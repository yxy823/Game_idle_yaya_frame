extends Node

## Incremental discovery of source paths; never imports/loads media on the UI thread.

signal found(paths: Array[String])
signal finished(message: String)

const Group = preload("res://asset_workbench/ui/analysis_group.gd")
const Source = preload("res://asset_workbench/ui/analysis_source.gd")
const ENTRY_LIMIT: int = 50000

var active: bool = false
var _directories: Array[String] = []
var _directory: DirAccess
var _visited: int = 0
var _matches: int = 0
var _errors: int = 0


func start(path: String) -> void:
	cancel()
	var local := Group.project_path(path)
	if local.is_empty() or not DirAccess.dir_exists_absolute(local):
		finished.emit("Choose an existing folder inside this project.")
		return
	var issue := Source.initialize()
	if not issue.is_empty():
		finished.emit(issue)
		return
	_directories = [local]
	_visited = 0
	_matches = 0
	_errors = 0
	active = true


func cancel() -> void:
	if _directory != null:
		_directory.list_dir_end()
	_directory = null
	_directories.clear()
	active = false


func _process(_delta: float) -> void:
	if not active:
		return
	var paths := _scan_slice()
	if not paths.is_empty():
		found.emit(paths)
	if not active:
		return
	if _visited >= ENTRY_LIMIT or _matches >= Group.MAX_ASSETS:
		cancel()
		finished.emit("Scan limit reached; choose a smaller folder. Partial membership retained.")
	elif _directory == null and _directories.is_empty():
		cancel()
		finished.emit("Scan complete: %d source files, %d unreadable folders." % [_matches, _errors])


func _scan_slice() -> Array[String]:
	var paths: Array[String] = []
	var deadline := Time.get_ticks_usec() + 3000
	for _index: int in 32:
		if not _next_directory() or Time.get_ticks_usec() >= deadline:
			break
		_read_entry(paths)
		if _visited >= ENTRY_LIMIT or _matches >= Group.MAX_ASSETS:
			break
	return paths


func _next_directory() -> bool:
	if _directory != null:
		return true
	if _directories.is_empty():
		return false
	_directory = DirAccess.open(_directories.pop_back())
	if _directory == null:
		_errors += 1
		return false
	_directory.include_hidden = false
	_directory.include_navigational = false
	if _directory.list_dir_begin() != OK:
		_errors += 1
		_directory = null
		return false
	return true


func _read_entry(paths: Array[String]) -> void:
	var entry_name := _directory.get_next()
	if entry_name.is_empty():
		_directory.list_dir_end()
		_directory = null
		return
	_visited += 1
	if entry_name.begins_with(".") or _directory.is_link(entry_name):
		return
	var path := _directory.get_current_dir().path_join(entry_name)
	if _directory.current_is_dir():
		if entry_name not in ["addons", "reports"]:
			_directories.append(path)
	elif not Source.asset_type(path).is_empty():
		paths.append(path)
		_matches += 1


func _exit_tree() -> void:
	cancel()
