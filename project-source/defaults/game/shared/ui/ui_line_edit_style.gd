class_name UiLineEditStyle
extends Resource
## Semantic tokens of LineEdit.

@export var background: UiPalette.Swatch = UiPalette.Swatch.GRAY_50:
	set(value):
		background = value
		emit_changed()
@export var font_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_900:
	set(value):
		font_color = value
		emit_changed()
@export var placeholder_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_500:
	set(value):
		placeholder_color = value
		emit_changed()
@export var border_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_300:
	set(value):
		border_color = value
		emit_changed()
@export var focus_border_color: UiPalette.Swatch = UiPalette.Swatch.ACCENT_500:
	set(value):
		focus_border_color = value
		emit_changed()
@export var border_width: UiBorderWidths.Step = UiBorderWidths.Step.THIN:
	set(value):
		border_width = value
		emit_changed()
@export var radius: UiRadii.Step = UiRadii.Step.SM:
	set(value):
		radius = value
		emit_changed()
@export var padding: UiSpacing.Step = UiSpacing.Step.SM:
	set(value):
		padding = value
		emit_changed()
@export var font_size: UiFontSizes.Step = UiFontSizes.Step.SM:
	set(value):
		font_size = value
		emit_changed()
