class_name FeedbackCue
extends Resource

## Optional media, particle and motion bindings shared by the game and its workbench.
## Referenced assets stay unmodified; trials replace references or change scalar values.

# Min, max, UI step. Scalar floats retain the same precision as serialized fields.
const SCALE_LIMITS: Array[float] = [0.5, 2.0, 0.05]
const DURATION_LIMITS: Array[float] = [0.15, 1.5, 0.05]
const GAIN_LIMITS: Array[float] = [-48.0, 0.0, 1.0]
const PITCH_LIMITS: Array[float] = [0.5, 2.0, 0.05]
const DELAY_LIMITS: Array[float] = [0.0, 0.6, 0.01]
const STRENGTH_LIMITS: Array[float] = [0.0, 1.0, 0.05]
const PARTICLE_SCALE_LIMITS: Array[float] = [0.25, 2.0, 0.05]
const EMISSION_LIMITS: Array[float] = [0.15, 5.0, 0.05]
const MOTION_TIME_LIMITS: Array[float] = [0.15, 3.0, 0.05]
const MOTION_DISTANCE_LIMITS: Array[float] = [0.0, 80.0, 1.0]
const ANIMATION_SPEED_LIMITS: Array[float] = [0.5, 2.0, 0.05]

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
@export var particle_preset: FeedbackParticlePreset
@export_range(0.25, 2.0, 0.05) var particle_scale: float = 1.0
@export_range(0.0, 0.6, 0.01) var particle_delay_seconds: float = 0.0
@export_range(0.15, 5.0, 0.05) var particle_emission_seconds: float = 1.5
@export var tween_enabled: bool = false
@export_range(0.0, 80.0, 1.0) var tween_distance: float = 24.0
@export_range(0.15, 3.0, 0.05) var tween_seconds: float = 0.7
@export var animation_clip: Animation
@export_range(0.5, 2.0, 0.05) var animation_speed: float = 1.0


func trial_copy() -> FeedbackCue:
	# Asset and preset definitions are shared read-only; mutable uniforms live in the presenter.
	return duplicate(false) as FeedbackCue


func same_values(other: FeedbackCue) -> bool:
	if other == null:
		return false
	return (
		texture == other.texture
		and icon_scale == other.icon_scale and animation_seconds == other.animation_seconds
		and _same_audio_values(other)
		and _same_shader_values(other)
		and _same_effect_values(other)
	)


func validation_error() -> String:
	for asset: Resource in [texture, sound, shader_preset, particle_preset, animation_clip]:
		if asset != null and asset.resource_path.is_empty():
			return "Candidates must be saved project resources."
	if sound != null and AudioServer.get_bus_index(bus) < 0:
		return "Audio bus does not exist: %s" % bus
	var issue := _parameter_error()
	if issue.is_empty():
		issue = _shader_error()
	if issue.is_empty():
		issue = _effect_error()
	return issue


func _same_effect_values(other: FeedbackCue) -> bool:
	return (particle_preset == other.particle_preset and particle_scale == other.particle_scale
		and particle_delay_seconds == other.particle_delay_seconds
		and particle_emission_seconds == other.particle_emission_seconds
		and tween_enabled == other.tween_enabled and tween_distance == other.tween_distance
		and tween_seconds == other.tween_seconds and animation_clip == other.animation_clip
		and animation_speed == other.animation_speed)


func _same_audio_values(other: FeedbackCue) -> bool:
	return (sound == other.sound and gain_db == other.gain_db and pitch_scale == other.pitch_scale
		and delay_seconds == other.delay_seconds and bus == other.bus)


func _effect_error() -> String:
	var issue := _particle_error()
	if not issue.is_empty():
		return issue
	if tween_enabled and (not _in_range(tween_seconds, MOTION_TIME_LIMITS)
			or not _in_range(tween_distance, MOTION_DISTANCE_LIMITS)):
		return "Tween duration or distance is outside the supported range."
	if animation_clip != null and not _in_range(animation_speed, ANIMATION_SPEED_LIMITS):
		return "Animation speed must be between 0.5 and 2.0."
	return _animation_error()


func _particle_error() -> String:
	if particle_preset != null:
		var issue := particle_preset.validation_error()
		if not issue.is_empty():
			return issue
		if not _in_range(particle_scale, PARTICLE_SCALE_LIMITS):
			return "Particle scale must be between 0.25 and 2.0."
		if not _in_range(particle_delay_seconds, DELAY_LIMITS):
			return "Particle delay must be between 0.0 and 0.6 seconds."
		if not _in_range(particle_emission_seconds, EMISSION_LIMITS):
			return "Particle emission duration must be between 0.15 and 5 seconds."
	return ""


func _animation_error() -> String:
	if animation_clip == null:
		return ""
	if animation_clip.loop_mode != Animation.LOOP_NONE or not is_finite(animation_clip.length):
		return "Animation clip must be finite and non-looping."
	if animation_clip.length <= 0.0 or animation_clip.length > 5.0:
		return "Animation clip length must be above zero and at most 5 seconds."
	if animation_clip.get_track_count() == 0:
		return "Animation clip requires at least one transform track."
	for track: int in animation_clip.get_track_count():
		var issue := _animation_track_error(track)
		if not issue.is_empty():
			return issue
	return ""


func _animation_track_error(track: int) -> String:
	var path := String(animation_clip.track_get_path(track))
	if animation_clip.track_get_type(track) != Animation.TYPE_VALUE or (
			path not in [".:position", ".:scale", ".:rotation"]):
		return "Animation supports only local position, scale and rotation value tracks."
	for key: int in animation_clip.track_get_key_count(track):
		var value: Variant = animation_clip.track_get_key_value(track, key)
		if not _valid_animation_value(path, value):
			return "Animation transform keys must contain finite values of the correct type."
	return ""


func _valid_animation_value(path: String, value: Variant) -> bool:
	if path == ".:rotation":
		return (value is float or value is int) and is_finite(float(value))
	return value is Vector2 and value.is_finite()


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
