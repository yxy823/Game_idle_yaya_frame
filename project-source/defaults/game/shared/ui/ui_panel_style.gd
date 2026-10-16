class_name UiPanelStyle
extends Resource
## Semantic tokens of Panel and PanelContainer.

@export var background: UiPalette.Swatch = UiPalette.Swatch.GRAY_50:
	set(value):
		background = value
		emit_changed()
@export var border_color: UiPalette.Swatch = UiPalette.Swatch.GRAY_200:
	set(value):
		border_color = value
		emit_changed()
@export var border_width: UiBorderWidths.Step = UiBorderWidths.Step.THIN:
	set(value):
		border_width = value
		emit_changed()
@export var radius: UiRadii.Step = UiRadii.Step.MD:
	set(value):
		radius = value
		emit_changed()
@export var padding: UiSpacing.Step = UiSpacing.Step.LG:
	set(value):
		padding = value
		emit_changed()
@export var shadow: UiShadows.Level = UiShadows.Level.MD:
	set(value):
		shadow = value
		emit_changed()
@export var shadow_color: UiPalette.Swatch = UiPalette.Swatch.SHADOW:
	set(value):
		shadow_color = value
		emit_changed()
