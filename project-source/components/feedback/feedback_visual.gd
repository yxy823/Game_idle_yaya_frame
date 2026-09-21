extends Control

## Image surface with an optional, independently timed material effect.
## Shader-only cues draw on a white quad. No fallback image or audio is selected.

var _cue: FeedbackCue
var _runtime_material: ShaderMaterial
var _elapsed: float = -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	var time := _elapsed - _cue.shader_delay_seconds
	if time >= _cue.shader_duration_seconds:
		stop()
	elif time >= 0.0:
		material = _runtime_material
		var preset := _cue.shader_preset
		if not preset.amount_uniform.is_empty():
			var envelope := sin(PI * time / _cue.shader_duration_seconds)
			_runtime_material.set_shader_parameter(preset.amount_uniform,
				preset.amount_at_peak * _cue.shader_strength * envelope)
		queue_redraw()


func _draw() -> void:
	if _cue == null:
		return
	if _cue.texture != null:
		draw_texture_rect(_cue.texture, Rect2(Vector2.ZERO, size), false)
	elif material != null:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)


func _exit_tree() -> void:
	stop()


func configure(cue: FeedbackCue) -> void:
	stop()
	_cue = cue
	_runtime_material = null
	if cue.shader_preset != null and cue.shader_preset.validation_error().is_empty():
		# These imported shaders use ordinary uniforms: each surface owns its material instance.
		_runtime_material = cue.shader_preset.material.duplicate(false) as ShaderMaterial
		if not cue.shader_preset.color_uniform.is_empty():
			_runtime_material.set_shader_parameter(cue.shader_preset.color_uniform, cue.shader_color)
	queue_redraw()


func trigger() -> void:
	if _runtime_material == null:
		return
	# Re-trigger restarts this surface's effect; audio voices remain separately owned.
	stop()
	_elapsed = 0.0
	set_process(true)
	_process(0.0)


func stop() -> void:
	_elapsed = -1.0
	set_process(false)
	material = null
	queue_redraw()


func is_active() -> bool:
	return _elapsed >= 0.0
