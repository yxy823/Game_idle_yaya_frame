extends Node

## One scene-time clock schedules windows, not sample-accurate media or seekable simulation.
## Missed windows are skipped; a late frame starts only windows still open, from their beginning.

signal state_changed
signal playback_issue(message: String)

const Manager = preload("res://components/feedback/feedback_playback_manager.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")

var position_seconds: float = 0.0
var looping: bool = false
var _definition: FeedbackTimeline
var _root: Node
var _manager: Manager
var _handles: Dictionary[int, int] = {}
var _visited: Array[int] = []
var _generation: int = 0
var _busy: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	stop()


func is_playing() -> bool:
	return _definition != null


func play(definition: FeedbackTimeline, target_root: Node, manager: Manager,
		repeat: bool = false) -> String:
	if _busy:
		return "Timeline is changing playback; defer a new play request from its signals."
	var issue := _input_error(definition, target_root, manager)
	if not issue.is_empty():
		return issue
	_busy = true
	var expected_generation := _generation + 1
	stop()
	if _generation != expected_generation:
		_busy = false
		return "Timeline start was cancelled while stopping the previous playback."
	_definition = definition.playback_copy()
	_root = target_root
	_manager = manager
	looping = repeat
	position_seconds = 0.0
	set_process(true)
	var generation := _generation
	state_changed.emit()
	if generation == _generation:
		_advance(0.0)
	_busy = false
	return ""


func stop() -> void:
	var was_playing := is_playing()
	var was_busy := _busy
	_busy = true
	_generation += 1
	_definition = null
	set_process(false)
	_visited.clear()
	position_seconds = 0.0
	looping = false
	_release_handles()
	if was_playing:
		state_changed.emit()
	_busy = was_busy


## Called by _process; consumers must not run a second clock alongside automatic processing.
func advance(delta: float) -> void:
	if _busy or not is_playing() or not is_finite(delta) or delta < 0.0:
		return
	_busy = true
	_advance(delta)
	_busy = false


func _advance(delta: float) -> void:
	if not is_instance_valid(_root) or not _root.is_inside_tree() \
			or not is_instance_valid(_manager) or not _manager.is_inside_tree():
		_fail("Timeline owner or playback manager left the scene.")
		return
	var generation := _generation
	position_seconds += delta
	if position_seconds >= _definition.length_seconds:
		if not looping:
			stop()
			return
		# Never burst through missed cycles after a stall. Only the current cycle is presented.
		position_seconds = fmod(position_seconds, _definition.length_seconds)
		_release_handles()
		if generation != _generation:
			return
		_visited.clear()
	_update_windows(generation)


func _update_windows(generation: int) -> void:
	for index: int in _handles.keys():
		if position_seconds >= _definition.clips[index].end_seconds():
			var handle := _handles[index]
			_handles.erase(index)
			_manager.cancel(handle)
			if generation != _generation:
				return
	for index: int in _definition.clips.size():
		_start_window(index, generation)
		if generation != _generation:
			return


func _start_window(index: int, generation: int) -> void:
	var clip := _definition.clips[index]
	if index in _visited or position_seconds < clip.start_seconds:
		return
	_visited.append(index)
	if position_seconds >= clip.end_seconds():
		return
	var object := _root.get_node_or_null(clip.target) as ObjectView
	if object == null or object.is_queued_for_deletion():
		_fail("Timeline target is unavailable: %s" % clip.target)
		return
	var manager := _manager
	var handle := manager.request(object.presenter, &"timeline", clip.priority)
	if generation != _generation:
		if handle != 0 and is_instance_valid(manager):
			manager.cancel(handle)
		return
	if handle != 0:
		_handles[index] = handle
	else:
		playback_issue.emit("Timeline clip skipped: %s (playback request rejected)." % clip.target)


func _release_handles() -> void:
	var handles: Array[int] = []
	handles.assign(_handles.values())
	_handles.clear()
	var manager := _manager
	if is_instance_valid(manager):
		for handle: int in handles:
			if is_instance_valid(manager):
				manager.cancel(handle)


func _fail(message: String) -> void:
	stop()
	playback_issue.emit(message)


func _input_error(definition: FeedbackTimeline, target_root: Node, manager: Manager) -> String:
	if definition == null:
		return "No timeline is configured."
	var issue := definition.validation_error()
	if not issue.is_empty():
		return issue
	issue = _owner_error(target_root, manager)
	return issue if not issue.is_empty() else _targets_error(definition, target_root)


func _owner_error(target_root: Node, manager: Manager) -> String:
	if not is_inside_tree() or not is_instance_valid(target_root) \
			or not target_root.is_inside_tree() or target_root.is_queued_for_deletion():
		return "Timeline target root must be in the scene."
	if not is_instance_valid(manager) or not manager.is_inside_tree() \
			or manager.is_queued_for_deletion() or manager.get_tree() != get_tree():
		return "Timeline requires a local playback manager in the same scene tree."
	return ""


func _targets_error(definition: FeedbackTimeline, target_root: Node) -> String:
	for clip: FeedbackTimelineClip in definition.clips:
		var object := target_root.get_node_or_null(clip.target) as ObjectView
		if object == null or object.is_queued_for_deletion():
			return "Timeline target is unavailable: %s" % clip.target
		if object.cue == null:
			return "Timeline target has no Cue: %s" % clip.target
		var issue := object.cue.validation_error()
		if not issue.is_empty():
			return "%s: %s" % [clip.target, issue]
	return ""
