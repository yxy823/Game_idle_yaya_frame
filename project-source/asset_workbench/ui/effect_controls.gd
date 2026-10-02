extends VBoxContainer

## Supported particle and motion parameters. Shared scenes and clips remain read-only.

signal edited

const Widgets = preload("res://asset_workbench/ui/workbench_widgets.gd")

var _presets: Array[FeedbackParticlePreset] = []
var _clips: Array[Animation] = []
var _particle: OptionButton = OptionButton.new()
var _clip: OptionButton = OptionButton.new()
var _particle_scale: SpinBox = SpinBox.new()
var _delay: SpinBox = SpinBox.new()
var _emission: SpinBox = SpinBox.new()
var _tween: CheckBox = CheckBox.new()
var _distance: SpinBox = SpinBox.new()
var _duration: SpinBox = SpinBox.new()
var _speed: SpinBox = SpinBox.new()
var _particle_info: Label
var _motion_info: Label


func build(presets: Array[FeedbackParticlePreset], clips: Array[Animation],
		bindings: GridContainer) -> void:
	_presets = presets.duplicate()
	_clips = clips.duplicate()
	_particle.add_item("无粒子")
	_clip.add_item("无动画片段")
	for preset: FeedbackParticlePreset in _presets:
		_particle.add_item(preset.display_name)
	for clip: Animation in _clips:
		_clip.add_item(clip.resource_name if not clip.resource_name.is_empty() else (
			clip.resource_path.get_file()))
	Widgets.field(bindings, "粒子", _particle)
	Widgets.field(bindings, "动画片段", _clip)
	var particle_group := Widgets.section(self, "粒子")
	var particle_fields := Widgets.grid(particle_group)
	_number(particle_fields, "缩放 (×)", _particle_scale, FeedbackCue.PARTICLE_SCALE_LIMITS)
	_number(particle_fields, "延迟 (s)", _delay, FeedbackCue.DELAY_LIMITS)
	_number(particle_fields, "发射时长 (s)", _emission, FeedbackCue.EMISSION_LIMITS)
	_particle_info = Widgets.label(particle_group, "")
	var motion_group := Widgets.section(self, "Tween / 动画片段")
	var motion_fields := Widgets.grid(motion_group)
	_tween.text = "启用跃动"
	Widgets.field(motion_fields, "Tween", _tween)
	_number(motion_fields, "跃动距离 (px)", _distance, FeedbackCue.MOTION_DISTANCE_LIMITS)
	_number(motion_fields, "往返时长 (s)", _duration, FeedbackCue.MOTION_TIME_LIMITS)
	_number(motion_fields, "片段速度 (×)", _speed, FeedbackCue.ANIMATION_SPEED_LIMITS)
	_motion_info = Widgets.label(motion_group, "")
	Widgets.button(self, "查看粒子与动画引用…", _show_references)
	_particle.item_selected.connect(func(_index: int) -> void: edited.emit())
	_clip.item_selected.connect(func(_index: int) -> void: edited.emit())
	_tween.toggled.connect(func(_enabled: bool) -> void: edited.emit())


func display(cue: FeedbackCue) -> void:
	var preset := cue.particle_preset
	_select_resources(cue)
	_particle_scale.set_value_no_signal(cue.particle_scale)
	_delay.set_value_no_signal(cue.particle_delay_seconds)
	_emission.set_value_no_signal(cue.particle_emission_seconds)
	_tween.set_pressed_no_signal(cue.tween_enabled)
	_distance.set_value_no_signal(cue.tween_distance)
	_duration.set_value_no_signal(cue.tween_seconds)
	_speed.set_value_no_signal(cue.animation_speed)
	_particle_scale.editable = preset != null
	_delay.editable = preset != null
	_emission.editable = preset != null and not preset.is_one_shot()
	_distance.editable = cue.tween_enabled
	_duration.editable = cue.tween_enabled
	_speed.editable = cue.animation_clip != null
	_display_context(cue)


func apply_to(cue: FeedbackCue) -> void:
	if _particle.selected >= 0:
		cue.particle_preset = null if _particle.selected == 0 else _presets[_particle.selected - 1]
	if _clip.selected >= 0:
		cue.animation_clip = null if _clip.selected == 0 else _clips[_clip.selected - 1]
	cue.particle_scale = _edited_value(_particle_scale, cue.particle_scale)
	cue.particle_delay_seconds = _edited_value(_delay, cue.particle_delay_seconds)
	cue.particle_emission_seconds = _edited_value(_emission, cue.particle_emission_seconds)
	cue.tween_enabled = _tween.button_pressed
	cue.tween_distance = _edited_value(_distance, cue.tween_distance)
	cue.tween_seconds = _edited_value(_duration, cue.tween_seconds)
	cue.animation_speed = _edited_value(_speed, cue.animation_speed)


func _select_resources(cue: FeedbackCue) -> void:
	var preset := cue.particle_preset
	if preset != null and preset not in _presets:
		_presets.append(preset)
		_particle.add_item(preset.display_name)
	if cue.animation_clip != null and cue.animation_clip not in _clips:
		_clips.append(cue.animation_clip)
		_clip.add_item(cue.animation_clip.resource_path.get_file())
	_particle.select(_presets.find(preset) + 1)
	_clip.select(_clips.find(cue.animation_clip) + 1)
	_particle.tooltip_text = preset.resource_path if preset != null else "无粒子"
	_clip.tooltip_text = cue.animation_clip.resource_path if cue.animation_clip != null else "无动画片段"


func _display_context(cue: FeedbackCue) -> void:
	var preset := cue.particle_preset
	_particle_info.text = "未绑定粒子；不自动选择图像或声音。"
	if preset != null:
		_particle_info.text = "一次性爆发：自然结束；发射时长不适用。" if preset.is_one_shot() else (
			"持续发射：时长结束后等待存活粒子消散。")
		_particle_info.text += " 再次触发重启；停止全部立即隐藏并取消延迟。"
		_particle_info.text += " 局部坐标：存活粒子跟随目标。" if (
			bool(preset.scene_value(&"local_coords", false))) else (
			"场景坐标：已发射粒子留在原处；停止或移除对象仍清除。")
	_motion_info.text = "Tween 与片段作用于图像/Shader 表面及粒子发射器，各用独立变换层。"
	if cue.texture == null and cue.shader_preset == null and preset == null:
		_motion_info.text += " 当前没有可见目标；不会补入素材。"


func _show_references() -> void:
	var lines: Array[String] = ["粒子：" + _particle.tooltip_text, "动画：" + _clip.tooltip_text]
	if _particle.selected > 0:
		var preset := _presets[_particle.selected - 1]
		lines.append("发射器：" + preset.emitter_scene.resource_path)
		var texture := preset.scene_value(&"texture", null) as Texture2D
		lines.append("粒子纹理：" + (texture.resource_path if texture != null else "无纹理"))
	Widgets.show_text(self, "效果预设引用（只读）", "\n".join(lines))


func _number(parent: GridContainer, title: String, spin: SpinBox, limits: Array[float]) -> void:
	spin.min_value = limits[0]
	spin.max_value = limits[1]
	spin.step = limits[2]
	spin.value_changed.connect(func(_value: float) -> void: edited.emit())
	Widgets.field(parent, title, spin)


func _edited_value(spin: SpinBox, current: float) -> float:
	# Range step rounding must not turn an unrelated binding edit into a changed scalar.
	return current if is_equal_approx(spin.value, current) else spin.value
