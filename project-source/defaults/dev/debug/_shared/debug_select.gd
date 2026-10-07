extends MenuButton
## A dropdown that always shows its current value: optional icon and caption, value, chevron.

signal chosen(index: int)

const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const SMALL := 24.0
const PADDING_LEFT := 8.0
const PADDING_RIGHT := 6.0
const GAP := 6

var value_label: Label
var min_width: float = 0.0:
	set(value):
		min_width = value
		_fit()
var _content: HBoxContainer


func _init(icon_name: String = "", caption: String = "", small: bool = false) -> void:
	flat = false
	theme_type_variation = &"SelectButton"
	custom_minimum_size.y = SMALL if small else Kit.CONTROL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_content = Kit.row(GAP)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_left = PADDING_LEFT
	_content.offset_right = -PADDING_RIGHT
	if not icon_name.is_empty():
		_content.add_child(Kit.glyph(icon_name, 15.0, Kit.color(&"tx3")))
	if not caption.is_empty():
		_content.add_child(Kit.label(caption, &"HintText"))
	value_label = Kit.label("", &"StatusText" if small else &"")
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if small:
		value_label.add_theme_color_override("font_color", Kit.color(&"tx1"))
	_content.add_child(value_label)
	_content.add_child(Kit.glyph("chevron-down", 14.0, Kit.color(&"tx3")))
	get_popup().id_pressed.connect(_on_id_pressed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		_fit()


## Button sizes itself in native code, so the width is set here: at least `min_width`,
## wider when the value needs it.
func _fit() -> void:
	if not is_inside_tree():
		return
	var needed := PADDING_LEFT + PADDING_RIGHT + GAP * (_content.get_child_count() - 1)
	for child: Control in _content.get_children():
		var label := child as Label
		if label == null:
			needed += child.custom_minimum_size.x
		else:
			needed += label.get_theme_font(&"font").get_string_size(label.text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size(&"font_size")).x
	custom_minimum_size.x = maxf(min_width, ceilf(needed))


## Each entry becomes a radio item whose id is its index.
func set_items(captions: PackedStringArray, selected: int) -> void:
	var menu := get_popup()
	menu.clear()
	for index in range(captions.size()):
		menu.add_radio_check_item(captions[index], index)
		menu.set_item_checked(index, index == selected)
	set_value(captions[selected] if selected >= 0 and selected < captions.size() else "")


## Radio items show the choice; other items are plain commands.
func _on_id_pressed(id: int) -> void:
	var menu := get_popup()
	var chosen_index := menu.get_item_index(id)
	if menu.is_item_radio_checkable(chosen_index):
		for index in range(menu.item_count):
			if menu.is_item_radio_checkable(index):
				menu.set_item_checked(index, index == chosen_index)
		set_value(menu.get_item_text(chosen_index))
	chosen.emit(id)


func selected_text() -> String:
	var menu := get_popup()
	for index in range(menu.item_count):
		if menu.is_item_radio_checkable(index) and menu.is_item_checked(index):
			return menu.get_item_text(index)
	return ""


func set_value(value: String) -> void:
	value_label.text = value
	_fit()
