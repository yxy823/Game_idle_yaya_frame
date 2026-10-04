# 用 Godot 自己的序列化重写 Agent 手工改过的文件，让它们与编辑器保存的格式一致。
extends SceneTree

## Re-save project.godot and text scenes/resources with Godot's own serializer.
## Usage: --headless --path <project> --script res://tools/godot/resave_godot_files.gd -- <path> [...]


func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		push_error("Pass project.godot or res:// scene/resource paths after --")
		quit(2)
		return
	var failures := 0
	for path in paths:
		if not _resave(path):
			failures += 1
	quit(1 if failures > 0 else 0)


func _resave(path: String) -> bool:
	if path in ["project.godot", "res://project.godot"]:
		return _check(path, ProjectSettings.save())
	if not path.begins_with("res://") or path.get_extension() not in ["tscn", "tres"]:
		push_error("Unsupported path (expected project.godot or res://*.tscn|*.tres): %s" % path)
		return false
	var resource := load(path)
	if resource == null:
		push_error("Cannot load %s" % path)
		return false
	return _check(path, ResourceSaver.save(resource, path))


func _check(path: String, error: Error) -> bool:
	if error != OK:
		push_error("Cannot save %s: %s" % [path, error_string(error)])
		return false
	return true
