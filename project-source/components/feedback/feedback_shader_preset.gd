class_name FeedbackShaderPreset
extends Resource

## Read-only material defaults and the small uniform contract exposed by the workbench.
## The presenter duplicates the material; images and audio are never part of this preset.

@export var display_name: String = "Shader"
@export var material: ShaderMaterial
@export var amount_uniform: StringName
@export_range(0.0, 100.0) var amount_at_peak: float = 1.0
@export var color_uniform: StringName


func validation_error() -> String:
	if material == null or material.shader == null:
		return "Shader preset needs a material with a shader."
	if material.shader.get_mode() != Shader.MODE_CANVAS_ITEM:
		return "This preview supports canvas_item shaders only."
	if not is_finite(amount_at_peak) or amount_at_peak < 0.0:
		return "Shader peak amount must be finite and non-negative."
	return _uniform_error()


func _uniform_error() -> String:
	var types: Dictionary[StringName, int] = {}
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		types[StringName(uniform["name"])] = int(uniform["type"])
	if not amount_uniform.is_empty() and types.get(amount_uniform, TYPE_NIL) != TYPE_FLOAT:
		return "Shader amount uniform must name a float: %s" % amount_uniform
	if not color_uniform.is_empty() and types.get(color_uniform, TYPE_NIL) != TYPE_COLOR:
		return "Shader color uniform must name a source_color vec4: %s" % color_uniform
	return ""
