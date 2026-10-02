@tool
extends EditorPlugin
## Install only as a temporary addon in a dedicated external verification project.
## Exercises the bundled plugins through the real editor; never copied to new games.

const PLUGINS := [
	"script-ide", "inspector_tabs", "kanban_tasks",
	"resources_spreadsheet_view", "signal_lens",
]
const REPORT := "res://reports/editor-plugin-lifecycle.json"
const DATA_DIR := "res://tests/editor_plugin_probe_data"
var checks: Array[Dictionary] = []
var inspected_resource: Gradient


func _enter_tree() -> void:
	_run.call_deferred()


func _run() -> void:
	await _settle()
	for addon in PLUGINS:
		if not EditorInterface.is_plugin_enabled(addon):
			EditorInterface.set_plugin_enabled(addon, true)
		await _settle()
		_record(addon + " enabled", _instances(addon).size() == 1)
	_record("Signal Lens autoload registered", ProjectSettings.has_setting("autoload/SignalLens"))

	# Open actual script/inspector consumers while all five plugins are loaded.
	EditorInterface.edit_script(load("res://addons/kanban_tasks/data/task.gd"))
	inspected_resource = Gradient.new()
	EditorInterface.inspect_object(inspected_resource)
	await _settle()
	var ide := _instances("script-ide")
	if ide.size() == 1:
		_record("Script-IDE tabs created", is_instance_valid(ide[0].get("multiline_tab_bar")))
	var inspector := _instances("inspector_tabs")
	if inspector.size() == 1:
		_record("Inspector Tabs inspector registered", inspector[0].get("plugin") != null)

	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	var board_script = load("res://addons/kanban_tasks/data/board.gd")
	var task_script = load("res://addons/kanban_tasks/data/task.gd")
	var board = board_script.new()
	board.load("res://kanban_tasks_data.kanban")
	var task_id: String = board.add_task(task_script.new("Independent idea", "Plugin smoke fixture"))
	board.save(DATA_DIR + "/idea.kanban")
	var reloaded = board_script.new()
	reloaded.load(DATA_DIR + "/idea.kanban")
	_record("Kanban board save and reload", reloaded.get_task(task_id).title == "Independent idea")

	var resource_path := DATA_DIR + "/gradient.tres"
	_record("Resource fixture saved", ResourceSaver.save(inspected_resource, resource_path) == OK)
	EditorInterface.get_resource_filesystem().scan()
	await _settle()
	var tables := _instances("resources_spreadsheet_view")
	if tables.size() == 1:
		var view = tables[0].get("editor_view")
		view.display_folder(DATA_DIR)
		await _settle()
		_record("ResourceTables folder opened", view.get("current_path").trim_suffix("/") == DATA_DIR)
		_record("ResourceTables resource loaded", view.get("remembered_paths").has(resource_path))

	for addon in PLUGINS:
		var help_menu: Object = null
		var table_view: Object = null
		var instances := _instances(addon)
		if addon == "kanban_tasks" and instances.size() == 1:
			help_menu = instances[0].get("help_menu")
		if addon == "resources_spreadsheet_view" and instances.size() == 1:
			table_view = instances[0].get("editor_view")
		EditorInterface.set_plugin_enabled(addon, false)
		await _settle()
		_record(addon + " disabled", _instances(addon).is_empty())
		if addon == "kanban_tasks":
			_record("Kanban detached help menu freed", not is_instance_valid(help_menu))
			_record("Kanban singleton holder removed", get_tree().root.get_node_or_null("PluginSingletons") == null)
		if addon == "signal_lens":
			_record("Signal Lens autoload removed", not ProjectSettings.has_setting("autoload/SignalLens"))
		if addon == "resources_spreadsheet_view":
			_record("ResourceTables editor view freed", not is_instance_valid(table_view))
		EditorInterface.set_plugin_enabled(addon, true)
		await _settle()
		_record(addon + " re-enabled once", _instances(addon).size() == 1)

	# Restore both optional plugins to the shipped disabled state.
	EditorInterface.set_plugin_enabled("signal_lens", false)
	EditorInterface.set_plugin_enabled("resources_spreadsheet_view", false)
	await _settle()
	var passed := true
	for check in checks:
		passed = passed and check.passed
	DirAccess.make_dir_recursive_absolute(REPORT.get_base_dir())
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "checks": checks}, "\t") + "\n")
	file.close()
	print("EDITOR_PLUGIN_PROBE ", "PASS" if passed else "FAIL", ": ", checks.size(), " checks")
	get_tree().quit(0 if passed else 1)


func _instances(addon: String) -> Array[Node]:
	var found: Array[Node] = []
	var pending: Array[Node] = [get_tree().root]
	var script_path := "res://addons/" + addon + "/plugin.gd"
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		var script = node.get_script()
		if script != null and script.resource_path == script_path:
			found.append(node)
		pending.append_array(node.get_children())
	return found


func _settle() -> void:
	await get_tree().create_timer(0.5).timeout
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame


func _record(label: String, passed: bool) -> void:
	checks.append({"check": label, "passed": passed})
	print("PLUGIN_CHECK ", label, ": ", passed)
