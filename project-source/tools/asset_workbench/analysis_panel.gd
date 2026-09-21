extends Window

## Shared browser selection, independent analysis A/B. Never binds or saves a game cue.

const Service = preload("res://tools/asset_workbench/analysis_service.gd")
const Result = preload("res://tools/asset_workbench/analysis_result.gd")
const Chart = preload("res://tools/asset_workbench/analysis_chart.gd")
const Appearance = preload("res://tools/asset_workbench/workbench_theme.gd")

var service: Service = Service.new()
var results: Array[Dictionary] = [{}, {}]
var _selected: Resource
var _tasks: Array[int] = [0, 0]
var _paths: Array[String] = ["", ""]
var _kinds: Array[String] = ["", ""]
var _selection_label: Label = Label.new()
var _status: Label = Label.new()
var _details: Label = Label.new()
var _table: Tree = Tree.new()
var _series: OptionButton = OptionButton.new()
var _chart: Chart = Chart.new()
var _threshold: SpinBox = SpinBox.new()
var _edge_rule: SpinBox = SpinBox.new()
var _background: ColorRect = ColorRect.new()


func _ready() -> void:
	title = "Source asset analysis (independent of event A/B)"
	size = Vector2i(1000, 700)
	min_size = Vector2i(400, 300)
	visible = false
	exclusive = false
	transient = true
	add_child(service)
	service.completed.connect(_completed)
	service.state_changed.connect(_state_changed)
	close_requested.connect(_close)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_build()


func set_background(dark: bool) -> void:
	_background.color = Appearance.background(dark)


func open_asset(asset: Resource) -> void:
	_selected = asset
	_selection_label.text = "Browser selection: " + asset.resource_path
	if not visible:
		popup_centered_clamped(Vector2i(1000, 700), 0.9)
	grab_focus()


func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_selection_label)
	var actions := HFlowContainer.new()
	root.add_child(actions)
	for index: int in 2:
		_button(actions, "Analyze selection as " + ["A", "B"][index], _analyze.bind(index))
		_button(actions, "Reanalyze " + ["A", "B"][index], _reanalyze.bind(index))
	_button(actions, "Cancel tasks", _cancel)
	_button(actions, "Close analysis", _close)
	_build_options(root)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)
	_build_results(root)


func _build_options(root: Container) -> void:
	var options := HFlowContainer.new()
	root.add_child(options)
	for text: String in ["Silence threshold (dBFS)", "Allowed edge silence (s)"]:
		var label := Label.new()
		label.text = text
		options.add_child(label)
		options.add_child(_threshold if text.begins_with("Silence") else _edge_rule)
	_threshold.min_value = -120
	_threshold.max_value = 0
	_threshold.value = -50
	_edge_rule.min_value = 0
	_edge_rule.max_value = 10
	_edge_rule.step = 0.01
	_edge_rule.value = 0.05
	_edge_rule.value_changed.connect(func(_value: float) -> void: _refresh())


func _build_results(root: Container) -> void:
	_table.columns = 3
	_table.hide_root = true
	_table.column_titles_visible = true
	_table.custom_minimum_size.y = 250
	for index: int in 3:
		_table.set_column_title(index, ["Measurement", "A", "B"][index])
	root.add_child(_table)
	root.add_child(_series)
	_series.item_selected.connect(_show_series)
	_chart.custom_minimum_size = Vector2(360, 210)
	root.add_child(_chart)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_details)


func _button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


func _analyze(index: int) -> void:
	if _selected == null:
		_status.text = "Select an asset in the existing browser first."
		return
	_paths[index] = _selected.resource_path
	_kinds[index] = "audio" if _selected is AudioStream else "image"
	var other := 1 - index
	if _kinds[other] != "" and _kinds[other] != _kinds[index]:
		service.cancel(_tasks[other])
		results[other] = {}
		_paths[other] = ""
		_kinds[other] = ""
	_submit(index, false)


func _reanalyze(index: int) -> void:
	if not _paths[index].is_empty():
		_submit(index, true)


func _submit(index: int, force: bool) -> void:
	service.cancel(_tasks[index])
	results[index] = {}
	_tasks[index] = service.submit(_paths[index], _kinds[index],
		{"silence_dbfs": _threshold.value}, force)
	_status.text = "%s queued: %s" % [["A", "B"][index], _paths[index].get_file()]
	_refresh()


func _completed(task_id: int, data: Dictionary) -> void:
	var index := _tasks.find(task_id)
	if index < 0:
		return
	results[index] = data
	_tasks[index] = 0
	_refresh()


func _state_changed(task_id: int, state: String) -> void:
	_status.text = "Task %d: %s. Preview and playback remain available." % [task_id, state]


func _refresh() -> void:
	_table.clear()
	var root := _table.create_item()
	for row: Dictionary in Result.compare_rows(results[0], results[1]):
		var item := _table.create_item(root)
		for index: int in 3:
			var text: String = row[["metric", "a", "b"][index]]
			item.set_text(index, text)
			item.set_tooltip_text(index, text)
	_details.text = _result_details(0) + "\n" + _result_details(1)
	var previous := _series.get_item_text(_series.selected) if _series.selected >= 0 else ""
	_series.clear()
	var names: Dictionary = results[0].get("series", {}).duplicate()
	names.merge(results[1].get("series", {}))
	for key: String in names:
		_series.add_item(key)
		if key == previous:
			_series.select(_series.item_count - 1)
	_show_series(maxi(_series.selected, 0))


func _result_details(index: int) -> String:
	var data: Dictionary = results[index]
	if data.is_empty():
		return "%s: no result" % ["A", "B"][index]
	var lines: Array[String] = ["%s: %s | %s | cache %s" % [["A", "B"][index],
		data.asset.path, data.status, "HIT" if data.cache.hit else "MISS"],
		"Backend: " + JSON.stringify(data.analyzer.backend),
		"Parameters: " + JSON.stringify(data.get("parameters", {}))]
	for issue: Dictionary in data.warnings + data.errors:
		lines.append(str(issue.message))
	lines.append_array(Result.rule_messages(data, _edge_rule.value))
	return "\n".join(lines)


func _show_series(index: int) -> void:
	var key := _series.get_item_text(index) if index < _series.item_count else ""
	_chart.display(results[0].get("series", {}).get(key, {}),
		results[1].get("series", {}).get(key, {}))


func _cancel() -> void:
	for task_id: int in _tasks.duplicate():
		service.cancel(task_id)


func _close() -> void:
	_cancel()
	hide()
