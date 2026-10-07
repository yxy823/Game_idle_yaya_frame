extends GdUnitTestSuite
## Read file text and UID registry only; never load or preload development resources.

const SELF := "res://tests/invariants/debug_dependency_test.gd"
const TEXT_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "godot", "gdshader", "import"]


func test_game_dependencies_do_not_point_into_dev() -> void:
	var sources: Dictionary[String, String] = {}
	for root: String in ["res://game", "res://main", "res://components"]:
		_collect(root, sources)
	sources["res://project.godot"] = FileAccess.get_file_as_string("res://project.godot")
	var classes := _dev_classes()
	var issues: PackedStringArray = []
	for path: String in sources:
		issues.append_array(_dependency_issues(path, sources[path], classes, {}))
	assert_array(issues).is_empty()


func test_game_and_tests_do_not_read_debug_presets_or_combos() -> void:
	var sources: Dictionary[String, String] = {}
	_collect("res://game", sources)
	_collect("res://tests", sources)
	var regex := RegEx.create_from_string("(?:res://)?dev/debug/[^\\s\"']*/(?:presets|combos)")
	var issues: PackedStringArray = []
	for path: String in sources:
		if path != SELF and regex.search(sources[path]) != null:
			issues.append(path)
	assert_array(issues).is_empty()


func test_slot_directories_have_matching_game_tuning_resources() -> void:
	var issues: PackedStringArray = []
	for target in DirAccess.get_directories_at("res://dev/debug"):
		if target.begins_with("_"):
			continue
		var slots := "res://dev/debug/" + target + "/slots"
		if DirAccess.dir_exists_absolute(slots):
			_orphans(slots, "res://game/" + target + "/tuning", "", issues)
	assert_array(issues).is_empty()


func test_scanner_detects_text_uid_class_symbols_and_accepts_game_paths() -> void:
	var uids: Dictionary[String, String] = {
		"uid://sampledev": "res://dev/debug/example.tres",
		"uid://samplegame": "res://game/board/example.tres",
	}
	var issues := _dependency_issues("sample.gd",
		'preload("res://dev/scene.tscn")\nvar value: DebugOnly\n"uid://sampledev"',
		["DebugOnly"], uids)
	assert_int(issues.size()).is_equal(3)
	assert_array(_dependency_issues("sample.gd", '"uid://samplegame"', [], uids)).is_empty()


func _dependency_issues(path: String, text: String, classes: PackedStringArray,
		uid_paths: Dictionary[String, String]) -> PackedStringArray:
	var issues: PackedStringArray = []
	if "res://dev/" in text:
		issues.append(path + ": dev path")
	var regex := RegEx.create_from_string("uid://[a-zA-Z0-9]+")
	for item in regex.search_all(text):
		var uid := item.get_string()
		var resolved := String(uid_paths.get(uid, ""))
		if resolved.is_empty():
			var identity := ResourceUID.text_to_id(uid)
			if ResourceUID.has_id(identity):
				resolved = ResourceUID.get_id_path(identity)
		if resolved.is_empty():
			issues.append(path + ": unresolved " + uid)
		if resolved.simplify_path().begins_with("res://dev/"):
			issues.append(path + ": " + uid)
	if path.get_extension() == "gd":
		for symbol in classes:
			if RegEx.create_from_string("\\b" + symbol + "\\b").search(text) != null:
				issues.append(path + ": " + symbol)
	return issues


func _dev_classes() -> PackedStringArray:
	var sources: Dictionary[String, String] = {}
	_collect("res://dev", sources)
	var result: PackedStringArray = []
	var regex := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for path: String in sources:
		if path.get_extension() == "gd":
			for item in regex.search_all(sources[path]):
				result.append(item.get_string(1))
	return result


func _collect(directory: String, output: Dictionary[String, String]) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() in TEXT_EXTENSIONS:
			var path := directory.path_join(file)
			output[path] = FileAccess.get_file_as_string(path)
	for child in DirAccess.get_directories_at(directory):
		_collect(directory.path_join(child), output)


func _orphans(directory: String, tuning: String, relative: String,
		issues: PackedStringArray) -> void:
	for child in DirAccess.get_directories_at(directory):
		var path := relative + child
		if FileAccess.file_exists(tuning.path_join(path + ".tres")):
			continue
		if not DirAccess.dir_exists_absolute(tuning.path_join(path)):
			issues.append(directory.path_join(child))
		else:
			_orphans(directory.path_join(child), tuning, path + "/", issues)
