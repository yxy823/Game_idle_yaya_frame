class_name UiThemeBuilder
extends RefCounted
## Builds the game's Theme from the UI tokens. A Theme cannot reference variables, so every
## semantic token is resolved to its primitive value here; rebuild after any token changes.

var palette: UiPalette
var font_sizes: UiFontSizes
var spacing: UiSpacing
var radii: UiRadii
var border_widths: UiBorderWidths
var shadows: UiShadows
var text: UiTextStyle
var panel: UiPanelStyle
var button_primary: UiButtonStyle
var button_secondary: UiButtonStyle
var button_danger: UiButtonStyle
var line_edit: UiLineEditStyle
var progress_bar: UiProgressBarStyle


## Every token resource the theme reads; a change in any of them needs a rebuild.
func tokens() -> Array[Resource]:
	return [palette, font_sizes, spacing, radii, border_widths, shadows, text, panel,
		button_primary, button_secondary, button_danger, line_edit, progress_bar]


func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = font_sizes.size(text.font_size)
	theme.set_color(&"font_color", &"Label", palette.color(text.font_color))
	theme.set_font_size(&"font_size", &"Label", font_sizes.size(text.font_size))
	var panel_box := _panel_box()
	theme.set_stylebox(&"panel", &"Panel", panel_box)
	theme.set_stylebox(&"panel", &"PanelContainer", panel_box)
	# Unstyled buttons look like the secondary variation.
	_add_button(theme, &"Button", button_secondary)
	var variations: Dictionary[StringName, UiButtonStyle] = {&"ButtonPrimary": button_primary,
		&"ButtonSecondary": button_secondary, &"ButtonDanger": button_danger}
	for variation: StringName in variations:
		theme.set_type_variation(variation, &"Button")
		_add_button(theme, variation, variations[variation])
	_add_line_edit(theme)
	_add_progress_bar(theme)
	return theme


func _panel_box() -> StyleBoxFlat:
	var box := _box(panel.background, panel.border_color, panel.border_width, panel.radius)
	box.set_content_margin_all(spacing.size(panel.padding))
	shadows.apply(panel.shadow, palette.color(panel.shadow_color), box)
	return box


func _add_button(theme: Theme, type: StringName, style: UiButtonStyle) -> void:
	var states := {
		&"normal": style.background, &"hover": style.background_hover,
		&"pressed": style.background_pressed, &"hover_pressed": style.background_pressed,
		&"disabled": style.background_disabled,
	}
	for state: StringName in states:
		var box := _box(states[state], style.border_color, style.border_width, style.radius)
		box.content_margin_left = spacing.size(style.padding_horizontal)
		box.content_margin_right = box.content_margin_left
		box.content_margin_top = spacing.size(style.padding_vertical)
		box.content_margin_bottom = box.content_margin_top
		theme.set_stylebox(state, type, box)
	var focus := _box(style.background, style.focus_color, style.focus_border_width, style.radius)
	focus.draw_center = false
	theme.set_stylebox(&"focus", type, focus)
	var font_color := palette.color(style.font_color)
	for item: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color"]:
		theme.set_color(item, type, font_color)
	theme.set_color(&"font_disabled_color", type, palette.color(style.font_disabled_color))
	theme.set_font_size(&"font_size", type, font_sizes.size(style.font_size))


func _add_line_edit(theme: Theme) -> void:
	var normal := _box(line_edit.background, line_edit.border_color, line_edit.border_width,
		line_edit.radius)
	normal.set_content_margin_all(spacing.size(line_edit.padding))
	var focus := _box(line_edit.background, line_edit.focus_border_color, line_edit.border_width,
		line_edit.radius)
	focus.draw_center = false
	theme.set_stylebox(&"normal", &"LineEdit", normal)
	theme.set_stylebox(&"read_only", &"LineEdit", normal)
	theme.set_stylebox(&"focus", &"LineEdit", focus)
	theme.set_color(&"font_color", &"LineEdit", palette.color(line_edit.font_color))
	theme.set_color(&"caret_color", &"LineEdit", palette.color(line_edit.font_color))
	theme.set_color(&"font_placeholder_color", &"LineEdit",
		palette.color(line_edit.placeholder_color))
	theme.set_font_size(&"font_size", &"LineEdit", font_sizes.size(line_edit.font_size))


func _add_progress_bar(theme: Theme) -> void:
	var none := UiBorderWidths.Step.NONE
	theme.set_stylebox(&"background", &"ProgressBar",
		_box(progress_bar.track, progress_bar.track, none, progress_bar.radius))
	theme.set_stylebox(&"fill", &"ProgressBar",
		_box(progress_bar.fill, progress_bar.fill, none, progress_bar.radius))
	theme.set_color(&"font_color", &"ProgressBar", palette.color(progress_bar.font_color))
	theme.set_font_size(&"font_size", &"ProgressBar", font_sizes.size(progress_bar.font_size))


func _box(background: UiPalette.Swatch, border: UiPalette.Swatch,
		border_width: UiBorderWidths.Step, radius: UiRadii.Step) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = palette.color(background)
	box.border_color = palette.color(border)
	box.set_border_width_all(border_widths.size(border_width))
	box.set_corner_radius_all(radii.size(radius))
	return box
