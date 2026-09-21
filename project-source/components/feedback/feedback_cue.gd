class_name FeedbackCue
extends Resource

## Small icon-pulse cue shared by the example game and its authoring workbench.
## Referenced assets stay unmodified; trials replace references or change scalar values.

# Min, max, UI step. Scalar floats retain the same precision as serialized fields.
const SCALE_LIMITS: Array[float] = [0.5, 2.0, 0.05]
const DURATION_LIMITS: Array[float] = [0.15, 1.5, 0.05]
const GAIN_LIMITS: Array[float] = [-48.0, 0.0, 1.0]
const PITCH_LIMITS: Array[float] = [0.5, 2.0, 0.05]
const DELAY_LIMITS: Array[float] = [0.0, 0.6, 0.01]

@export var texture: Texture2D
@export var sound: AudioStream
@export_range(0.5, 2.0, 0.05) var icon_scale: float = 1.0
@export_range(0.15, 1.5, 0.05) var animation_seconds: float = 0.5
@export_range(-48.0, 0.0, 1.0) var gain_db: float = -12.0
@export_range(0.5, 2.0, 0.05) var pitch_scale: float = 1.0
@export_range(0.0, 0.6, 0.01) var delay_seconds: float = 0.08
@export var bus: StringName = &"Master"


func trial_copy() -> FeedbackCue:
	# Deliberately share immutable Texture/AudioStream assets, never edit their properties.
	return duplicate(false) as FeedbackCue


func same_values(other: FeedbackCue) -> bool:
	if other == null:
		return false
	return (
		texture == other.texture and sound == other.sound
		and icon_scale == other.icon_scale and animation_seconds == other.animation_seconds
		and gain_db == other.gain_db and pitch_scale == other.pitch_scale
		and delay_seconds == other.delay_seconds and bus == other.bus
	)


func validation_error() -> String:
	if texture == null or sound == null:
		return "Choose an imported texture and an audio stream."
	if texture.resource_path.is_empty() or sound.resource_path.is_empty():
		return "Candidates must be saved project resources."
	if AudioServer.get_bus_index(bus) < 0:
		return "Audio bus does not exist: %s" % bus
	return _parameter_error()


func _parameter_error() -> String:
	if not _in_range(icon_scale, SCALE_LIMITS):
		return "Icon scale must be between 0.5 and 2.0."
	if not _in_range(animation_seconds, DURATION_LIMITS):
		return "Animation duration must be between 0.15 and 1.5 seconds."
	if not _in_range(gain_db, GAIN_LIMITS) or not _in_range(pitch_scale, PITCH_LIMITS):
		return "Gain or playback pitch is outside the supported range."
	if not _in_range(delay_seconds, DELAY_LIMITS):
		return "Audio delay must be between 0.0 and 0.6 seconds."
	return ""


func _in_range(value: float, limits: Array[float]) -> bool:
	return is_finite(value) and value >= limits[0] and value <= limits[1]
