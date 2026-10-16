class_name GameButton
extends Button
## Button that scales on hover and press. Scales, duration and easing come from the shared motion
## tokens and are read on every change, so the debug console's edits apply to the next tween.

const MOTION := preload("res://game/shared/tuning/ui/motion/button.tres")

var motion: UiButtonMotion = MOTION
var _tween: Tween


func _ready() -> void:
	pivot_offset_ratio = Vector2(0.5, 0.5)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_scale_to.bind(1.0))
	button_down.connect(func() -> void: _scale_to(motion.press_scale))
	button_up.connect(func() -> void: _scale_to(motion.hover_scale if is_hovered() else 1.0))


func _on_mouse_entered() -> void:
	if not disabled:
		_scale_to(motion.hover_scale)


func _scale_to(target: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(motion.transition).set_ease(motion.easing)
	_tween.tween_property(self, "scale", Vector2.ONE * target, motion.duration)
