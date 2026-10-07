extends RefCounted
## Builds the debug window's recurring controls; colors and sizes come from debug_theme.tres.

const ICONS := "res://dev/debug/_shared/icons/"
const CONTROL := 28.0
const INLINE := 22.0
const CHIP := 22.0
const DOT := 6.0
const PALETTE := &"DebugPalette"
const THEME := preload("res://dev/debug/_shared/debug_theme.tres")
## Chip tone -> [panel variation, text variation, glyph color].
const CHIP_TONES := {
	&"": [&"Chip", &"ChipText", &"tx2"],
	&"warn": [&"ChipWarn", &"ChipWarnText", &"warn"],
	&"accent": [&"ChipAccent", &"ChipAccentText", &"accent"],
}


## Palette colors for drawing code; the theme is the only place they are defined.
static func color(color_name: StringName) -> Color:
	return THEME.get_color(color_name, PALETTE)


static func icon(icon_name: String) -> Texture2D:
	return load(ICONS + icon_name + ".svg") as Texture2D


## Icon-only actions keep their name and consequence in the tooltip.
static func icon_button(icon_name: String, tooltip: String, variation: StringName = &"IconButton",
		side: float = CONTROL) -> Button:
	var button := Button.new()
	button.icon = icon(icon_name)
	button.tooltip_text = tooltip
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(side, side)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button


static func inline_button(icon_name: String, tooltip: String) -> Button:
	return icon_button(icon_name, tooltip, &"IconButtonSmall", INLINE)


static func text_button(caption: String, icon_name: String, tooltip: String,
		variation: StringName = &"") -> Button:
	var button := Button.new()
	button.text = caption
	if not icon_name.is_empty():
		button.icon = icon(icon_name)
	button.tooltip_text = tooltip
	button.theme_type_variation = variation
	button.custom_minimum_size.y = CONTROL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button


static func label(text: String, variation: StringName = &"") -> Label:
	var result := Label.new()
	result.text = text
	result.theme_type_variation = variation
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return result


static func elided(text: String, variation: StringName = &"") -> Label:
	var result := label(text, variation)
	result.clip_text = true
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


static func glyph(icon_name: String, side: float, tint: Color) -> TextureRect:
	var image := TextureRect.new()
	image.texture = icon(icon_name)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(side, side)
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image.modulate = tint
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


static func row(separation: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func column(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func spacer() -> Control:
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return space


static func panel(variation: StringName, child: Control = null) -> PanelContainer:
	var box := PanelContainer.new()
	box.theme_type_variation = variation
	if child != null:
		box.add_child(child)
	return box


## A rounded status tag; set its text with chip_text(). Tones: &"" neutral gray, &"warn" for
## unsaved or modified, &"accent" outlined for what is about to take effect.
static func chip(text: String, icon_name: String, tone: StringName = &"") -> PanelContainer:
	var content := row(4)
	content.name = "Row"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: Array = CHIP_TONES[tone]
	var box := panel(style[0], content)
	box.custom_minimum_size.y = CHIP
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if icon_name == "dot":
		content.add_child(dot())
	elif not icon_name.is_empty():
		content.add_child(glyph(icon_name, 13.0, color(style[2])))
	var caption := label(text, style[1])
	caption.name = "Text"
	content.add_child(caption)
	return box


static func chip_text(box: PanelContainer, text: String) -> void:
	(box.get_node("Row/Text") as Label).text = text


static func dot() -> Panel:
	var mark := Panel.new()
	mark.theme_type_variation = &"Dot"
	mark.custom_minimum_size = Vector2(DOT, DOT)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_PASS
	return mark


static func kbd(text: String) -> PanelContainer:
	var caption := label(text, &"KbdText")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var box := panel(&"Kbd", caption)
	box.custom_minimum_size = Vector2(18, 18)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return box


## A titled block of the inspector; its first child is the header that holds the title and
## right-aligned tools.
static func section(title: String) -> VBoxContainer:
	var block := column(0)
	block.name = "Section"
	block.add_child(section_header(title))
	return block


static func section_header(title: String) -> HBoxContainer:
	var header := row(4)
	header.name = "Header"
	header.custom_minimum_size.y = CONTROL
	header.add_child(label(title, &"SectionLabel"))
	header.add_child(spacer())
	return header


static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


## Stacks inspector sections: 8 px gap and a divider before every section but the first,
## then 12 px above the section title.
static func section_frame(block: Control, first: bool) -> VBoxContainer:
	var frame := column(0)
	if not first:
		var gap := Control.new()
		gap.custom_minimum_size.y = 8.0
		frame.add_child(gap)
		frame.add_child(HSeparator.new())
	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_top", 12)
	top.add_child(block)
	frame.add_child(top)
	return frame


## The candidate radio: a ring that turns into a thick accent ring when selected.
class Radio extends Control:
	const SIDE := 14.0
	var on: bool = false:
		set(value):
			on = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(SIDE, SIDE)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var ring := THEME.get_color(&"accent" if on else &"tx3", PALETTE)
		var width := 4.0 if on else 1.5
		draw_arc(size * 0.5, (SIDE - width) * 0.5, 0.0, TAU, 32, ring, width, true)
