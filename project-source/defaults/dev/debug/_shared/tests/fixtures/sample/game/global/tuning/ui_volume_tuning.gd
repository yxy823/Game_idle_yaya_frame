extends Resource
## Sample global tuning resource, listed with every target.

@export_range(-60, 6, 0.5, "suffix:dB") var volume_db: float = 0.0:
	set(value):
		volume_db = value
		emit_changed()
