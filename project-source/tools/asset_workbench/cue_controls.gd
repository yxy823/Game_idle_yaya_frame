extends VBoxContainer

## Edits only the cue's supported fields, never arbitrary project node properties.

signal edited

const ShaderControls = preload("res://tools/asset_workbench/shader_controls.gd")
const Widgets = preload("res://tools/asset_workbench/workbench_widgets.gd")

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
var _shader: ShaderControls = ShaderControls.new()


func build(textures: Array[Texture2D], sounds: Array[AudioStream],
		shaders: Array[FeedbackShaderPreset] = []) -> void:
	_textures = textures.duplicate()
	_sounds = sounds.duplicate()
	_texture.add_item("无图像")
	_sound.add_item("无音频")
	for texture: Texture2D in textures:
		_texture.add_item(texture.resource_path.get_file())
	for sound: AudioStream in sounds:
		_sound.add_item(sound.resource_path.get_file())
	for index: int in AudioServer.bus_count:
		_bus.add_item(AudioServer.get_bus_name(index))
	add_theme_constant_override("separation", 16)
	var binding_group := Widgets.section(self, "资源绑定")
	Widgets.label(binding_group, "图像、音频、Shader 独立选择，均可留空。")
	var bindings := Widgets.grid(binding_group)
	Widgets.field(bindings, "图像", _texture)
	Widgets.field(bindings, "音频", _sound)
	Widgets.button(binding_group, "查看并复制绑定路径…", _show_binding_paths)
	var visual := Widgets.grid(Widgets.section(self, "图像 / 动画"))
	_number(visual, "缩放 (×)", _scale, FeedbackCue.SCALE_LIMITS)
	_number(visual, "动画 (s)", _duration, FeedbackCue.DURATION_LIMITS)
	var audio_group := Widgets.section(self, "音频")
	var audio := Widgets.grid(audio_group)
	_number(audio, "增益 (dB)", _gain, FeedbackCue.GAIN_LIMITS)
	_number(audio, "音高 (×)", _pitch, FeedbackCue.PITCH_LIMITS)
	_number(audio, "延迟 (s)", _delay, FeedbackCue.DELAY_LIMITS)
	Widgets.field(audio, "总线", _bus)
	Widgets.label(audio_group, "Cue 播放条件；不改变源音频或总线增益。")
	_texture.item_selected.connect(func(_index: int) -> void: edited.emit())
	_sound.item_selected.connect(func(_index: int) -> void: edited.emit())
	_bus.item_selected.connect(func(_index: int) -> void: edited.emit())
	Widgets.section(self, "Shader").add_child(_shader)
	_shader.build(shaders, bindings)
	_shader.edited.connect(func() -> void: edited.emit())


func display(cue: FeedbackCue) -> void:
	# A saved binding may be outside the scene's candidate list. Preserve it on unrelated edits.
	if cue.texture != null and cue.texture not in _textures:
		_textures.append(cue.texture)
		_texture.add_item(cue.texture.resource_path.get_file())
	if cue.sound != null and cue.sound not in _sounds:
		_sounds.append(cue.sound)
		_sound.add_item(cue.sound.resource_path.get_file())
	_texture.select(_textures.find(cue.texture) + 1)
	_sound.select(_sounds.find(cue.sound) + 1)
	_texture.tooltip_text = cue.texture.resource_path if cue.texture != null else "无图像"
	_sound.tooltip_text = cue.sound.resource_path if cue.sound != null else "无音频"
	_scale.set_value_no_signal(cue.icon_scale)
	_duration.set_value_no_signal(cue.animation_seconds)
	_gain.set_value_no_signal(cue.gain_db)
	_pitch.set_value_no_signal(cue.pitch_scale)
	_delay.set_value_no_signal(cue.delay_seconds)
	_bus.select(AudioServer.get_bus_index(cue.bus))
	_shader.display(cue)


func apply_to(cue: FeedbackCue) -> void:
	if _texture.selected >= 0:
		cue.texture = null if _texture.selected == 0 else _textures[_texture.selected - 1]
	if _sound.selected >= 0:
		cue.sound = null if _sound.selected == 0 else _sounds[_sound.selected - 1]
	cue.icon_scale = _scale.value
	cue.animation_seconds = _duration.value
	cue.gain_db = _gain.value
	cue.pitch_scale = _pitch.value
	cue.delay_seconds = _delay.value
	if _bus.selected >= 0:
		cue.bus = _bus.get_item_text(_bus.selected)
	_shader.apply_to(cue)


func _show_binding_paths() -> void:
	var texture_path := "无图像" if _texture.selected <= 0 else (
		_textures[_texture.selected - 1].resource_path)
	var sound_path := "无音频" if _sound.selected <= 0 else _sounds[_sound.selected - 1].resource_path
	Widgets.show_text(self, "当前方案绑定路径（只读，可选择复制）",
		"图像：" + texture_path + "\n音频：" + sound_path)


func _number(parent: GridContainer, title: String, spin: SpinBox, limits: Array[float]) -> void:
	spin.min_value = limits[0]
	spin.max_value = limits[1]
	spin.step = limits[2]
	spin.value_changed.connect(func(_value: float) -> void: edited.emit())
	Widgets.field(parent, title, spin)
