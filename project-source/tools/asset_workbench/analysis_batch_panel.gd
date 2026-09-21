extends Window

## Group membership/report view. The existing browser and A/B charts remain the preview entry.

signal compare_requested(first: Dictionary, second: Dictionary)

const Batch = preload("res://tools/asset_workbench/analysis_batch.gd")
const Group = preload("res://tools/asset_workbench/analysis_group.gd")
const Statistics = preload("res://tools/asset_workbench/analysis_group_statistics.gd")
const Scan = preload("res://tools/asset_workbench/analysis_group_scan.gd")
const Rules = preload("res://tools/asset_workbench/analysis_group_rules.gd")
const Appearance = preload("res://tools/asset_workbench/workbench_theme.gd")

var batch: Batch = Batch.new()
var _scan: Scan = Scan.new()
var _name: LineEdit = LineEdit.new()
var _status: Label = Label.new()
var _notice: Label = Label.new()
var _details: Label = Label.new()
var _members: Tree = Tree.new()
var _statistics: Tree = Tree.new()
var _rules: Rules = Rules.new()
var _file: FileDialog = FileDialog.new()
var _background: ColorRect = ColorRect.new()
var _action: String = ""
var _checks: Dictionary = {}
var _dirty: bool = true


func _ready() -> void:
	title = "Resource groups / batch analysis"
	size = Vector2i(1600, 900)
	min_size = Vector2i(420, 320)
	visible = false
	add_child(batch)
	add_child(_scan)
	batch.changed.connect(func() -> void: _dirty = true)
	_scan.found.connect(_add_discovered)
	_scan.finished.connect(func(message: String) -> void: _notice.text = message)
	close_requested.connect(_close)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_file.access = FileDialog.ACCESS_RESOURCES
	_file.file_selected.connect(_picked)
	_file.dir_selected.connect(func(path: String) -> void: _scan.start(path))
	add_child(_file)
	_build()


func set_background(dark: bool) -> void:
	_background.color = Appearance.background(dark)


func _add_discovered(paths: Array[String]) -> void:
	_notice.text = batch.add_paths(paths)
	if not _notice.text.is_empty():
		_scan.cancel()


func open_assets(assets: Array[Resource]) -> void:
	var paths: Array[String] = []
	for asset: Resource in assets:
		paths.append(asset.resource_path)
	_notice.text = batch.add_paths(paths)
	if not visible:
		popup_centered(Vector2i(1600, 900))
	grab_focus()


func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "GroupScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.follow_focus = true
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)
	_name.text = batch.group.name
	_name.placeholder_text = "Resource group name"
	_name.text_changed.connect(func(value: String) -> void: batch.group.name = value)
	root.add_child(_name)
	_actions(root)
	for label: Label in [_status, _notice]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(label)
	_tables(root)
	root.add_child(_rules)
	_rules.edited.connect(func() -> void: _dirty = true)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_details)


func _actions(root: Container) -> void:
	var actions := HFlowContainer.new()
	root.add_child(actions)
	var buttons := {
		"Analyze group": _start.bind(false), "Force reanalyze": _start.bind(true),
		"Cancel batch / scan": _cancel, "Add source folder": _choose_file.bind("folder"),
		"Remove selected members": _remove, "Compare selected 2": _compare,
		"Save group + rules": _choose_file.bind("save"),
		"Load group (replace)": _choose_file.bind("group"),
		"Save result snapshot": _save_snapshot,
		"Open historical snapshot": _choose_file.bind("snapshot"), "Close": _close}
	for text: String in buttons:
		var button := Button.new()
		button.text = text
		button.pressed.connect(buttons[text])
		actions.add_child(button)


func _tables(root: Container) -> void:
	_members.select_mode = Tree.SELECT_MULTI
	_members.multi_selected.connect(func(_item: TreeItem, _column: int, _selected: bool) -> void:
		_show_selection())
	var headings := [["Member (Ctrl: select two)", "Task / cache", "Rules"],
		["Comparable measurement", "n", "Minimum", "Median", "Maximum"]]
	for index: int in 2:
		var table: Tree = [_members, _statistics][index]
		table.columns = headings[index].size()
		table.hide_root = true
		table.column_titles_visible = true
		table.custom_minimum_size.y = 220 if index == 0 else 160
		for column: int in table.columns:
			table.set_column_title(column, headings[index][column])
		root.add_child(table)


func _process(_delta: float) -> void:
	if _dirty and visible:
		_dirty = false
		_refresh()


