class_name UiButtonStyle
extends Resource
## Semantic tokens of one button style; primary, secondary and danger each have a file.

@export var background: UiPalette.Swatch = UiPalette.Swatch.GRAY_100:
	set(value):
		background = value
		emit_changed()
@export var background_hover: UiPalette.Swatch = UiPalette.Swatch.GRAY_200:
	set(value):
		background_hover = value
		emit_changed()
@export var background_pressed: UiPalette.Swatch = UiPalette.Swatch.GRAY_300:
	set(value):
		background_pressed = value
		emit_changed()
@export var background_disabled: UiPalette.Swatch = UiPalette.Swatch.GRAY_100:
	set(value):
		background_disabled = value
		emit_changed()
@export var font_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_900:
	set(value):
		font_color = value
		emit_changed()
@export var font_disabled_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_400:
	set(value):
		font_disabled_color = value
		emit_changed()
@export var border_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_300:
	set(value):
		border_color = value
		emit_changed()
@export var border_width: UiBorderWidths.Step = UiBorderWidths.Step.THIN:
	set(value):
		border_width = value
		emit_changed()
@export var focus_color: UiPalette.Swatch = UiPalette.Swatch.ACCENT_400:
	set(value):
		focus_color = value
		emit_changed()
@export var focus_border_width: UiBorderWidths.Step = UiBorderWidths.Step.THICK:
	set(value):
		focus_border_width = value
		emit_changed()
@export var radius: UiRadii.Step = UiRadii.Step.MD:
	set(value):
		radius = value
		emit_changed()
@export var padding_horizontal: UiSpacing.Step = UiSpacing.Step.LG:
	set(value):
		padding_horizontal = value
		emit_changed()
@export var padding_vertical: UiSpacing.Step = UiSpacing.Step.SM:
	set(value):
		padding_vertical = value
		emit_changed()
@export var font_size: UiFontSizes.Step = UiFontSizes.Step.SM:
	set(value):
		font_size = value
		emit_changed()
