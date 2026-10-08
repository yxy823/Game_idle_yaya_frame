extends PanelContainer
## The combo bar: the combo dropdown with its save, save-as and delete icons, then the compact
## compare switch "当前改动 ` 对比对象" whose shown side is filled with the accent, the
## difference count and the deferred-switch hint.

signal requested(action: String)
signal combo_chosen(value: String)
signal compare_chosen(value: String)

const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Select := preload("res://dev/debug/_shared/debug_select.gd")
const BAR_HEIGHT := 56.0
const COMBO_WIDTH := 168.0
const SIDE_PADDING := 10.0
const MENU_BUTTON := 22.0
const NAME_WIDTH := 140.0
## The combo dropdown without a combo, and its first item; the compare side names the
## comparison with its own words, so the two never show the same caption.
const NO_COMBO := "未选"
const GAME_COMBO := "不用组合（游戏原值）"
const LOCKED_PLAYING := "播放中不能改组合：点播放条的“回到开头”结束播放后可用"
const LOCKED_COMPARING := "正在显示对比对象：按 ` 回到当前改动后可用"

var combo_select: Select
var current_side: Button
var compare_side: Button
var compare_menu: MenuButton
var differences: PanelContainer
var pending: PanelContainer
var save: Button
var save_as: Button
var delete: Button
var _current_name: Label
var _compare_name: Label
var _save_badge: Panel
var _combos: PackedStringArray = []
var _targets: PackedStringArray = []
var _session: Session


func _init() -> void:
	name = "CompareBar"
	theme_type_variation = &"CompareBar"
	custom_minimum_size.y = BAR_HEIGHT
	var line := Kit.row(12)
	add_child(line)
	combo_select = Select.new("", "组合")
	combo_select.min_width = COMBO_WIDTH
	combo_select.tooltip_text = "组合：每个插槽各选一个预设。选择后载入整套设定"
	combo_select.about_to_popup.connect(_fill_combos)
	combo_select.chosen.connect(func(index: int) -> void:
		combo_chosen.emit("" if index == 0 else _combos[index - 1]))
	line.add_child(combo_select)
	_build_tools(line)
	line.add_child(_divider())
	line.add_child(_build_switch())
	differences = Kit.chip("", "arrows-diff")
	line.add_child(differences)
	pending = Kit.chip("", "clock", &"accent")
	pending.tooltip_text = "固定局面播放中，切换在下一遍开头生效"
	line.add_child(pending)
	line.add_child(Kit.spacer())


func _build_tools(line: HBoxContainer) -> void:
	var tools := Kit.row(2)
	save = Kit.icon_button("device-floppy", "保存组合")
	save.pressed.connect(func() -> void: requested.emit("保存组合"))
	_save_badge = Kit.dot()
	save.add_child(_save_badge)
	_save_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_save_badge.offset_left = -10.0
	_save_badge.offset_right = -4.0
	_save_badge.offset_top = 4.0
	_save_badge.offset_bottom = 10.0
	tools.add_child(save)
	save_as = Kit.icon_button("copy-plus", "另存为新组合：用新名字保存当前全部插槽的预设引用")
	save_as.pressed.connect(func() -> void: requested.emit("另存组合"))
	tools.add_child(save_as)
	delete = Kit.icon_button("trash", "删除组合（会要求确认）", &"IconButtonDanger")
	delete.pressed.connect(func() -> void: requested.emit("删除组合"))
	tools.add_child(delete)
	line.add_child(tools)


## "当前改动" and the comparison side share one frame with the ` key cap between them.
func _build_switch() -> PanelContainer:
	var pair := Kit.row(2)
	current_side = _side("显示当前改动（` 键切换）")
	_current_name = _side_label(current_side, "当前改动")
	pair.add_child(current_side)
	var key := Kit.kbd("`")
	key.tooltip_text = "按 ` 在当前改动和对比对象之间切换"
	var key_margin := MarginContainer.new()
	key_margin.add_theme_constant_override("margin_left", 4)
	key_margin.add_theme_constant_override("margin_right", 4)
	key_margin.add_child(key)
	pair.add_child(key_margin)
	compare_side = _side("显示对比对象，只读（` 键切换）")
	_compare_name = _side_label(compare_side, "游戏原值")
	compare_menu = MenuButton.new()
	compare_menu.flat = false
	compare_menu.icon = Kit.icon("chevron-down")
	compare_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compare_menu.custom_minimum_size = Vector2(MENU_BUTTON, MENU_BUTTON)
	compare_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	compare_menu.tooltip_text = "选择对比对象：游戏原值或已保存的组合"
	compare_menu.add_theme_constant_override("icon_max_width", 14)
	compare_menu.about_to_popup.connect(_fill_targets)
	compare_menu.get_popup().id_pressed.connect(func(id: int) -> void:
		compare_chosen.emit("" if id == 0 else _targets[id - 1]))
	compare_side.get_child(0).add_child(compare_menu)
	pair.add_child(compare_side)
	var frame := Kit.panel(&"ABFrame", pair)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.tooltip_text = "对比：青色一侧是游戏正在使用的设定"
	return frame


