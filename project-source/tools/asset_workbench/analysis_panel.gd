extends Window

## Shared browser selection, independent analysis A/B. Never binds or saves a game cue.

signal results_changed

const Service = preload("res://tools/asset_workbench/analysis_service.gd")
const Result = preload("res://tools/asset_workbench/analysis_result.gd")
const Chart = preload("res://tools/asset_workbench/analysis_chart.gd")
const Appearance = preload("res://tools/asset_workbench/workbench_theme.gd")
const Source = preload("res://tools/asset_workbench/analysis_source.gd")
const Widgets = preload("res://tools/asset_workbench/workbench_widgets.gd")

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
var _comparison: Label = Label.new()
var _summaries: Array[Label] = []
var _issues: Label = Label.new()
var _analyze_buttons: Array[Button] = []
var _reanalyze_buttons: Array[Button] = []


func _ready() -> void:
	title = "源资源分析 · 分析对比 A/B"
	size = Vector2i(1600, 900)
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
	theme = Appearance.create(dark)


func open_asset(asset: Resource) -> void:
	_selected = asset
	_selection_label.text = "候选：%s · %s（下方按钮指定分析 A/B，已有结果保持各自来源）" % [
		asset.resource_path.get_file(), "图像" if asset is Texture2D else "音频"]
	_selection_label.tooltip_text = asset.resource_path
	_refresh()
	if not visible:
		popup_centered(Vector2i(1600, 900))
	grab_focus()


func open_results(first: Dictionary, second: Dictionary) -> void:
	_cancel()
	_tasks = [0, 0]
	_selected = null
	results = [first.duplicate(true), second.duplicate(true)]
	for index: int in 2:
		_paths[index] = ProjectSettings.localize_path(results[index].asset.path)
		_kinds[index] = results[index].asset.type
	_selection_label.text = "批量结果 / 历史快照；下方 A/B 名称是各自分析来源。重分析可检查当前文件。"
	_refresh()
	popup_centered(Vector2i(1600, 900))
	grab_focus()


func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
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
	Widgets.label(root, "源资源分析 · 分析对比 A/B").add_theme_font_size_override("font_size", 21)
	Widgets.label(root, "测量原始图像 / 音频；不代表 Cue 增益、最终混音或 Shader 渲染质量。")
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_selection_label)
	var actions := HFlowContainer.new()
	root.add_child(actions)
	for index: int in 2:
		_analyze_buttons.append(Widgets.button(actions, "候选 → 分析 " + ["A", "B"][index],
			_analyze.bind(index)))
		_reanalyze_buttons.append(Widgets.button(actions, "重分析 " + ["A", "B"][index],
			_reanalyze.bind(index)))
	Widgets.button(actions, "取消分析", _cancel)
	Widgets.button(actions, "按当前条件重分析 A/B", _reanalyze_both)
	Widgets.button(actions, "关闭", _close)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)
	_comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_comparison)
	for index: int in 2:
		_summaries.append(Widgets.label(root, "分析 %s：未分析" % ["A", "B"][index]))
	_issues.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_issues)
	_build_options(Widgets.section(root, "分析条件与判定规则", true))
	_build_results(root)
	_refresh()


func _build_options(root: Container) -> void:
	var options := HFlowContainer.new()
	root.add_child(options)
	for text: String in ["静音阈值 (dBFS)", "允许首尾静音 (s)"]:
		var label := Label.new()
		label.text = text
		options.add_child(label)
		options.add_child(_threshold if text.begins_with("静音") else _edge_rule)
	_threshold.min_value = -120
	_threshold.max_value = 0
	_threshold.value = -50
	_threshold.value_changed.connect(func(_value: float) -> void: _refresh())
	_edge_rule.min_value = 0
	_edge_rule.max_value = 10
	_edge_rule.step = 0.01
	_edge_rule.value = 0.05
	_edge_rule.value_changed.connect(func(_value: float) -> void: _refresh())


func _build_results(root: Container) -> void:
	Widgets.label(root, "详细测量（缺失 / 不支持不会记作 0）")
	_table.columns = 3
	_table.hide_root = true
	_table.column_titles_visible = true
	_table.custom_minimum_size.y = 250
	for index: int in 3:
		_table.set_column_title(index, ["指标与单位", "分析 A", "分析 B"][index])
	root.add_child(_table)
	root.add_child(_series)
	_series.item_selected.connect(_show_series)
	_chart.custom_minimum_size = Vector2(360, 210)
	root.add_child(_chart)
	Widgets.label(root, "音频包络：横轴为时间 (s)，纵轴为线性满幅幅度；不是 dB 或播放后音量。"
		+ "图像分布按图中实际坐标与单位读取。滚轮缩放，右键还原。")
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Widgets.section(root, "来源路径、分析器与参数（可复制）", true).add_child(_details)
	Widgets.button(root, "查看并复制完整分析详情…", func() -> void:
		Widgets.show_text(self, "源资源分析详情", _details.text))


