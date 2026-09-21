extends VBoxContainer

## Edits only the cue's supported fields, never arbitrary project node properties.

signal edited

var _textures: Array[Texture2D] = []
var _sounds: Array[AudioStream] = []
var _texture: OptionButton = OptionButton.new()
var _sound: OptionButton = OptionButton.new()
var _scale: SpinBox = SpinBox.new()
var _duration: SpinBox = SpinBox.new()
var _gain: SpinBox = SpinBox.new()
var _pitch: SpinBox = SpinBox.new()
var _delay: SpinBox = SpinBox.new()
var _bus: OptionButton = OptionButton.new()


func build(textures: Array[Texture2D], sounds: Array[AudioStream]) -> void:
	_textures = textures
	_sounds = sounds
	for texture: Texture2D in textures:
		_texture.add_item(texture.resource_path.get_file())
	for sound: AudioStream in sounds:
		_sound.add_item(sound.resource_path.get_file())
	for index: int in AudioServer.bus_count:
		_bus.add_item(AudioServer.get_bus_name(index))
	_field("Visual candidate", _texture)
	_field("Audio candidate", _sound)
	_number("Icon scale (multiplier)", _scale, FeedbackCue.SCALE_LIMITS)
	_number("Animation (seconds)", _duration, FeedbackCue.DURATION_LIMITS)
	_number("Per-play gain (dB)", _gain, FeedbackCue.GAIN_LIMITS)
	_number("Playback pitch (multiplier)", _pitch, FeedbackCue.PITCH_LIMITS)
	_number("Sound delay from event (seconds)", _delay, FeedbackCue.DELAY_LIMITS)
	_field("Audio bus (does not change bus gain)", _bus)
	_texture.item_selected.connect(func(_index: int) -> void: edited.emit())
	_sound.item_selected.connect(func(_index: int) -> void: edited.emit())
	_bus.item_selected.connect(func(_index: int) -> void: edited.emit())


func display(cue: FeedbackCue) -> void:
	_texture.select(_textures.find(cue.texture))
	_sound.select(_sounds.find(cue.sound))
	_scale.set_value_no_signal(cue.icon_scale)
	_duration.set_value_no_signal(cue.animation_seconds)
	_gain.set_value_no_signal(cue.gain_db)
	_pitch.set_value_no_signal(cue.pitch_scale)
	_delay.set_value_no_signal(cue.delay_seconds)
	_bus.select(AudioServer.get_bus_index(cue.bus))


func apply_to(cue: FeedbackCue) -> void:
	if _texture.selected >= 0:
		cue.texture = _textures[_texture.selected]
	if _sound.selected >= 0:
		cue.sound = _sounds[_sound.selected]
	cue.icon_scale = _scale.value
	cue.animation_seconds = _duration.value
	cue.gain_db = _gain.value
	cue.pitch_scale = _pitch.value
	cue.delay_seconds = _delay.value
	if _bus.selected >= 0:
		cue.bus = _bus.get_item_text(_bus.selected)


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
