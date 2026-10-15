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


## GDScript folds CONST.field reads at compile time, so the game would never see the debug
## console's live changes. Game code reads tuning resources through a variable or get().
func test_game_does_not_read_tuning_fields_through_constants() -> void:
	var sources: Dictionary[String, String] = {}
	for root: String in ["res://game", "res://main", "res://components"]:
		_collect(root, sources)
	var issues: PackedStringArray = []
	for path: String in sources:
		if path.get_extension() == "gd":
			issues.append_array(_tuning_constant_reads(path, sources[path]))
	assert_array(issues).is_empty()


func test_tuning_constant_scanner_flags_field_reads_only() -> void:
	for quote: String in ['"', "'"]:
		var text := ('const TUNING := preload(%sres://game/shop/tuning/sound.tres%s)\n' % [quote, quote]
			+ 'var tuning: Resource = TUNING\n'
			+ 'func a(): return TUNING.volume_db\n'
			+ 'func b(): return TUNING.get("volume_db")\n'
			+ 'func c(): TUNING.changed.connect(a)\n')
		assert_array(_tuning_constant_reads("sample.gd", text)).contains_exactly(["sample.gd: TUNING.volume_db"])
	assert_array(_tuning_constant_reads("sample.gd",
		'const ICON := preload("res://game/shop/icon.png")\nfunc a(): return ICON.get_size()\n')).is_empty()


func _tuning_constant_reads(path: String, text: String) -> PackedStringArray:
	var issues: PackedStringArray = []
	var source := _scan_source(text, "gd")
	var constants := RegEx.create_from_string(
		"(?m)^\\s*const\\s+(\\w+)\\s*(?::\\s*\\w+\\s*)?:?=\\s*preload\\(\\s*\\z")
	for literal: Dictionary in source.strings:
		var found := constants.search(String(source.code).substr(0, literal.offset))
		if found == null:
			continue
		var target: String = literal.value
		if target.begins_with("uid://"):
			var identity := ResourceUID.text_to_id(target)
			target = ResourceUID.get_id_path(identity) if ResourceUID.has_id(identity) else ""
		target = target.simplify_path()
		if not ("/tuning/" in target and target.get_extension() == "tres"):
			continue
		var constant := found.get_string(1)
		var reads := RegEx.create_from_string("\\b" + constant + "\\.([A-Za-z_]\\w*)\\b(?!\\s*\\()")
		for read in reads.search_all(source.code):
			if read.get_string(1) != "changed":
				issues.append("%s: %s.%s" % [path, constant, read.get_string(1)])
	return issues


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


func test_scanner_normalizes_development_paths() -> void:
	assert_array(_dependency_issues("sample.gd", "preload('res://game/../dev/scene.tscn')", [], {})) \
		.contains_exactly(["sample.gd: dev path"])


func test_scanners_ignore_comments_and_quoted_symbols() -> void:
	var text := ('# preload("res://dev/example.tres") uid://sampledev DebugOnly\n'
		+ '# const TUNING := preload("res://game/shop/tuning/sound.tres")\n'
		+ '# var value := TUNING.volume_db\nvar label := "DebugOnly TUNING.volume_db"\n')
	assert_array(_dependency_issues("sample.gd", text, ["DebugOnly"], {})).is_empty()
	assert_array(_tuning_constant_reads("sample.gd", text)).is_empty()


func _dependency_issues(path: String, text: String, classes: PackedStringArray,
		uid_paths: Dictionary[String, String]) -> PackedStringArray:
	var issues: PackedStringArray = []
	var source := _scan_source(text, path.get_extension())
	var regex := RegEx.create_from_string("uid://[a-zA-Z0-9]+")
	for literal: Dictionary in source.strings:
		var value: String = literal.value
		if value.simplify_path().begins_with("res://dev/"):
			issues.append(path + ": dev path")
		for item in regex.search_all(value):
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
			if RegEx.create_from_string("\\b" + symbol + "\\b").search(source.code) != null:
				issues.append(path + ": " + symbol)
	return issues


func _scan_source(text: String, extension: String) -> Dictionary:
	var quoted := "\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?'''|\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'"
	var comments := "|#[^\n]*" if extension == "gd" else "|[;#][^\n]*"
	if extension in ["gdshader", "gdshaderinc"]:
		comments = "|//[^\n]*|/\\*[\\s\\S]*?\\*/"
	var code := ""
	var strings: Array[Dictionary] = []
	var cursor := 0
	var mask := RegEx.create_from_string("[^\n]")
	for token in RegEx.create_from_string(quoted + comments).search_all(text):
		var value := token.get_string()
		code += text.substr(cursor, token.get_start() - cursor) + mask.sub(value, " ", true)
		cursor = token.get_end()
		if value.begins_with('"') or value.begins_with("'"):
			var width := 3 if value.begins_with('"""') or value.begins_with("'''") else 1
			strings.append({"offset": token.get_start(),
				"value": value.substr(width, value.length() - 2 * width).c_unescape()})
	return {"code": code + text.substr(cursor), "strings": strings}


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
