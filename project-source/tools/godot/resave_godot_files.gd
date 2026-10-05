# 用编辑器模式的序列化重存 Agent 以文本方式新建或修改的文件，保留资源 UID。
extends SceneTree

## Re-save project.godot and text scenes/resources with Godot's own serializer.
## Usage: --headless --editor --path <project> --script res://yaya/tools/godot/resave_godot_files.gd -- <path> [...]


func _initialize() -> void:
	if not Engine.is_editor_hint():
		push_error("Run with --headless --editor --script")
		quit(2)
		return
	if OS.get_cmdline_user_args().is_empty():
		push_error("Pass project.godot or res:// scene/resource paths after --")
		quit(2)
		return
	call_deferred("_run")


func _wait_for_filesystem() -> void:
	var filesystem := EditorInterface.get_resource_filesystem()
	while filesystem.is_scanning() or filesystem.is_importing():
		await process_frame


func _run() -> void:
	await _wait_for_filesystem()
	var resources: PackedStringArray = []
	var failures := 0
	for path in OS.get_cmdline_user_args():
		if _resave(path):
			if path.get_extension() in ["tscn", "tres"]:
				resources.append(path)
		else:
			failures += 1
	if not resources.is_empty():
		# 首轮持久化资源 UID；重扫后第二轮才能补齐同批资源之间的引用 UID。
		EditorInterface.get_resource_filesystem().scan()
		await _wait_for_filesystem()
		for path in resources:
			if not _resave(path):
				failures += 1
	quit(1 if failures > 0 else 0)


func _resave(path: String) -> bool:
	if path in ["project.godot", "res://project.godot"]:
		return _check(path, ProjectSettings.save())
	if not path.begins_with("res://") or path.get_extension() not in ["tscn", "tres"]:
		push_error("Unsupported path (expected project.godot or res://*.tscn|*.tres): %s" % path)
		return false
	var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		push_error("Cannot load %s" % path)
		return false
	return _check(path, ResourceSaver.save(resource, path))


func _check(path: String, error: Error) -> bool:
	if error != OK:
		push_error("Cannot save %s: %s" % [path, error_string(error)])
		return false
	return true
