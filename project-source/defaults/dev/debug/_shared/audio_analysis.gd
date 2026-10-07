extends VBoxContainer
## Shows analyzer metrics for the selected slot's audio candidate; each file runs once per session.

## `result` is the status-bar result of the analysis action, e.g. "已填入基础音高 B6".
signal edited(result: Dictionary)

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Service := preload("res://dev/debug/_shared/analyzer_service.gd")
const SlotPanel := preload("res://dev/debug/_shared/slot_panel.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const MODULES: Array[String] = ["audio_max_rms", "audio_attack_decay", "audio_spectrum",
	"audio_true_peak", "audio_pitch"]
const ROWS: Array[Array] = [["时长", "duration"], ["峰值", "sample_peak"], ["真峰值", "true_peak"],
	["RMS", "rms"], ["20 ms 最大 RMS", "max_rms_20ms"], ["起音 10%→90%", "attack_10_90"],
	["衰减至 10%", "decay_to_10"], ["频谱重心", "spectral_centroid"]]
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
	if not state.status in ["success", "partial"]:
		block.add_child(_note(state.message, String(state.get("detail", ""))))
		return
	if state.status == "partial":
		block.add_child(_note("有几项指标没算出来，其余照常显示", state.message))
	var metrics: Dictionary = state.data.metrics
	block.add_child(_grid(metrics))
	if _slot.actions != null and _slot.actions.has_method("analysis_extras"):
		_add_extras(block, _slot.actions.analysis_extras(_slot.live, metrics))


func _grid(metrics: Dictionary) -> MarginContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	grid.add_child(_tile(_pitch_caption(metrics), _pitch(metrics)))
	for row in ROWS:
		grid.add_child(_tile(row[0], _format(metrics.get(row[1], {}))))
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 8)
	margins.add_theme_constant_override("margin_top", 4)
	margins.add_theme_constant_override("margin_bottom", 8)
	margins.add_child(grid)
	return margins


func _tile(caption: String, value: String) -> PanelContainer:
	var lines := Kit.column(0)
	lines.add_child(Kit.label(caption, &"MetricCaption"))
	var shown := Kit.elided(value, &"MetricValue")
	shown.tooltip_text = value
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
	var started := service.analyze(path, "audio", MODULES, _finished.bind(path))
	if started.error != OK:
		_results[path] = {"status": "unavailable", "message": started.message,
			"detail": String(started.get("detail", ""))}


func _finished(state: Dictionary, path: String) -> void:
	if state.status == "failed":
		state.message = "分析失败：analyzer 无法分析这个文件。悬停这行文字看原因" 			if state.has("data") else "分析失败：" + state.message
	_results[path] = state
	if _candidate != null and _candidate.resource_path == path:
		_render()


static func _format(entry: Dictionary) -> String:
	if entry.get("status") != "available":
		return "没有算出（%s）" % entry.get("reason", "")
	var value: Variant = entry.value
	return "%s %s" % [String.num(value, 3) if value is float else str(value), entry.unit]


static func _pitch(metrics: Dictionary) -> String:
	var note: Dictionary = metrics.get("pitch_note", {})
	if note.get("status") != "available":
		return "无明确音高（%s）" % note.get("reason", "missing")
	var hertz: Dictionary = metrics.get("pitch", {})
	if hertz.get("status") == "available":
		return "%s · %s" % [note.value, _format(hertz)]
	return String(note.value)


static func _pitch_caption(metrics: Dictionary) -> String:
	var confidence: Dictionary = metrics.get("pitch_confidence", {})
	if confidence.get("status") == "available":
		return "基础音高 · 置信度 %.2f" % confidence.value
	return "基础音高"
