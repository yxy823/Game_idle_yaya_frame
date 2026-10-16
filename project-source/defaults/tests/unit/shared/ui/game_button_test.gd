extends GdUnitTestSuite
## GameButton reads the motion tokens each time it starts a tween.

const MOTION := preload("res://game/shared/tuning/ui/motion/button.tres")

var motion: UiButtonMotion = MOTION
var _duration: float
var _transition: Tween.TransitionType


func before_test() -> void:
	_duration = motion.duration
	_transition = motion.transition


func after_test() -> void:
	motion.duration = _duration
	motion.transition = _transition


func test_new_tween_uses_the_changed_duration() -> void:
	var button := auto_free(GameButton.new()) as GameButton
	add_child(button)
	motion.transition = Tween.TRANS_LINEAR
	motion.duration = 1.0
	button.mouse_entered.emit()
	var hover := _latest_tween()
	hover.custom_step(0.5)
	assert_float(button.scale.x).is_equal_approx(lerpf(1.0, motion.hover_scale, 0.5), 0.001)
	motion.duration = 0.2
	var start := button.scale.x
	button.mouse_exited.emit()
	var leave := _latest_tween()
	leave.custom_step(0.1)
	assert_float(button.scale.x).is_equal_approx(lerpf(start, 1.0, 0.5), 0.001)
	leave.custom_step(0.1)
	assert_float(button.scale.x).is_equal(1.0)


## Paused in the frame it was created, so only custom_step advances it.
func _latest_tween() -> Tween:
	var tweens := get_tree().get_processed_tweens().filter(func(item: Tween) -> bool:
		return item.is_valid())
	var tween: Tween = tweens.back()
	tween.pause()
	return tween
