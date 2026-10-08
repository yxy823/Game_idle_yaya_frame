# Run only in a disposable external fixture project containing the current linter.
# godot --headless --path <fixture> --script <this script> -- <report.json>
extends SceneTree

const CLI := "res://addons/gdscript-linter/analyzer/analyze-cli.gd"
const CONFIG_PATH := "res://gdlint.json"
const BACKUP_PATH := "res://gdlint-entry-contracts.backup"
const SOURCE_PATH := "res://gdlint-entry-contracts-source.gd"
const OUTPUT_PATH := "res://gdlint-entry-contracts-output.json"
const DIRECTORY_PATH := "res://gdlint-entry-contracts-directory"
const CONFIG := preload("res://addons/gdscript-linter/analyzer/analysis-config.gd")

var _checks: int = 0
var _failures: Array[String] = []
var _runs: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or FileAccess.file_exists(BACKUP_PATH) \
			or FileAccess.file_exists(SOURCE_PATH) or FileAccess.file_exists(OUTPUT_PATH) \
			or DirAccess.dir_exists_absolute(DIRECTORY_PATH):
		printerr("Supply one report path and a disposable fixture without contract leftovers.")
		quit(3)
		return
	var had_config := FileAccess.file_exists(CONFIG_PATH)
	if had_config and DirAccess.rename_absolute(CONFIG_PATH, BACKUP_PATH) != OK:
		printerr("Cannot preserve fixture config.")
		quit(3)
		return
	_write(SOURCE_PATH, "func sample() -> int:\n\tvar number: int = 37\n\treturn number\n")
	_missing_config_contracts()
	_valid_and_invalid_filters()
	_unwritable_output_contracts()
	_unreadable_directory_contracts()
	_remove(CONFIG_PATH)
	_remove(SOURCE_PATH)
	_remove(OUTPUT_PATH)
	if had_config:
		_expect(DirAccess.rename_absolute(BACKUP_PATH, CONFIG_PATH) == OK, "restore fixture config")
	_write(args[0], JSON.stringify({"checks": _checks, "failures": _failures,
		"runs": _runs, "engine": Engine.get_version_info()}, "  ") + "\n")
	quit(0 if _failures.is_empty() else 1)


func _missing_config_contracts() -> void:
	_expect(_run_cli(["--help"]).code == 0, "help works without a project config")
	_expect_failure(_run_cli([]), "Could not load config", "missing default config")
	_expect_failure(_run_cli(["--config", "res://missing-config.json"]),
		"Could not load config", "missing explicit config")
	# A directory at the default path is a real unopenable config, without ACL changes.
	_expect(DirAccess.make_dir_absolute(CONFIG_PATH) == OK, "create unreadable config fixture")
	_expect_failure(_run_cli([]), "Could not load config", "unopenable default config")
	_remove(CONFIG_PATH)


func _valid_and_invalid_filters() -> void:
	_write(CONFIG_PATH, JSON.stringify({"limits": {
		"function_lines": 2, "function_lines_critical": 5}}))
	var result := _run_cli(["--check", "long-function"])
	_expect(result.code == 1, "valid check keeps warning exit code")
	_expect(FileAccess.file_exists(OUTPUT_PATH), "valid CLI creates JSON report")
	if FileAccess.file_exists(OUTPUT_PATH):
		var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT_PATH))
		_expect(report is Dictionary, "CLI report is a JSON object")
		if report is Dictionary:
			_expect(report.get("exit_code", -1) == 1, "JSON verdict matches process verdict")
			var issues: Array = report.get("issues", [])
			_expect(issues.size() == 1, "valid filter emits only the requested finding")
			if issues.size() == 1:
				_expect(issues[0].get("check_id", "") == "long-function", "requested check ran")
	for check_ids: String in ["unknown-check", "long-function,unknown-check"]:
		_expect_failure(_run_cli(["--check", check_ids]), "Unknown check ID",
			"reject invalid check list: " + check_ids)
	_write(CONFIG_PATH, "{ malformed JSON")
	_expect_failure(_run_cli([]), "Invalid JSON config", "invalid default config")