func _analyze(index: int) -> void:
	if _selected == null:
		_status.text = "Select an asset in the existing browser first."
		return
	var source := Source.describe(_selected)
	service.cancel(_tasks[index])
	_tasks[index] = 0
	_kinds[index] = source.type
	if not source.issue.is_empty():
		_paths[index] = ""
		results[index] = Result.failure(source.path, source.type, source.issue.code, source.issue.message)
		_refresh()
		return
	_paths[index] = source.path
	_kinds[index] = source.type
	var other := 1 - index
	if _kinds[other] != "" and _kinds[other] != _kinds[index]:
		service.cancel(_tasks[other])
		_tasks[other] = 0
		results[other] = {}
		_paths[other] = ""
		_kinds[other] = ""
	_submit(index, false)


func _reanalyze(index: int) -> void:
	if not _paths[index].is_empty():
		_submit(index, true)


func _reanalyze_both() -> void:
	for index: int in 2:
		_reanalyze(index)


func _stale(index: int) -> bool:
	var data: Dictionary = results[index]
	return data.get("status") in ["success", "partial"] and data.get(
		"parameters", {}).get("silence_dbfs") != _threshold.value


func _comparison_reason() -> String:
	var reason := Result.comparison_reason(results[0], results[1])
	for index: int in 2:
		if _stale(index) and results[index].status in ["success", "partial"]:
			reason += " %s STALE: settings changed." % ["A", "B"][index]
	return reason.strip_edges()


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
	_status.text = "分析 %s · %s：%s" % [["A", "B"][index],
		str(data.get("asset", {}).get("path", _paths[index])).get_file(), data.get("status", "未知")]
	_refresh()


func _state_changed(task_id: int, state: String) -> void:
	var index := _tasks.find(task_id)
	if index >= 0:
		_status.text = "分析 %s · %s：%s；预览和播放仍可使用。" % [
			["A", "B"][index], _paths[index].get_file(), state]


func _update_comparison_notice() -> void:
	var reason := _comparison_reason()
	_comparison.text = "分析对比 A/B：选择同类源资源后按需分析，与对象方案无关。"
	if not results[0].is_empty() and not results[1].is_empty():
		_comparison.text = "分析对比 A/B：分析条件兼容。"
	if not reason.is_empty():
		_comparison.text = reason + " Reanalyze both before comparing."
	for index: int in 2:
		_table.set_column_title(index + 1, "分析 " + ["A", "B"][index]
			+ (" [STALE]" if _stale(index) else ""))


func _refresh() -> void:
	if _summaries.size() < 2:
		return
	_update_comparison_notice()
	for index: int in 2:
		_summaries[index].text = _summary(index)
		_analyze_buttons[index].disabled = _selected == null
		_reanalyze_buttons[index].disabled = _paths[index].is_empty()
	_issues.text = _issue_summary(0) + "\n" + _issue_summary(1)
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
	results_changed.emit()


func source_status(path: String) -> String:
	var states: Array[String] = []
	for index: int in 2:
		var source: String = results[index].get("asset", {}).get("path", _paths[index])
		if not path.is_empty() and ProjectSettings.localize_path(source) == path:
			var state: String = "分析中" if _tasks[index] > 0 else str(
				results[index].get("status", "未分析"))
			states.append(["A", "B"][index] + " " + ("已过期 (STALE)" if _stale(index) else state))
	return "；".join(states) if not states.is_empty() else "未分析（当前无结果）"


func _summary(index: int) -> String:
	var data := results[index]
	var asset: Dictionary = data.get("asset", {})
	var path: String = asset.get("path", _paths[index])
	var state: String = "分析中" if _tasks[index] > 0 else str(data.get("status", "未分析"))
	var heading := "分析 %s · %s · %s · %s" % [["A", "B"][index],
		path.get_file() if not path.is_empty() else "未指定源资源",
		asset.get("type", _kinds[index]), state + (" [STALE]" if _stale(index) else "")]
	var metrics: Dictionary = data.get("metrics", {})
	var core := {"width": "源图宽", "height": "源图高", "transparent_ratio": "全透明像素占比",
		"duration": "时长", "sample_peak": "采样峰值", "rms": "RMS", "integrated_loudness": "综合响度"}
	var values: Array[String] = []
	for key: String in core:
		if metrics.has(key):
			values.append(core[key] + "：" + Result.metric_text(metrics[key]))
	return heading + ("\n" + " | ".join(values) if not values.is_empty() else "")


func _issue_summary(index: int) -> String:
	var data := results[index]
	if data.is_empty():
		return ""
	var issues: Array[String] = []
	for issue: Dictionary in data.get("warnings", []) + data.get("errors", []):
		issues.append(str(issue.message))
	issues.append_array(Result.rule_messages(data, _edge_rule.value))
	return "分析 %s · 问题摘要：%s" % [["A", "B"][index],
		"未返回警告 / 错误" if issues.is_empty() else "；".join(issues)]


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
		results[1].get("series", {}).get(key, {}), _comparison_reason())


func _cancel() -> void:
	for task_id: int in _tasks.duplicate():
		service.cancel(task_id)


func _close() -> void:
	_cancel()
	hide()
