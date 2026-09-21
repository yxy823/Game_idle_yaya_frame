extends VBoxContainer

## Shader choice and per-cue values; never edits the shared preset material.

signal edited

var _presets: Array[FeedbackShaderPreset] = []
var _choice: OptionButton = OptionButton.new()
var _strength: SpinBox = SpinBox.new()
var _color: ColorPickerButton = ColorPickerButton.new()
var _delay: SpinBox = SpinBox.new()
var _duration: SpinBox = SpinBox.new()


func build(presets: Array[FeedbackShaderPreset]) -> void:
	_presets = presets.duplicate()
	_choice.add_item("None")
	for preset: FeedbackShaderPreset in _presets:
		_choice.add_item(preset.display_name)
	_field("Shader (independent of image and audio)", _choice)
	_number("Shader peak strength (0-1)", _strength, FeedbackCue.STRENGTH_LIMITS)
	_color.custom_minimum_size.y = 32.0
	_field("Shader effect color", _color)
	_number("Shader delay from event (seconds)", _delay, FeedbackCue.DELAY_LIMITS)
	_number("Shader duration (seconds)", _duration, FeedbackCue.DURATION_LIMITS)
	_choice.item_selected.connect(func(_index: int) -> void: edited.emit())
	_color.color_changed.connect(func(_value: Color) -> void: edited.emit())
	var note := Label.new()
	note.text = "No image: Shader uses a plain quad. Trigger restarts the effect; Stop restores the image."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)


func display(cue: FeedbackCue) -> void:
	var preset := cue.shader_preset
	if preset != null and preset not in _presets:
		_presets.append(preset)
		_choice.add_item(preset.display_name)
	_choice.select(_presets.find(preset) + 1)
	_strength.set_value_no_signal(cue.shader_strength)
	_color.color = cue.shader_color
	_delay.set_value_no_signal(cue.shader_delay_seconds)
	_duration.set_value_no_signal(cue.shader_duration_seconds)
	_strength.editable = preset != null and not preset.amount_uniform.is_empty()
	_color.disabled = preset == null or preset.color_uniform.is_empty()
	_delay.editable = preset != null
	_duration.editable = preset != null


func apply_to(cue: FeedbackCue) -> void:
	if _choice.selected >= 0:
		cue.shader_preset = null if _choice.selected == 0 else _presets[_choice.selected - 1]
	cue.shader_strength = _strength.value
	cue.shader_color = _color.color
	cue.shader_delay_seconds = _delay.value
	cue.shader_duration_seconds = _duration.value


func _field(title: String, control: Control) -> void:
	var label := Label.new()
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	add_child(control)


func _number(title: String, spin: SpinBox, limits: Array[float]) -> void:
	spin.min_value = limits[0]
	spin.max_value = limits[1]
	spin.step = limits[2]
	spin.value_changed.connect(func(_value: float) -> void: edited.emit())
	_field(title, spin)
