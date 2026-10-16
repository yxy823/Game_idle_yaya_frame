class_name UiTextStyle
extends Resource
## Semantic tokens of plain text: Label and the theme's default font size.

@export var font_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_900:
	set(value):
		font_color = value
		emit_changed()
@export var font_size: UiFontSizes.Step = UiFontSizes.Step.SM:
	set(value):
		font_size = value
		emit_changed()
