extends GdUnitTestSuite
## Read file text and UID registry only; never load or preload development resources.

const SELF := "res://tests/invariants/debug_dependency_test.gd"
const TEXT_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "godot", "gdshader", "import"]
## Excluded from the export, so a game reference into them breaks the packaged game.
const UNSHIPPED_ROOTS: Array[String] = ["res://dev/", "res://tests/", "res://addons/gdUnit4/"]
## Editor-only settings that legitimately name the test plugin.
const EDITOR_ONLY_SECTIONS: Array[String] = ["editor_plugins", "gdunit4"]


func test_game_dependencies_do_not_point_into_unshipped_files() -> void:
	var sources: Dictionary[String, String] = {}
	for root: String in ["res://game", "res://main", "res://components"]:
		_collect(root, sources)
	sources["res://project.godot"] = _without_sections(
		FileAccess.get_file_as_string("res://project.godot"), EDITOR_ONLY_SECTIONS)
	var classes := _unshipped_classes()
	var issues: PackedStringArray = []
	for path: String in sources:
		issues.append_array(_dependency_issues(path, sources[path], classes, {}))
	assert_array(issues).is_empty()


func test_game_and_tests_do_not_read_debug_presets_or_combos() -> void:
	var sources: Dictionary[String, String] = {}
	_collect("res://game", sources)
	_collect("res://tests", sources)
	var issues: PackedStringArray = []
	for path: String in sources:
		if path != SELF and _reads_presets(sources[path], {}):
			issues.append(path)
	assert_array(issues).is_empty()


func test_preset_scanner_resolves_uids() -> void:
	var uids: Dictionary[String, String] = {
		"uid://samplepreset": "res://dev/debug/shop/presets/loud.tres",
		"uid://samplegame": "res://game/shop/tuning/sound.tres",
	}
	assert_bool(_reads_presets('preload("uid://samplepreset")', uids)).is_true()
	assert_bool(_reads_presets('preload("uid://samplegame")', uids)).is_false()


func test_project_settings_skip_editor_only_sections() -> void:
	var text := ('[editor_plugins]\nenabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")\n'
		+ '[gdunit4]\nsettings/test/test_lookup_folder="tests"\n'
		+ '[autoload]\nHelper="*res://tests/helper.gd"\n')
	var settings := _without_sections(text, EDITOR_ONLY_SECTIONS)
	assert_array(_dependency_issues("project.godot", settings, [], {})) \
		.contains_exactly(["project.godot: res://tests/"])


func _reads_presets(text: String, uid_paths: Dictionary[String, String]) -> bool:
	var preset := RegEx.create_from_string("(?:res://)?dev/debug/[^\\s\"']*/(?:presets|combos)")
	if preset.search(text) != null:
		return true
	for item in RegEx.create_from_string("uid://[a-zA-Z0-9]+").search_all(text):
		if preset.search(_uid_path(item.get_string(), uid_paths)) != null:
			return true
	return false


func _without_sections(text: String, sections: Array[String]) -> String:
	var kept := PackedStringArray()
	var skipping := false
	for line in text.split("\n"):
		var header := RegEx.create_from_string("^\\[([^\\]]+)\\]").search(line)
		if header != null:
			skipping = header.get_string(1) in sections
		if not skipping:
			kept.append(line)
	return "\n".join(kept)


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
			target = _uid_path(target, {})
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
		.contains_exactly(["sample.gd: res://dev/"])


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
		# Autoload entries prefix the path with "*".
		var root := _unshipped_root(String(literal.value).trim_prefix("*"))
		if not root.is_empty():
			issues.append(path + ": " + root)
		for item in regex.search_all(literal.value):
			var uid := item.get_string()
			var resolved := _uid_path(uid, uid_paths)
			if resolved.is_empty():
				issues.append(path + ": unresolved " + uid)
			elif not _unshipped_root(resolved).is_empty():
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


func _unshipped_root(value: String) -> String:
	var normalized := value.simplify_path()
	for root in UNSHIPPED_ROOTS:
		if normalized.begins_with(root):
			return root
	return ""


func _uid_path(uid: String, uid_paths: Dictionary[String, String]) -> String:
	if uid_paths.has(uid):
		return uid_paths[uid]
	var identity := ResourceUID.text_to_id(uid)
	return ResourceUID.get_id_path(identity) if ResourceUID.has_id(identity) else ""


## gdUnit4's own class names are left out: matching them would flag ordinary game identifiers.
func _unshipped_classes() -> PackedStringArray:
	var sources: Dictionary[String, String] = {}
	_collect("res://dev", sources)
	_collect("res://tests", sources)
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
