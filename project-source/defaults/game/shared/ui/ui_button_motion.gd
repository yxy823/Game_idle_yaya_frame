class_name UiButtonMotion
extends Resource
## Motion tokens of GameButton: hover and press scales, and the tween that reaches them.

@export_range(0.5, 1.5, 0.01) var hover_scale: float = 1.05:
	set(value):
		hover_scale = value
		emit_changed()
@export_range(0.5, 1.5, 0.01) var press_scale: float = 0.95:
	set(value):
		press_scale = value
		emit_changed()
@export_range(0.0, 1.0, 0.01, "suffix:s") var duration: float = 0.12:
	set(value):
		duration = value
		emit_changed()
@export var transition: Tween.TransitionType = Tween.TRANS_QUAD:
	set(value):
		transition = value
		emit_changed()
@export var easing: Tween.EaseType = Tween.EASE_OUT:
	set(value):
		easing = value
		emit_changed()
