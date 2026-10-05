extends SceneTree

## Run with --main-pack from the report directory, not the source project.
## This probes the exported dependency closure; it is not a production export preset.

const BASE: String = "res://yaya/asset_workbench/examples/"
const ENTRIES: Array[String] = ["single/example_game.tscn",
	"composition/example_composition.tscn", "shader_composition/example_composition.tscn",
	"effects_composition/example_consumer.tscn"]

var _failures: Array[String] = []
var _cases: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].is_absolute_path() or not args[1].is_absolute_path():
		push_error("Pass absolute JSON output and project export_presets.cfg paths after --.")
		quit(2)
		return
	_check_export_boundary(args[1])
	for index: int in ENTRIES.size():
		await _consume(index)
	# The audio thread retires stopped stream playbacks on its next mix, after node release.
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	var result := {"passed": _failures.is_empty(), "cases": _cases, "failures": _failures,
		"engine": Engine.get_version_info().string}
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		push_error("Cannot write export probe result: " + args[0])
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	quit(0 if _failures.is_empty() else 1)


func _check_export_boundary(preset_path: String) -> void:
	var preset := ConfigFile.new()
	var error := preset.load(preset_path)
	_check(error == OK, "Cannot read preset: " + preset_path)
	if error != OK:
		return
	var includes: String = preset.get_value("preset.0", "include_filter", "")
	var licenses := _license_paths(preset_path.get_base_dir(), includes)
	_check(not licenses.is_empty(), "No license expectations in preset")
	for path: String in licenses:
		_check(FileAccess.file_exists("res://" + path), "Missing license: " + path)
	var excludes: String = preset.get_value("preset.0", "exclude_filter", "")
	_check(not excludes.is_empty(), "No exclusions in preset")
	for filter: String in excludes.split(",", false):
		var pattern := filter.strip_edges()
		var directory := pattern.trim_suffix("/*")
		if not pattern.ends_with("/*") or directory.contains("*") or directory.contains("?"):
			_check(false, "Unsupported exclusion: " + pattern)
			continue
		_check(not DirAccess.dir_exists_absolute("res://" + directory),
			"Excluded directory present: " + directory)


func _license_paths(source_root: String, includes: String) -> Array[String]:
	var paths: Array[String] = []
	for filter: String in includes.split(",", false):
		var pattern := filter.strip_edges()
		if not pattern.to_lower().contains("license"):
			continue
		if not pattern.contains("*") and not pattern.contains("?"):
			_check(FileAccess.file_exists(source_root.path_join(pattern)), "Missing source license: " + pattern)
			paths.append(pattern)
		elif pattern.get_file() == "*license*" and not pattern.get_base_dir().contains("*") \
				and not pattern.get_base_dir().contains("?"):
			var matches := _find_licenses(source_root, pattern.get_base_dir())
			_check(not matches.is_empty(), "No source licenses match: " + pattern)
			paths.append_array(matches)
		else:
			_check(false, "Unsupported license filter: " + pattern)
	return paths


func _find_licenses(source_root: String, relative_directory: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(source_root.path_join(relative_directory))
	_check(directory != null, "Cannot read source license directory: " + relative_directory)
	if directory == null:
		return paths
	for filename: String in directory.get_files():
		if filename.matchn("*license*"):
			paths.append(relative_directory.path_join(filename))
	for child: String in directory.get_directories():
		paths.append_array(_find_licenses(source_root, relative_directory.path_join(child)))
	return paths


func _consume(index: int) -> void:
	var path := BASE + ENTRIES[index]
	var packed := load(path) as PackedScene
	_check(packed != null, path + ": load")
	if packed == null:
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	var presenters: Array[Node] = []
	if index == 0:
		_check(scene.get("cue") != null, path + ": saved cue")
		presenters.append(scene.get("_presenter"))
		scene.call("activate_example")
	else:
		var objects: Array = scene.get("objects")
		_check(objects.size() == (6 if index == 3 else 3), path + ": objects")
		for object: Node in objects:
			_check(object.get("cue") != null, path + ": " + String(object.name) + " cue")
			presenters.append(object.get("presenter"))
		scene.call("trigger_all")
	await create_timer(0.2).timeout
	var voices := 0
	for presenter: Node in presenters:
		_check(presenter.call("playback_error") == "", path + ": valid media bindings")
		_check(presenter.call("is_playing"), path + ": active playback")
		voices += int(presenter.call("active_voice_count"))
	_check(voices > 0, path + ": real audio voices")
	if index == 3:
		_check(scene.call("play_timeline", true) == "", path + ": timeline start")
		await create_timer(0.1).timeout
		_check(scene.get("manager").active_count() > 0, path + ": managed playback")
	await _release_scene(scene, presenters, path)
	_cases.append({"entry": ENTRIES[index], "presenters": presenters.size(), "voices": voices})


func _release_scene(scene: Node, presenters: Array[Node], path: String) -> void:
	if scene.has_method("stop"):
		scene.call("stop")
	for presenter: Node in presenters:
		presenter.call("stop")
		_check(not presenter.call("is_playing"), path + ": stopped")
	scene.free()
	await process_frame
	_check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == 0,
		path + ": released")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
