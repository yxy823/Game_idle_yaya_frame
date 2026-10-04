extends VBoxContainer

## Shader choice and per-cue values; never edits the shared preset material.

signal edited

const Widgets = preload("res://yaya/asset_workbench/ui/workbench_widgets.gd")

var _presets: Array[FeedbackShaderPreset] = []
var _choice: OptionButton = OptionButton.new()
var _strength: SpinBox = SpinBox.new()
var _color: ColorPickerButton = ColorPickerButton.new()
var _delay: SpinBox = SpinBox.new()
var _duration: SpinBox = SpinBox.new()
var _availability: Label
var _references: Label


func build(presets: Array[FeedbackShaderPreset], bindings: GridContainer = null) -> void:
	_presets = presets.duplicate()
	_choice.add_item("无 Shader")
	for preset: FeedbackShaderPreset in _presets:
		_choice.add_item(preset.display_name)
	Widgets.field(Widgets.grid(self) if bindings == null else bindings, "Shader", _choice)
	var fields := Widgets.grid(self)
	_number(fields, "强度 (0–1)", _strength, FeedbackCue.STRENGTH_LIMITS)
	_color.custom_minimum_size.y = 32.0
	Widgets.field(fields, "效果颜色", _color)
	_number(fields, "延迟 (s)", _delay, FeedbackCue.DELAY_LIMITS)
	_number(fields, "时长 (s)", _duration, FeedbackCue.DURATION_LIMITS)
	_choice.item_selected.connect(func(_index: int) -> void: edited.emit())
	_color.color_changed.connect(func(_value: Color) -> void: edited.emit())
	_availability = Widgets.label(self, "")
	_references = Widgets.label(Widgets.section(self, "预设引用（只读）", true), "")
	Widgets.button(self, "查看并复制 Shader 引用…", func() -> void:
		Widgets.show_text(self, "Shader 预设引用（只读）", _references.tooltip_text))
	Widgets.label(self, "无图像时使用现有承载面；触发重新开始，停止恢复原状。")


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
	_availability.text = "未绑定 Shader；参数不可用。"
	if preset != null:
		var missing: Array[String] = []
		if preset.amount_uniform.is_empty():
			missing.append("强度")
		if preset.color_uniform.is_empty():
			missing.append("颜色")
		_availability.text = "当前预设支持强度、颜色和时序。" if missing.is_empty() else (
			"当前预设未提供 %s uniform，对应参数不可用。" % "、".join(missing))
	_update_references(preset)


func apply_to(cue: FeedbackCue) -> void:
	if _choice.selected >= 0:
		cue.shader_preset = null if _choice.selected == 0 else _presets[_choice.selected - 1]
	cue.shader_strength = _strength.value
	cue.shader_color = _color.color
	cue.shader_delay_seconds = _delay.value
	cue.shader_duration_seconds = _duration.value


func _update_references(preset: FeedbackShaderPreset) -> void:
	var lines: Array[String] = []
	var paths: Array[String] = []
	if preset != null:
		lines.append("预设：" + preset.display_name)
		paths.append("预设：" + preset.resource_path)
		var preset_material := preset.material
		if preset_material != null and preset_material.shader != null:
			var mode := preset_material.shader.get_mode()
			lines.append("类型：" + ("canvas_item" if mode == Shader.MODE_CANVAS_ITEM else str(mode)))
			lines.append("Shader：" + preset_material.shader.resource_path.get_file())
			lines.append("材质：" + preset_material.resource_path.get_file())
			paths.append("Shader：" + preset_material.shader.resource_path)
			paths.append("材质：" + preset_material.resource_path)
			_texture_references(preset_material, lines, paths)
	_references.text = "\n".join(lines) if not lines.is_empty() else "无 Shader 预设"
	_references.tooltip_text = "\n".join(paths)
	_choice.tooltip_text = _references.tooltip_text


func _texture_references(preset_material: ShaderMaterial, lines: Array[String],
		paths: Array[String]) -> void:
	for uniform: Dictionary in preset_material.shader.get_shader_uniform_list():
		var value: Variant = preset_material.get_shader_parameter(uniform["name"])
		if value is Texture2D:
			var reference: String = value.resource_path if not value.resource_path.is_empty() else (
				"内嵌 " + value.get_class())
			lines.append("纹理 %s：%s" % [uniform["name"], reference.get_file()])
			paths.append("纹理 %s：%s" % [uniform["name"], reference])


func _number(parent: GridContainer, title: String, spin: SpinBox, limits: Array[float]) -> void:
	spin.min_value = limits[0]
	spin.max_value = limits[1]
	spin.step = limits[2]
	spin.value_changed.connect(func(_value: float) -> void: edited.emit())
	Widgets.field(parent, title, spin)
