extends RefCounted

## Neutral development UI only. Never assign this palette to asset modulation.


static func background(dark: bool) -> Color:
	return Color("242424") if dark else Color.WHITE


static func create(dark: bool) -> Theme:
	var result := Theme.new()
	var ink := Color.WHITE if dark else Color.BLACK
	var surface := Color("333333") if dark else Color("f3f3f3")
	var active := Color("555555") if dark else Color("d8d8d8")
	var border := Color("888888")
	_apply_text_colors(result, ink)
	for type_name: String in ["Button", "OptionButton", "CheckButton"]:
		result.set_stylebox("normal", type_name, _box(surface, border))
		result.set_stylebox("disabled", type_name, _box(surface, border))
		for state: String in ["hover", "pressed", "hover_pressed"]:
			result.set_stylebox(state, type_name, _box(active, ink))
		var focus := _box(Color.TRANSPARENT, ink)
		focus.draw_center = false
		result.set_stylebox("focus", type_name, focus)
		for key: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			result.set_color(key, type_name, ink)
	result.set_constant("modulate_arrow", "OptionButton", 1)
	result.set_color("caret_color", "LineEdit", ink)
	result.set_color("font_placeholder_color", "LineEdit", Color(ink, 0.6))
	result.set_color("selection_color", "LineEdit", active)
	result.set_stylebox("normal", "LineEdit", _box(surface, border))
	result.set_stylebox("focus", "LineEdit", _box(Color.TRANSPARENT, ink, false))
	result.set_stylebox("panel", "ItemList", _box(surface, border))
	_apply_tree(result, surface, border, ink)
	result.set_stylebox("selected", "ItemList", _box(active, ink))
	result.set_stylebox("selected_focus", "ItemList", _box(active, ink))
	result.set_stylebox("panel", "PopupMenu", _box(surface, border))
	result.set_stylebox("hover", "PopupMenu", _box(active, ink))
	result.set_color("title_color", "Window", ink)
	result.set_stylebox("panel", "AcceptDialog", _box(surface, border))
	for direction: String in ["up", "down"]:
		for state: String in ["", "hover_", "pressed_", "disabled_"]:
			result.set_color(direction + "_" + state + "icon_modulate", "SpinBox", ink)
	return result


static func _apply_text_colors(result: Theme, ink: Color) -> void:
	for type_name: String in ["Label", "Button", "OptionButton", "CheckButton",
			"LineEdit", "ItemList", "PopupMenu", "Window", "Tree"]:
		for key: String in ["font_color", "font_hover_color", "font_pressed_color",
				"font_focus_color", "font_hover_pressed_color", "font_selected_color"]:
			result.set_color(key, type_name, ink)
		result.set_color("font_disabled_color", type_name, Color(ink, 0.5))
		result.set_color("font_outline_color", type_name, Color.TRANSPARENT)


static func _apply_tree(result: Theme, surface: Color, border: Color, ink: Color) -> void:
	result.set_stylebox("panel", "Tree", _box(surface, border))
	result.set_color("title_button_color", "Tree", ink)
	for key: String in ["font_hovered_color", "font_hovered_dimmed_color",
			"font_hovered_selected_color"]:
		result.set_color(key, "Tree", ink)
	for state: String in ["normal", "hover", "pressed"]:
		result.set_stylebox("title_button_" + state, "Tree", _box(surface, border))


static func _box(fill: Color, border: Color, draw_center: bool = true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	box.draw_center = draw_center
	return box
