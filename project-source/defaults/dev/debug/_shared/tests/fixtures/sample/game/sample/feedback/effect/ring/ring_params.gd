extends Resource
## Parameters of the game's ring effect.

@export_range(1, 60, 1) var frame_count: int = 12:
	set(value):
		frame_count = value
		emit_changed()
@export_range(1, 60, 0.5, "suffix:fps") var fps: float = 24.0:
	set(value):
		fps = value
		emit_changed()
@export_range(10, 400, 1, "or_greater", "suffix:px") var size: float = 100.0:
	set(value):
		size = value
		emit_changed()
