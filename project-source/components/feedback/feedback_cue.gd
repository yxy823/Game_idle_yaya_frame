class_name FeedbackCue
extends Resource

## Optional image, audio and shader bindings shared by the game and its workbench.
## Referenced assets stay unmodified; trials replace references or change scalar values.

# Min, max, UI step. Scalar floats retain the same precision as serialized fields.
const SCALE_LIMITS: Array[float] = [0.5, 2.0, 0.05]
const DURATION_LIMITS: Array[float] = [0.15, 1.5, 0.05]
const GAIN_LIMITS: Array[float] = [-48.0, 0.0, 1.0]
const PITCH_LIMITS: Array[float] = [0.5, 2.0, 0.05]
const DELAY_LIMITS: Array[float] = [0.0, 0.6, 0.01]
const STRENGTH_LIMITS: Array[float] = [0.0, 1.0, 0.05]

@export var texture: Texture2D
@export var sound: AudioStream
@export var shader_preset: FeedbackShaderPreset
@export_range(0.5, 2.0, 0.05) var icon_scale: float = 1.0
@export_range(0.15, 1.5, 0.05) var animation_seconds: float = 0.5
@export_range(-48.0, 0.0, 1.0) var gain_db: float = -12.0
@export_range(0.5, 2.0, 0.05) var pitch_scale: float = 1.0
@export_range(0.0, 0.6, 0.01) var delay_seconds: float = 0.08
@export var bus: StringName = &"Master"
@export_range(0.0, 1.0, 0.05) var shader_strength: float = 0.7
@export var shader_color: Color = Color(1.0, 0.4, 0.1, 1.0)
@export_range(0.0, 0.6, 0.01) var shader_delay_seconds: float = 0.0
@export_range(0.15, 1.5, 0.05) var shader_duration_seconds: float = 0.8


func trial_copy() -> FeedbackCue:
	# Asset and preset definitions are shared read-only; mutable uniforms live in the presenter.
	return duplicate(false) as FeedbackCue


func same_values(other: FeedbackCue) -> bool:
	if other == null:
		return false
	return (
		texture == other.texture and sound == other.sound
		and icon_scale == other.icon_scale and animation_seconds == other.animation_seconds
		and gain_db == other.gain_db and pitch_scale == other.pitch_scale
		and delay_seconds == other.delay_seconds and bus == other.bus
		and _same_shader_values(other)
	)


func validation_error() -> String:
	for asset: Resource in [texture, sound, shader_preset]:
		if asset != null and asset.resource_path.is_empty():
			return "Candidates must be saved project resources."
	if sound != null and AudioServer.get_bus_index(bus) < 0:
		return "Audio bus does not exist: %s" % bus
	var issue := _parameter_error()
	return issue if not issue.is_empty() else _shader_error()


func _same_shader_values(other: FeedbackCue) -> bool:
	return (shader_preset == other.shader_preset and shader_strength == other.shader_strength
		and shader_color == other.shader_color and shader_delay_seconds == other.shader_delay_seconds
		and shader_duration_seconds == other.shader_duration_seconds)


func _shader_error() -> String:
	if shader_preset == null:
		return ""
	var issue := shader_preset.validation_error()
	if not issue.is_empty():
		return issue
	if not _in_range(shader_strength, STRENGTH_LIMITS):
		return "Shader strength must be between 0.0 and 1.0."
	if not _in_range(shader_delay_seconds, DELAY_LIMITS):
		return "Shader delay must be between 0.0 and 0.6 seconds."
	if not _in_range(shader_duration_seconds, DURATION_LIMITS):
		return "Shader duration must be between 0.15 and 1.5 seconds."
	for channel: float in [shader_color.r, shader_color.g, shader_color.b, shader_color.a]:
		if not is_finite(channel):
			return "Shader color must be finite."
	return ""


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
