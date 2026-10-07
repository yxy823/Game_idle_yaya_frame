extends Resource
## Sample tuning resource without candidates: plain numbers and a curve.

@export_range(0.05, 2, 0.01, "or_greater", "suffix:s") var hold: float = 0.3:
	set(value):
		hold = value
		emit_changed()
@export var motion_curve: Curve:
	set(value):
		if motion_curve != null:
			motion_curve.changed.disconnect(emit_changed)
		motion_curve = value
		if motion_curve != null:
			motion_curve.changed.connect(emit_changed)
		emit_changed()
