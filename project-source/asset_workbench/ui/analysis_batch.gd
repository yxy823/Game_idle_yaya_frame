extends Node

## Uses the same service as single-asset analysis; cancellation owns only this batch's jobs.

signal changed

const Group = preload("res://asset_workbench/ui/analysis_group.gd")
const Service = preload("res://asset_workbench/ui/analysis_service.gd")
const Source = preload("res://asset_workbench/ui/analysis_source.gd")

var service: Service
var group: Dictionary = Group.empty()
var results: Dictionary = {}
var states: Dictionary = {}
var historical: String = ""
var _tasks: Dictionary[int, String] = {}


func _ready() -> void:
	service.completed.connect(_completed)
	service.state_changed.connect(_state_changed)


func busy() -> bool:
	return not _tasks.is_empty()


func add_paths(paths: Array[String]) -> String:
	if busy():
		return "Cancel or finish the batch before changing membership."
	var issue := Source.initialize()
	if not issue.is_empty():
		return issue
	for path: String in paths:
		var local := Group.project_path(path)
		var kind := Source.asset_type(local)
		if local.is_empty() or kind.is_empty():
			continue
		var asset := {"path": local, "type": kind}
		if asset in group.assets:
			continue
		if group.assets.size() >= Group.MAX_ASSETS:
			changed.emit()
			return "Group is limited to 512 assets. Create another group."
		group.assets.append(asset)
	changed.emit()
	return ""


func remove_paths(paths: Array[String]) -> void:
	if busy():
		return
	group.assets = group.assets.filter(func(asset: Dictionary) -> bool: return asset.path not in paths)
	for path: String in paths:
		results.erase(path)
		states.erase(path)
	changed.emit()


func load_group(value: Variant) -> String:
	var issue := Group.validation_error(value)
	if not issue.is_empty():
		return issue
	cancel()
	group = value.duplicate(true)
	results.clear()
	states.clear()
	historical = ""
	changed.emit()
	return ""


func run(force: bool = false) -> void:
	cancel()
	results.clear()
	states.clear()
	historical = ""
	for asset: Dictionary in group.assets:
		var task := service.submit(asset.path, asset.type, group.parameters.duplicate(true), force)
		_tasks[task] = asset.path
		states[asset.path] = "queued"
	changed.emit()


func cancel() -> void:
	for task: int in _tasks.keys():
		service.cancel(task)


func snapshot() -> Dictionary:
	var saved_results := results.duplicate(true)
	for path: String in saved_results:
		saved_results[path].asset.path = path
	var timestamp := historical if not historical.is_empty() \
		else Time.get_datetime_string_from_system(true)
	return {"snapshot_version": 1, "created_at": timestamp,
		"group": group.duplicate(true), "results": saved_results}


func load_snapshot(value: Variant) -> String:
	var issue := Group.snapshot_error(value)
	if not issue.is_empty():
		return issue
	load_group(value.group)
	results = value.results.duplicate(true)
	historical = value.created_at
	for path: String in results:
		states[path] = results[path].status
	changed.emit()
	return ""


func _completed(task: int, data: Dictionary) -> void:
	if not _tasks.has(task):
		return
	var path: String = _tasks[task]
	_tasks.erase(task)
	results[path] = data
	states[path] = data.status
	changed.emit()


func _state_changed(task: int, state: String) -> void:
	if _tasks.has(task):
		states[_tasks[task]] = state
		changed.emit()


func _exit_tree() -> void:
	if is_instance_valid(service):
		cancel()