## A report or config that cannot be written completely fails and leaves the old file.
func _unwritable_output_contracts() -> void:
	_write(CONFIG_PATH, JSON.stringify({"limits": {
		"function_lines": 2, "function_lines_critical": 5}}))
	# A directory where the temporary file goes makes the write fail, without ACL changes.
	_expect(DirAccess.make_dir_absolute(OUTPUT_PATH + ".tmp") == OK, "block temporary report")
	var result := _run_cli([])
	_expect(result.code == 3, "unwritable report returns exit 3")
	_expect("Cannot write JSON report" in result.output, "unwritable report is explained")
	_expect(not FileAccess.file_exists(OUTPUT_PATH), "unwritable report publishes nothing")
	_remove(OUTPUT_PATH + ".tmp")
	var config := CONFIG.new()
	_expect(config.load_from_json(CONFIG_PATH), "load config before saving")
	var before := FileAccess.get_file_as_string(CONFIG_PATH)
	_expect(DirAccess.make_dir_absolute(CONFIG_PATH + ".tmp") == OK, "block temporary config")
	_expect(not config.save_to_json(CONFIG_PATH), "unwritable config save returns false")
	_expect(FileAccess.get_file_as_string(CONFIG_PATH) == before, "failed config save keeps the original")
	_remove(CONFIG_PATH + ".tmp")
	_expect(config.save_to_json(CONFIG_PATH), "config save replaces the existing file")
	_expect(FileAccess.get_file_as_string(CONFIG_PATH) != before, "replaced config holds every field")


## A directory the linter cannot open is an input error, even beside readable scripts.
func _unreadable_directory_contracts() -> void:
	_expect(DirAccess.make_dir_recursive_absolute(DIRECTORY_PATH.path_join("readable")) == OK,
		"create readable directory")
	_write(DIRECTORY_PATH.path_join("readable/sample.gd"), "extends Node\n")
	var link := ProjectSettings.globalize_path(DIRECTORY_PATH.path_join("locked")).replace("/", "\\")
	var target := ProjectSettings.globalize_path(DIRECTORY_PATH + "-target").replace("/", "\\")
	_expect(DirAccess.make_dir_absolute(target) == OK, "create junction target")
	# A junction whose target is gone is listed as a directory that cannot be opened.
	_expect(OS.execute("cmd.exe", ["/c", "mklink", "/J", link, target]) == 0, "create junction")
	_expect(DirAccess.remove_absolute(target) == OK, "remove junction target")
	var result := _run_cli([], DIRECTORY_PATH)
	_expect(result.code == 3, "unreadable directory returns exit 3")
	_expect("Cannot open directory: " + DIRECTORY_PATH.path_join("locked") in result.output,
		"unreadable directory is named")
	_expect(DirAccess.remove_absolute(link) == OK, "remove junction")
	_remove(DIRECTORY_PATH.path_join("readable/sample.gd"))
	_remove(DIRECTORY_PATH.path_join("readable"))
	_remove(DIRECTORY_PATH)


func _run_cli(options: Array[String], input: String = SOURCE_PATH) -> Dictionary:
	_remove(OUTPUT_PATH)
	var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", CLI, "--", "--json", "--output", OUTPUT_PATH])
	args.append_array(PackedStringArray(options))
	args.append(input)
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), args, output, true)
	var result := {"options": options, "code": code, "output": "\n".join(PackedStringArray(output))}
	_runs.append(result)
	return result


func _expect_failure(result: Dictionary, diagnostic: String, label: String) -> void:
	_expect(result.code == 3, label + " returns input-error exit code")
	_expect(diagnostic in result.output, label + " explains rejection")
	_expect(not FileAccess.file_exists(OUTPUT_PATH), label + " cannot publish a success report")


func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "open output: " + path)
	if file != null:
		file.store_string(content)
		file.close()


func _remove(path: String) -> void:
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		_expect(DirAccess.remove_absolute(path) == OK, "remove fixture: " + path)


func _expect(value: bool, description: String) -> void:
	_checks += 1
	if not value:
		_failures.append(description)
