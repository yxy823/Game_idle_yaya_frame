# Enable this as an EditorPlugin only in a disposable external fixture project.
# godot --headless --editor --path <fixture> -- --lint-editor-contracts <report.json>
@tool
extends EditorPlugin

const CONFIG_PATH := "res://gdlint.json"
const DOCK = preload("res://addons/gdscript-linter/dock.tscn")
const CONFIG = preload("res://addons/gdscript-linter/analyzer/analysis-config.gd")
const MACHINE_OVERRIDES := {
	"code_quality/limits/max_params": 2,
	"code_quality/limits/function_lines": 90,
	"code_quality/checks/long_lines": true,
	"code_quality/scanning/respect_gdignore": true,
	"code_quality/scanning/scan_addons": false,
	"code_quality/scanning/included_addons": "machine_only",
	"code_quality/scanning/excluded_addons": "machine_excluded",
	"code_quality/display/show_debt": false,
}

var _checks: int = 0
var _failures: Array[String] = []
var _machine_snapshot: Dictionary = {}
var _original_config: PackedByteArray
var _had_config: bool = false
var _config_saved: bool = false
var _dock


func _enter_tree() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--lint-editor-contracts":
		_run.call_deferred(args[1])


func _exit_tree() -> void:
	_restore()


func _run(report_path: String) -> void:
	await _wait_for_filesystem()
	_had_config = FileAccess.file_exists(CONFIG_PATH)
	if _had_config:
		_original_config = FileAccess.get_file_as_bytes(CONFIG_PATH)
	_config_saved = true
	var expected := _project_settings()
	_write(CONFIG_PATH, JSON.stringify(expected, "  "))
	var before := FileAccess.get_file_as_bytes(CONFIG_PATH)
	_override_machine_settings()
	_dock = DOCK.instantiate()
	add_control_to_bottom_panel(_dock, "Lint contract fixture")
	_expect(_dock.get("_ready_complete") == true, "real dock completed initialization")
	_check_loaded_values()
	_expect(FileAccess.get_file_as_bytes(CONFIG_PATH) == before, "opening dock never rewrites config")
	# Use the actual control signal -> limits handler -> save callback -> JSON chain.
	_dock.settings_controls.max_params_spin.value = 7
	expected.limits.max_parameters = 7
	_check_saved(expected, "single limit change")
	_expect(EditorInterface.get_editor_settings().get_setting("code_quality/limits/max_params") == 2,
		"analysis change does not persist a machine override")
	before = FileAccess.get_file_as_bytes(CONFIG_PATH)
	_dock._rebuild_settings_panel()
	_expect(_dock.settings_manager.config == _dock.current_config, "theme rebuild shares current config")
	_expect(FileAccess.get_file_as_bytes(CONFIG_PATH) == before, "theme rebuild never rewrites config")
	_expect(_dock.settings_controls.max_params_spin.value == 7, "theme rebuild preserves saved limit")
	_dock.settings_controls.check_long_lines.button_pressed = true
	expected.checks.long_lines = true
	_check_saved(expected, "check toggle after rebuild")
	_write(CONFIG_PATH, "{ malformed JSON")
	_dock.settings_controls.max_params_spin.value = 8
	_expect(FileAccess.get_file_as_string(CONFIG_PATH) == "{ malformed JSON",
		"saving a control cannot overwrite an invalid external config")
	_restore()
	await _wait_for_filesystem()
	_write(report_path, JSON.stringify({"checks": _checks, "failures": _failures,
		"engine": Engine.get_version_info()}, "  ") + "\n")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _wait_for_filesystem() -> void:
	await get_tree().process_frame
	var filesystem := EditorInterface.get_resource_filesystem()
	var deadline := Time.get_ticks_msec() + 10000
	while filesystem.is_scanning() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_expect(not filesystem.is_scanning(), "editor filesystem scan completed before continuing")


func _project_settings() -> Dictionary:
	return {
		"metrics": {"file_length": "code", "function_length": "code"},
		"limits": {"file_lines_soft": 177, "file_lines_hard": 333, "function_lines": 23,
			"function_lines_critical": 47, "max_parameters": 6, "max_nesting": 5,
			"max_line_length": 96, "cyclomatic_warning": 9, "cyclomatic_critical": 17,
			"god_class_functions": 19, "god_class_signals": 11, "god_class_exports": 13,
			"future_limit": 456},
		"checks": {"long_lines": false, "magic_numbers": false, "ignore_underscore_prefix": false,
			"ascii_only_project_wide": true, "future_check": false},
		"scanning": {"respect_gdignore": false, "scan_addons": true,
			"respect_ignore_directives": false, "included_addons": ["project_only"],
			"excluded_addons": ["project_excluded"]},
		"exclude": {"paths": ["res://generated/"]},
		"future_section": {"preserve": "project-owned"},
	}


func _check_loaded_values() -> void:
	var config = _dock.current_config
	_expect(config.max_parameters == 6 and config.function_line_limit == 23,
		"project limits win over machine limits")
	_expect(not config.check_long_lines and not config.check_magic_numbers,
		"project check switches survive load")
	_expect(not config.respect_gdignore and config.scan_addons, "project scan switches survive load")
	_expect(config.included_addons == ["project_only"] and config.excluded_addons == ["project_excluded"],
		"project addon lists win over machine lists")
	_expect(config.file_length_metric == "code" and not config.ignore_underscore_prefix,
		"settings without panel controls survive load")
	_expect(not _dock.settings_controls.check_long_lines.button_pressed,
		"real checkbox reflects project value")
	_expect(_dock.settings_controls.max_params_spin.value == 6, "real spinbox reflects project value")
	_expect(not _dock.settings_manager.show_debt, "display preference remains machine-local")


func _check_saved(expected: Dictionary, label: String) -> void:
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	_expect(saved is Dictionary, label + " saves valid JSON")
	if saved is Dictionary:
		for section: String in expected:
			var actual_section: Dictionary = saved.get(section, {})
			for key: String in expected[section]:
				_expect(actual_section.get(key) == expected[section][key],
					label + " preserves " + section + "." + key)
	var reloaded := CONFIG.new()
	_expect(reloaded.load_from_json(CONFIG_PATH), label + " reloads through production config loader")
	_expect(reloaded.max_parameters == 7, label + " survives load/save round trip")


func _override_machine_settings() -> void:
	var settings := EditorInterface.get_editor_settings()
	for key: String in MACHINE_OVERRIDES:
		_machine_snapshot[key] = {"exists": settings.has_setting(key),
			"value": settings.get_setting(key) if settings.has_setting(key) else null}
		settings.set_setting(key, MACHINE_OVERRIDES[key])


func _restore() -> void:
	if is_instance_valid(_dock):
		remove_control_from_bottom_panel(_dock)
		_dock.free()
		_dock = null
	var settings := EditorInterface.get_editor_settings()
	for key: String in _machine_snapshot:
		if _machine_snapshot[key].exists:
			settings.set_setting(key, _machine_snapshot[key].value)
		else:
			settings.erase(key)
	_machine_snapshot.clear()
	if _config_saved:
		if _had_config:
			var original := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
			if original != null:
				original.store_buffer(_original_config)
				original.close()
			else:
				_expect(false, "restore original fixture config")
		else:
			_expect(DirAccess.remove_absolute(CONFIG_PATH) == OK, "remove temporary project config")
		_config_saved = false


func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "open output: " + path)
	if file != null:
		file.store_string(content)
		file.close()


func _expect(value: bool, description: String) -> void:
	_checks += 1
	if not value:
		_failures.append(description)
