class_name UiProgressBarStyle
extends Resource
## Semantic tokens of ProgressBar.

@export var track: UiPalette.Swatch = UiPalette.Swatch.GRAY_200:
	set(value):
		track = value
		emit_changed()
@export var fill: UiPalette.Swatch = UiPalette.Swatch.ACCENT_500:
	set(value):
		fill = value
		emit_changed()
@export var font_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_900:
	set(value):
		font_color = value
		emit_changed()
@export var radius: UiRadii.Step = UiRadii.Step.SM:
	set(value):
		radius = value
		emit_changed()
@export var font_size: UiFontSizes.Step = UiFontSizes.Step.XS:
	set(value):
		font_size = value
		emit_changed()
