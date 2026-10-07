extends Resource
## Parameters of the spark candidate.

@export_range(1, 64, 1) var count: int = 8:
	set(value):
		count = value
		emit_changed()
@export_range(0, 800, 1, "or_greater", "suffix:px/s") var speed: float = 240.0:
	set(value):
		speed = value
		emit_changed()
