extends SceneTree
## Starts the real debug entry in a fresh process: --headless --path <project> --script <this>.
## The game runs with its own user:// data, so run it in a project copy, not the project itself.

const BOOT := preload("res://dev/debug/debug_main.tscn")

var _failures: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var paths: PackedStringArray = []
	_catalog("res://dev/debug", paths)
	for path in paths:
		var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		_check(resource != null, "Cannot load " + path)
		_check(ResourceLoader.get_resource_uid(path) != ResourceUID.INVALID_ID, "Missing UID " + path)
	var boot := BOOT.instantiate()
	root.add_child(boot)
	current_scene = boot
	await scene_changed
	var window := root.get_node("DebugWindow") as Window
	_check(window != null and window.force_native, "Native persistent debug window")
	var main := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main.begins_with("uid://"):
		main = ResourceUID.get_id_path(ResourceUID.text_to_id(main))
	_check(current_scene.scene_file_path == main, "Main initialized")
	if window.session.targets.is_empty():
		_check(window.status.message.text.begins_with(window.NO_TARGETS), "No target notice")
	for target: RefCounted in window.session.targets:
		if target.adapter != null and target.adapter.matches(current_scene):
			_check(window.session.active == target, "Target follows main")
	var error := change_scene_to_file(main)
	_check(error == OK, "Reload main")
	await scene_changed
	_check(is_instance_valid(window) and window.get_parent() == root, "Window survives scene change")
	for issue in _failures:
		push_error(issue)
	quit(0 if _failures.is_empty() else 1)


func _catalog(directory: String, output: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() in ["tscn", "tres"]:
			output.append(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_catalog(directory.path_join(child), output)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
