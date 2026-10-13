extends VBoxContainer
## Shows GAA metrics for the selected audio candidate; each file runs once per session.

## `result` is the status-bar result of the analysis action, e.g. "已填入基础音高 B6".
signal edited(result: Dictionary)

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Service := preload("res://dev/debug/_shared/analyzer_service.gd")
const SlotPanel := preload("res://dev/debug/_shared/slot_panel.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const ROWS: Array[Array] = [["时长", "duration_s"], ["峰值", "peak_dbfs"],
	["真峰值", "true_peak_estimate_dbtp"], ["RMS", "rms_dbfs"],
	["20 ms 最大 RMS", "max_rms_20ms_dbfs"], ["起音 10%→90%", "attack_10_90_s"],
	["衰减至 10%", "decay_to_10_s"], ["频谱重心", "spectral_centroid_hz"]]
const STATUS_TEXT := {"silent": "静音", "not_applicable": "不适用",
	"insufficient_data": "数据不足", "below_threshold": "低于筛选阈值",
	"not_analyzed": "未分析", "disabled": "已关闭"}
const NOTE_NAMES := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const COLUMNS := 3
const GRID_GAP := 8

var service: Service
var locked: bool = false
var lock_reason: String = ""
var _slot: Slot
var _candidate: AudioStream
var _results: Dictionary[String, Dictionary] = {}


func _init(analyzer: Service) -> void:
	service = analyzer
	add_theme_constant_override("separation", 0)


## Follows the panel's selection and lock; on_edited rebuilds the panel after a fill.
func attach(panel: SlotPanel, on_edited: Callable) -> void:
	panel.analysis_host.add_child(self)
	panel.analysis_changed.connect(func(_slot_id: String, candidate: Resource) -> void:
		locked = panel.locked
		lock_reason = panel.lock_reason
		show_candidate(panel.slot, candidate))
	edited.connect(on_edited)


func show_candidate(slot: Slot, candidate: Resource) -> void:
	_slot = slot
	_candidate = candidate as AudioStream
	_render()


func _render() -> void:
	Kit.clear(self)
	if _slot == null or _candidate == null:
		return
	var path := _candidate.resource_path
	if not _results.has(path):
		_start(path)
	var state := _results[path]
	var block := Kit.section("分析")
	var header := block.get_child(0) as HBoxContainer
	var file := Kit.label(path.get_file(), &"MonoId")
	header.add_child(file)
	header.move_child(file, 1)
	add_child(Kit.section_frame(block, false))
	if state.status != "success":
		block.add_child(_note(state.message, String(state.get("detail", ""))))
		return
	var metrics: Dictionary = state.data.metrics
	block.add_child(_grid(metrics))
	if _slot.actions != null and _slot.actions.has_method("analysis_extras"):
		_add_extras(block, _slot.actions.analysis_extras(_slot.live, metrics))


func _grid(metrics: Dictionary) -> MarginContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	grid.add_child(_tile("基础音高", _pitch(metrics), metrics.get("f0_median_hz", {})))
	for row in ROWS:
		var entry: Dictionary = metrics.get(row[1], {})
		grid.add_child(_tile(row[0], _format(entry), entry))
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 8)
	margins.add_theme_constant_override("margin_top", 4)
	margins.add_theme_constant_override("margin_bottom", 8)
	margins.add_child(grid)
	return margins


func _tile(caption: String, value: String, entry: Dictionary) -> PanelContainer:
	var lines := Kit.column(0)
	lines.add_child(Kit.label(caption, &"MetricCaption"))
	var shown := Kit.elided(value, &"MetricValue")
	shown.tooltip_text = value
	if entry.get("status") in ["ok", "estimate"] and not str(entry.get("note", "")).is_empty():
		shown.tooltip_text += "\n" + str(entry.note)
	shown.mouse_filter = Control.MOUSE_FILTER_PASS
	lines.add_child(shown)
	var tile := Kit.panel(&"MetricTile", lines)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return tile


## The slot's analysis action sits in the section header; its notes follow the metrics.
func _add_extras(block: VBoxContainer, extras: Dictionary) -> void:
	var reason := String(extras.get("reason", ""))
	var action := Kit.text_button(extras.action, extras.get("icon", ""),
		reason if not reason.is_empty() else extras.get("tooltip", ""))
	Messages.explain(action, locked or not reason.is_empty(), reason if not reason.is_empty()
		else lock_reason)
	action.pressed.connect(func() -> void:
		var done: Variant = extras.apply.call()
		edited.emit({"error": OK, "text": done if done is String else ""}))
	block.get_child(0).add_child(action)
	for note: String in extras.get("notes", []):
		block.add_child(_note(note))


func _note(text: String, detail: String = "") -> MarginContainer:
	var label := Kit.label(text, &"StatusText")
	if not detail.is_empty():
		label.tooltip_text = detail
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 8)
	margins.custom_minimum_size.y = Kit.INLINE
	margins.add_child(label)
	return margins


func _start(path: String) -> void:
	_results[path] = {"status": "pending", "message": "分析中…"}
	var started := service.analyze(path, "audio", _finished.bind(path))
	if started.error != OK:
		_results[path] = {"status": "unavailable", "message": started.message,
			"detail": String(started.get("detail", ""))}


func _finished(state: Dictionary, path: String) -> void:
	_results[path] = state
	if _candidate != null and _candidate.resource_path == path:
		_render()


static func _format(entry: Dictionary) -> String:
	var status := str(entry.get("status", "not_analyzed"))
	var value: Variant = entry.get("value")
	if status not in ["ok", "estimate"] or not (value is float or value is int):
		var reason := str(STATUS_TEXT.get(status, "无数值（%s）" % status))
		var note := str(entry.get("note", ""))
		return reason if note.is_empty() else "%s（%s）" % [reason, note]
	return "%s %s%s" % [String.num(float(value), 3), entry.unit,
		"（估算）" if status == "estimate" else ""]


static func _pitch(metrics: Dictionary) -> String:
	var entry: Dictionary = metrics.get("f0_median_hz", {})
	var shown := _format(entry)
	var value: Variant = entry.get("value")
	if entry.get("status") not in ["ok", "estimate"] or not (value is float or value is int):
		return shown
	if float(value) <= 0.0:
		return shown
	var midi := roundi(69.0 + 12.0 * log(float(value) / 440.0) / log(2.0))
	var note: String = NOTE_NAMES[posmod(midi, 12)] + str(floori(midi / 12.0) - 1)
	return "%s · %s" % [note, shown]
