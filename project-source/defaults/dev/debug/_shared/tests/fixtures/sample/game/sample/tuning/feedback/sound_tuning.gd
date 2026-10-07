extends Resource
## Sample tuning resource: the sound a button plays, an AudioStream candidate.

enum PitchMode { FIXED, RISING }

@export var candidate: AudioStream:
	set(value):
		candidate = value
		emit_changed()
@export var candidate_params: Resource:
	set(value):
		if candidate_params != null:
			candidate_params.changed.disconnect(emit_changed)
		candidate_params = value
		if candidate_params != null:
			candidate_params.changed.connect(emit_changed)
		emit_changed()
@export_range(-60, 6, 0.5, "or_greater", "or_less", "suffix:dB") var volume_db: float = -6.0:
	set(value):
		volume_db = value
		emit_changed()
@export var pitch_mode: PitchMode = PitchMode.FIXED:
	set(value):
		pitch_mode = value
		emit_changed()
