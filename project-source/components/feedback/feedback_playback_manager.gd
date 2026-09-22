extends Node

## Optional scene-local leases over existing presenters, never a global pool or GPU budget.
## A handle owns the whole target until completion, cancellation or external playback changes.

signal request_rejected(reason: String)
signal handle_ended(handle: int, reason: String)

const Presenter = preload("res://components/feedback/feedback_presenter.gd")

@export_range(1, 128, 1) var max_active: int = 8

var last_error: String = ""

var _records: Dictionary[int, Playback] = {}
var _next_handle: int = 1
var _mutation_depth: int = 0
var _closing: bool = false


func _enter_tree() -> void:
	_closing = false


func _process(_delta: float) -> void:
	_sweep()


func _exit_tree() -> void:
	_closing = true
	stop_all()


## Replaces this manager's lease on the target. Higher priority may evict the oldest lowest one.
## Requests made synchronously from playback/manager signals return 0; defer a new request instead.
func request(target: Presenter, group: StringName = &"", priority: int = 0) -> int:
	if _mutation_depth > 0:
		# Emitting another rejection here would allow a rejection listener to recurse forever.
		last_error = "Playback request is reentrant; defer it until the current operation finishes."
		return 0
	_mutation_depth += 1
	last_error = ""
	var handle := _request(target, group, priority)
	if handle == 0 and not last_error.is_empty():
		request_rejected.emit(last_error)
	elif handle != 0:
		last_error = ""
	_mutation_depth -= 1
	return handle


func cancel(handle: int) -> void:
	_finish(handle, "cancelled", true)


func cancel_group(group: StringName) -> void:
	_mutation_depth += 1
	for handle: int in _records.keys():
		if _records.has(handle) and _records[handle].group == group:
			_finish(handle, "group_cancelled", true)
	_mutation_depth -= 1


func stop_all() -> void:
	_mutation_depth += 1
	for handle: int in _records.keys():
		_finish(handle, "stopped", true)
	_mutation_depth -= 1


func active_count() -> int:
	_sweep()
	return _records.size()


func is_active(handle: int) -> bool:
	_sweep()
	return _records.has(handle)


func _request(target: Presenter, group: StringName, priority: int) -> int:
	if not _usable(target) or max_active < 1:
		last_error = "Playback needs a live target in the same SceneTree and a positive target budget."
		return 0
	last_error = target.playback_error()
	if not last_error.is_empty():
		return 0
	_sweep()
	for handle: int in _records.keys():
		if _records.has(handle) and _records[handle].target.get_ref() == target:
			_finish(handle, "replaced", true)
	if not _make_room(priority):
		return 0
	# End notifications may have stopped or freed the requested target.
	if not _usable(target):
		last_error = "Playback target left the scene during admission."
		return 0
	return _start(target, group, priority)


func _make_room(priority: int) -> bool:
	if _records.size() < max_active:
		return true
	if _records.size() > max_active:
		last_error = "Target budget was reduced; cancel existing handles before admitting more."
		return false
	var victim: int = 0
	for handle: int in _records:
		if victim == 0 or _records[handle].priority < _records[victim].priority:
			victim = handle
		elif _records[handle].priority == _records[victim].priority and handle < victim:
			victim = handle
	if victim == 0 or priority <= _records[victim].priority:
		last_error = "Managed target budget is full; only a strictly higher priority may preempt."
		return false
	_finish(victim, "preempted", true)
	return true


func _start(target: Presenter, group: StringName, priority: int) -> int:
	var handle := _next_handle
	_next_handle += 1
	var playback := Playback.new()
	playback.target = weakref(target)
	playback.group = group
	playback.priority = priority
	playback.failure_callback = _on_failure.bind(handle)
	playback.exit_callback = _on_target_exit.bind(handle)
	_records[handle] = playback
	target.playback_failed.connect(playback.failure_callback)
	target.tree_exiting.connect(playback.exit_callback)
	# Register first so synchronous sound_started listeners can cancel this pending admission.
	var revision := target.trigger_managed()
	playback.revision = revision
	if (not _records.has(handle) or not _usable(target) or revision == 0
			or target.playback_revision() != revision):
		if is_instance_valid(target) and revision != 0 and target.playback_revision() == revision:
			target.stop()
		_finish(handle, "superseded", false)
		last_error = "Playback was cancelled or superseded during its start notification."
		return 0
	return handle


func _usable(target: Presenter) -> bool:
	return (not _closing and is_inside_tree() and not is_queued_for_deletion()
		and is_instance_valid(target) and target.is_inside_tree()
		and not target.is_queued_for_deletion() and target.get_tree() == get_tree())


func _sweep() -> void:
	_mutation_depth += 1
	for handle: int in _records.keys():
		if not _records.has(handle):
			continue
		var playback := _records[handle]
		var target := playback.target.get_ref() as Presenter
		if not _usable(target):
			_finish(handle, "target_left", true)
		elif playback.revision < 0:
			continue
		elif target.playback_revision() != playback.revision:
			_finish(handle, "superseded", false)
		elif not target.is_playing():
			_finish(handle, "completed", false)
	_mutation_depth -= 1


func _finish(handle: int, reason: String, stop_target: bool) -> void:
	if not _records.has(handle):
		return
	_mutation_depth += 1
	var playback := _records[handle]
	_records.erase(handle)
	var target := playback.target.get_ref() as Presenter
	if is_instance_valid(target):
		if target.playback_failed.is_connected(playback.failure_callback):
			target.playback_failed.disconnect(playback.failure_callback)
		if target.tree_exiting.is_connected(playback.exit_callback):
			target.tree_exiting.disconnect(playback.exit_callback)
		if stop_target and playback.revision >= 0 and target.playback_revision() == playback.revision:
			target.stop()
	handle_ended.emit(handle, reason)
	_mutation_depth -= 1


func _on_failure(message: String, handle: int) -> void:
	if not _records.has(handle):
		return
	var playback := _records[handle]
	var target := playback.target.get_ref() as Presenter
	if playback.revision < 0 or target.playback_revision() == playback.revision:
		_finish(handle, "failed: " + message, true)


func _on_target_exit(handle: int) -> void:
	_finish(handle, "target_left", true)


class Playback:
	var target: WeakRef
	var revision: int = -1
	var group: StringName
	var priority: int
	var failure_callback: Callable
	var exit_callback: Callable
