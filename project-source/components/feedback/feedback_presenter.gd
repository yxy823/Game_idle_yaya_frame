extends Control

## Pure presentation: no inventory, rewards, saves, network calls, or global manager.

signal sound_started
signal playback_failed(message: String)

const AudioPlayback = preload("res://components/feedback/audio_playback.gd")
const Visual = preload("res://components/feedback/feedback_visual.gd")
const Particles = preload("res://components/feedback/feedback_particles.gd")
const Motion = preload("res://components/feedback/feedback_motion.gd")
const ICON_SIZE: float = 100.0
const RAY_COUNT: int = 12

var _cue: FeedbackCue
var _generation: int = 0
var _revision: int = 0
var _managed: bool = false
var _pending_audio: int = 0
var _pulses: Array[float] = []
var _audio: AudioPlayback = AudioPlayback.new()
var _visual: Visual = Visual.new()
var _particles: Particles = Particles.new()
var _motion: Motion = Motion.new()


func _init() -> void:
	# Own every constructed node even when this presenter is freed before entering the tree.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_audio)
	add_child(_motion)
	_motion.content.add_child(_visual)
	_motion.content.add_child(_particles)


func _process(delta: float) -> void:
	if _cue == null or _pulses.is_empty():
		return
	for index: int in range(_pulses.size() - 1, -1, -1):
		_pulses[index] += delta / _cue.animation_seconds
		if _pulses[index] >= 1.0:
			_pulses.remove_at(index)
	queue_redraw()


func _draw() -> void:
	if _cue == null:
		return
	var center := size * 0.5
	var pulse_scale := 1.0
	for progress: float in _pulses:
		pulse_scale = maxf(pulse_scale, 1.0 + sin(progress * PI) * 0.2)
		_draw_burst(center, progress)
	var extent := Vector2.ONE * ICON_SIZE * _cue.icon_scale * pulse_scale
	_motion.position = center
	_visual.position = -extent * 0.5
	_visual.size = extent


func _exit_tree() -> void:
	stop()


func configure(cue: FeedbackCue) -> void:
	stop()
	_cue = cue.trial_copy()
	_visual.configure(_cue)
	_particles.configure(_cue)
	_motion.configure(_cue)
	queue_redraw()


func trigger() -> void:
	# A manual trigger takes the whole target back; later managed cancellation cannot stop it.
	if _managed:
		stop()
	_start_playback(false)


## Managed playback is exclusive for this target; ordinary triggers still allow audio overlap.
## Returns this invocation's revision, even if a synchronous signal supersedes it, or 0 on failure.
func trigger_managed() -> int:
	stop()
	return _start_playback(true)


func playback_revision() -> int:
	return _revision


func playback_error() -> String:
	return "No Cue is configured." if _cue == null else _cue.validation_error()


func pending_audio_count() -> int:
	return _pending_audio


func is_playing() -> bool:
	return _pending_audio > 0 or active_voice_count() > 0 or active_effect_count() > 0


func stop() -> void:
	_generation += 1
	_revision += 1
	_managed = false
	_pending_audio = 0
	_pulses.clear()
	_audio.stop_all()
	_visual.stop()
	_particles.stop()
	_motion.stop()
	queue_redraw()


func active_effect_count() -> int:
	return (_pulses.size() + int(_visual.is_active())
		+ int(_particles.is_active()) + _motion.active_count())


func active_voice_count() -> int:
	return _audio.active_voice_count()


func _play_after_delay(cue: FeedbackCue, generation: int) -> void:
	_pending_audio += 1
	if cue.delay_seconds > 0.0:
		await get_tree().create_timer(cue.delay_seconds).timeout
	if generation != _generation or not is_inside_tree():
		return
	_pending_audio -= 1
	var error := _audio.play(cue.sound, cue.gain_db, cue.pitch_scale, cue.bus)
	if error == OK:
		sound_started.emit()
	else:
		playback_failed.emit("Audio playback failed: %s" % error_string(error))


func _start_playback(managed: bool) -> int:
	_revision += 1
	var revision := _revision
	var issue := playback_error()
	if not issue.is_empty():
		playback_failed.emit(issue)
		return 0
	_managed = managed
	if _cue.texture != null:
		_pulses.append(0.0)
	_visual.trigger()
	_particles.trigger()
	_motion.trigger()
	if _cue.sound != null:
		_play_after_delay(_cue.trial_copy(), _generation)
	queue_redraw()
	return revision


func _draw_burst(center: Vector2, progress: float) -> void:
	# The procedural effect has its own neutral color; it never recolors the asset.
	var color := Color(0.5, 0.5, 0.5)
	color.a *= 1.0 - progress
	var radius := (55.0 + progress * 90.0) * _cue.icon_scale
	draw_arc(center, radius, 0.0, TAU, 48, color, 2.0, true)
	for ray: int in RAY_COUNT:
		var direction := Vector2.from_angle(TAU * float(ray) / RAY_COUNT)
		draw_line(center + direction * radius, center + direction * (radius + 12.0), color, 2.0)