func _side(tooltip: String) -> Button:
	var side := Button.new()
	side.theme_type_variation = &"ABSegment"
	side.custom_minimum_size.y = Kit.CONTROL
	side.toggle_mode = true
	side.focus_mode = Control.FOCUS_NONE
	side.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	side.tooltip_text = tooltip
	side.pressed.connect(func() -> void:
		var showing := _session != null and _session.comparing == (side == compare_side)
		side.set_pressed_no_signal(showing)
		if not showing:
			requested.emit("对比"))
	var content := Kit.row(6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = SIDE_PADDING
	content.offset_right = -4.0
	return side


func _side_label(side: Button, text: String) -> Label:
	var caption := Kit.label(text, &"ComboName")
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	side.get_child(0).add_child(caption)
	return caption


static func _divider() -> VSeparator:
	var line := VSeparator.new()
	line.custom_minimum_size.y = 20.0
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line


func configure(session: Session) -> void:
	_session = session


func refresh(locked: bool) -> void:
	if _session == null or _session.active == null:
		return
	var comparing := _session.comparing
	_paint_side(current_side, _current_name, "当前改动", not comparing)
	var target := _session.compare_name()
	if not _session.compare_combo.is_empty() and _session.compare_combo == _session.combo_name:
		target = "组合 %s 已存版本" % _session.compare_combo
	_paint_side(compare_side, _compare_name, target, comparing)
	compare_menu.theme_type_variation = &"IconButtonOnAccent" if comparing else &"IconButton"
	var count := _session.compare_differences()
	var readable := _session.compare_readable()
	Kit.chip_text(differences, "%d 处不同" % count if readable else "无法对比")
	differences.tooltip_text = "当前改动和%s相比有 %d 项设定不同" % [_session.compare_name(), count] \
		if readable else "%s读不出来，按 ` 看原因" % _session.compare_name()
	pending.visible = _session.pending_compare
	Kit.chip_text(pending, "下一遍切到" + _session.next_side())
	_paint_combo(locked, comparing)


## The combo dropdown and its icons; they wait while playback runs or the comparison shows.
func _paint_combo(locked: bool, comparing: bool) -> void:
	var combo := _session.combo_name
	combo_select.set_value(combo if not combo.is_empty() else NO_COMBO)
	Messages.usable_tooltip(save, "保存组合：把各插槽当前用的预设存进组合 %s（游戏文件不变）" % combo
		if not combo.is_empty() else "保存为新组合：记录各插槽当前用的预设（游戏文件不变）")
	_save_badge.visible = not combo.is_empty() and _session.combo_dirty()
	var reason := LOCKED_COMPARING if comparing else LOCKED_PLAYING
	var editing := not locked and not comparing
	Messages.explain(combo_select, not editing, reason)
	Messages.explain(save, not editing, reason)
	Messages.explain(save_as, not editing, reason)
	Messages.explain(delete, not editing or combo.is_empty(),
		reason if not editing else "还没有选组合，没有可删除的组合")


## The shown side is filled with the accent and its text uses the accent ink.
func _paint_side(side: Button, caption: Label, text: String, on: bool) -> void:
	side.set_pressed_no_signal(on)
	_fit_name(caption, text)
	caption.add_theme_color_override("font_color", Kit.color(&"accent_ink") if on else Kit.color(&"tx2"))
	var width := caption.custom_minimum_size.x + SIDE_PADDING + 4.0
	if side == compare_side:
		width += MENU_BUTTON + 6.0
	side.custom_minimum_size.x = ceilf(width)


## Long names are elided at NAME_WIDTH.
func _fit_name(label: Label, text: String) -> void:
	label.text = text
	var font := label.get_theme_font(&"font")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		label.get_theme_font_size(&"font_size")).x
	label.clip_text = width > NAME_WIDTH
	label.custom_minimum_size.x = minf(ceilf(width), NAME_WIDTH)


func _fill_combos() -> void:
	_combos = _session.store.list_names(_combo_directory())
	var captions: PackedStringArray = [GAME_COMBO]
	captions.append_array(_combos)
	combo_select.set_items(captions, _combos.find(_session.combo_name) + 1)


func _fill_targets() -> void:
	_targets = _session.store.list_names(_combo_directory())
	var menu := compare_menu.get_popup()
	menu.clear()
	menu.add_radio_check_item("游戏原值", 0)
	menu.set_item_checked(0, _session.compare_combo.is_empty())
	for index in range(_targets.size()):
		menu.add_radio_check_item("组合 " + _targets[index], index + 1)
		menu.set_item_checked(index + 1, _targets[index] == _session.compare_combo)


func _combo_directory() -> String:
	return _session.store.root.path_join(_session.active.id + "/combos")
