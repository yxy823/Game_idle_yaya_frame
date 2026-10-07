extends MarginContainer
## One parameter in four columns: label, control, value box, row tools. A modified row shows
## an amber bar on the left, an amber label and a revert button.

signal revert_requested(path: String)

const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const LABEL_WIDTH := 96.0
const ROW_HEIGHT := 30.0
const TALL_PADDING := 6
const BAR_WIDTH := 2.0
const BAR_INSET := 7.0

var path: String = ""
var caption: Label
var tools: VBoxContainer
var revert: Button
var modified: bool = false


func _init(field_path: String, text: String, control: Control, tall: bool) -> void:
	path = field_path
	name = field_path.validate_node_name()
	custom_minimum_size.y = ROW_HEIGHT
	add_theme_constant_override("margin_left", 8)
	if tall:
		add_theme_constant_override("margin_top", TALL_PADDING)
		add_theme_constant_override("margin_bottom", TALL_PADDING)
	var line := Kit.row(12)
	line.name = "Line"
	add_child(line)
	caption = Kit.elided(text, &"FieldLabel")
	caption.size_flags_horizontal = Control.SIZE_FILL
	caption.custom_minimum_size = Vector2(LABEL_WIDTH, Kit.INLINE)
	caption.tooltip_text = field_path.get_file()
	caption.mouse_filter = Control.MOUSE_FILTER_PASS
	if tall:
		caption.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line.add_child(caption)
	line.add_child(control)
	tools = Kit.column(4)
	tools.custom_minimum_size.x = Kit.INLINE
	tools.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if tall else Control.SIZE_SHRINK_CENTER
	line.add_child(tools)
	revert = Kit.inline_button("arrow-back-up", "还原这一项")
	revert.visible = false
	revert.pressed.connect(func() -> void: revert_requested.emit(path))
	tools.add_child(revert)


func set_modified(value: bool, tooltip: String) -> void:
	modified = value
	caption.theme_type_variation = &"FieldLabelModified" if value else &"FieldLabel"
	revert.visible = value
	revert.tooltip_text = tooltip
	queue_redraw()


func _draw() -> void:
	if modified:
		draw_rect(Rect2(0.0, BAR_INSET, BAR_WIDTH, size.y - BAR_INSET * 2.0), Kit.color(&"warn"))
