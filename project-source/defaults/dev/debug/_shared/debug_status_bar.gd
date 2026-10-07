extends VBoxContainer
## The status bar: unsaved count, combo note, the last result in plain words and its "详情"
## button, which opens the raw details above the bar; the ` hint sits at the right.

const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const STATUS_HEIGHT := 26.0
const DETAIL_HEIGHT := 96.0

var message: Label
var details: Button
var detail_text: Label
var _detail_panel: PanelContainer
var _unsaved: HBoxContainer
var _combo_note: Label


func _init() -> void:
	name = "Status"
	add_theme_constant_override("separation", 0)
	detail_text = Kit.label("", &"MonoId")
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = DETAIL_HEIGHT
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 8)
	margins.add_child(detail_text)
	scroll.add_child(margins)
	_detail_panel = Kit.panel(&"DrawerPanel", scroll)
	_detail_panel.visible = false
	add_child(_detail_panel)
	add_child(_build_bar())


func _build_bar() -> PanelContainer:
	var line := Kit.row(16)
	var bar := Kit.panel(&"StatusBar", line)
	bar.custom_minimum_size.y = STATUS_HEIGHT
	_unsaved = Kit.row(6)
	_unsaved.add_child(Kit.dot())
	_unsaved.add_child(Kit.label("", &"WarnText"))
	_unsaved.visible = false
	line.add_child(_unsaved)
	_combo_note = Kit.label("组合未保存", &"HintText")
	_combo_note.visible = false
	line.add_child(_combo_note)
	message = Kit.elided("", &"HintText")
	message.mouse_filter = Control.MOUSE_FILTER_PASS
	line.add_child(message)
	details = Kit.text_button("详情", "chevron-up", "展开或收起原始信息，方便交给 Agent 排查",
		&"DrawerHeader")
	details.custom_minimum_size.y = Kit.INLINE
	details.visible = false
	details.pressed.connect(func() -> void: set_details_open(not _detail_panel.visible))
	line.add_child(details)
	var shortcut := Kit.row(6)
	shortcut.add_child(Kit.kbd("`"))
	shortcut.add_child(Kit.label("对比", &"HintText"))
	line.add_child(shortcut)
	return bar


func set_details_open(value: bool) -> void:
	_detail_panel.visible = value and details.visible
	details.icon = Kit.icon("chevron-down" if _detail_panel.visible else "chevron-up")


func set_counts(unsaved: int, combo_dirty: bool) -> void:
	_unsaved.visible = unsaved > 0
	(_unsaved.get_child(1) as Label).text = "%d 个插槽未保存" % unsaved
	_combo_note.visible = combo_dirty


## Shows a result's "text"; a failure without one gets a plain fallback. Raw messages, issues
## and engine error names only appear under "详情".
func show_result(result: Dictionary) -> void:
	var error: int = result.get("error", OK)
	var text := String(result.get("text", ""))
	if text.is_empty():
		text = String(result.get("message", "")) if error == OK \
			else "这一步没有完成：%s。点“详情”看原始信息" % Messages.reason(error)
	var raw := String(result.get("detail", ""))
	if raw.is_empty() and (error != OK or not result.get("issues", PackedStringArray()).is_empty()):
		raw = Messages.detail(result)
	message.text = text
	message.tooltip_text = text
	if error != OK:
		message.add_theme_color_override("font_color", Kit.color(&"tx1"))
	else:
		message.remove_theme_color_override("font_color")
	detail_text.text = raw
	details.visible = not raw.is_empty()
	set_details_open(false)
