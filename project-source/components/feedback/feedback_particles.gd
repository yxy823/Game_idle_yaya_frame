extends Node2D

## One GPU emitter per object: retrigger restarts, continuous emission drains naturally.
## Stop hides immediately; the next trigger restarts the GPU simulation from its initial state.

var _emitter: GPUParticles2D
var _cue: FeedbackCue
var _elapsed: float = -1.0
var _started: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	var age := _elapsed - _cue.particle_delay_seconds
	if age < 0.0:
		return
	if not _started:
		_started = true
		_emitter.visible = true
		_emitter.restart(true)
	if not _emitter.one_shot:
		if age >= _cue.particle_emission_seconds:
			_emitter.emitting = false
		if age >= _cue.particle_emission_seconds + _emitter.lifetime:
			stop()


func _exit_tree() -> void:
	stop()


func configure(cue: FeedbackCue) -> void:
	stop()
	if _emitter != null:
		remove_child(_emitter)
		_emitter.queue_free()
		_emitter = null
	_cue = cue
	var preset := cue.particle_preset
	if preset == null or not preset.validation_error().is_empty():
		return
	_emitter = preset.emitter_scene.instantiate() as GPUParticles2D
	# The texture and curves stay read-only; each emitter owns its mutable process material.
	_emitter.process_material = _emitter.process_material.duplicate(false)
	_emitter.emitting = false
	_emitter.visible = false
	_emitter.scale = Vector2.ONE * cue.particle_scale
	_emitter.finished.connect(_on_finished.bind(_emitter))
	add_child(_emitter)


func trigger() -> void:
	stop()
	if _emitter == null:
		return
	_elapsed = 0.0
	set_process(true)
	_process(0.0)


func stop() -> void:
	_elapsed = -1.0
	_started = false
	set_process(false)
	if _emitter != null:
		_emitter.emitting = false
		_emitter.visible = false


func is_active() -> bool:
	return _elapsed >= 0.0


func _on_finished(source: GPUParticles2D) -> void:
	if source == _emitter and _started and source.one_shot and not source.emitting:
		stop()