func _refresh() -> void:
	if not _name.has_focus():
		_name.text = batch.group.name
	var selected := _selected_paths()
	var stats := Statistics.columns(batch.results)
	_checks = Statistics.checks(batch.group, batch.results, stats)
	_members.clear()
	var root := _members.create_item()
	for asset: Dictionary in batch.group.assets:
		var item := _members.create_item(root)
		item.set_metadata(0, asset.path)
		item.set_text(0, str(asset.path).get_file())
		item.set_tooltip_text(0, asset.path)
		var data: Dictionary = batch.results.get(asset.path, {})
		var state: String = batch.states.get(asset.path, "not analyzed")
		if data.get("cache", {}).get("hit", false):
			state += " / cache HIT"
		item.set_text(1, state)
		item.set_text(2, Statistics.summary(_checks[asset.path]))
		if asset.path in selected:
			item.select(0)
	_status.text = "%d members | %d results | %s" % [batch.group.assets.size(),
		batch.results.size(), "RUNNING" if batch.busy() else "idle"]
	if not batch.historical.is_empty():
		_status.text += " | HISTORICAL %s UTC; reanalyze to check current files" % batch.historical
	_render_stats(stats)
	_rules.display(batch.group.rules, stats)
	_show_selection()


func _render_stats(stats: Dictionary) -> void:
	_statistics.clear()
	var root := _statistics.create_item()
	for column: Dictionary in stats.values():
		var item := _statistics.create_item(root)
		item.set_text(0, "%s / %s [%s]" % [column.type, column.metric, column.unit])
		item.set_tooltip_text(0, JSON.stringify({"analyzer": column.analyzer,
			"parameters": column.parameters}, "  "))
		item.set_text(1, str(column.count))
		for index: int in 3:
			item.set_text(index + 2, "%.5f" % column[["minimum", "median", "maximum"][index]])


func _selected_paths() -> Array[String]:
	var paths: Array[String] = []
	var item := _members.get_next_selected(null)
	while item != null:
		paths.append(str(item.get_metadata(0)))
		item = _members.get_next_selected(item)
	return paths


func _show_selection() -> void:
	var lines: Array[String] = []
	for path: String in _selected_paths():
		lines.append(path)
		for row: Dictionary in _checks.get(path, []):
			lines.append("%s: %s" % [row.status, row.message])
		var data: Dictionary = batch.results.get(path, {})
		for issue: Dictionary in data.get("warnings", []) + data.get("errors", []):
			lines.append(str(issue.message))
	_details.text = "\n".join(lines) if not lines.is_empty() else "Select a member for explanations."


func _compare() -> void:
	var paths := _selected_paths()
	if paths.size() != 2 or not paths.all(func(path: String) -> bool: return batch.results.has(path)):
		_notice.text = "Select exactly two analyzed members with Ctrl."
		return
	var first: Dictionary = batch.results[paths[0]]
	var second: Dictionary = batch.results[paths[1]]
	if first.asset.type != second.asset.type:
		_notice.text = "Choose two resources of the same type."
		return
	compare_requested.emit(first, second)


func _remove() -> void:
	batch.remove_paths(_selected_paths())


func _start(force: bool) -> void:
	_scan.cancel()
	batch.run(force)


func _choose_file(action: String) -> void:
	_action = action
	_file.title = "Choose source folder" if action == "folder" else action.capitalize() + " group JSON"
	_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file.filters = PackedStringArray(["*.json ; Group or snapshot"])
	if action == "folder":
		if batch.busy():
			_notice.text = "Finish or cancel the batch before scanning."
			return
		_file.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	elif action == "save":
		_file.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file.popup_centered_clamped(Vector2i(900, 650), 0.85)


func _picked(path: String) -> void:
	if _action == "save":
		_notice.text = Group.write_json(path, batch.group)
	else:
		var loaded := Group.read_json(path)
		if loaded.has("error"):
			_notice.text = loaded.error
			return
		_scan.cancel()
		_notice.text = batch.load_snapshot(loaded.data) if _action == "snapshot" \
			else batch.load_group(loaded.data)
		_name.text = batch.group.name
	if _notice.text.is_empty():
		_notice.text = "Saved: " + path if _action == "save" else "Opened: " + path


func _save_snapshot() -> void:
	if batch.busy() or batch.results.is_empty() or _scan.active:
		_notice.text = "Finish/cancel the batch and scan before saving results."
		return
	var directory := "res://reports/asset-analyzer/history"
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if error != OK:
		_notice.text = "Cannot create history directory: " + error_string(error)
		return
	var path := directory.path_join("batch-%d-%d.json" % [Time.get_unix_time_from_system(), randi()])
	_notice.text = Group.write_json(path, batch.snapshot())
	if _notice.text.is_empty():
		_notice.text = "Saved results and rules: " + path


func _cancel() -> void:
	_scan.cancel()
	batch.cancel()
	_notice.text = "Cancelled. Completed results and current membership retained."


func _close() -> void:
	_cancel()
	hide()
