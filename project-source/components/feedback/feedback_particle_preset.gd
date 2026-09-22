class_name FeedbackParticlePreset
extends Resource

## Read-only, single-emitter definition. No scene scripts or arbitrary child nodes.

@export var display_name: String = ""
@export var emitter_scene: PackedScene


func validation_error() -> String:
	if emitter_scene == null or emitter_scene.resource_path.is_empty():
		return "Particle preset requires a saved emitter scene."
	var state := emitter_scene.get_state()
	if state.get_node_count() != 1 or state.get_node_type(0) != &"GPUParticles2D":
		return "Particle scene must contain only one GPUParticles2D root."
	if scene_value(&"script", null) != null:
		return "Particle emitter scenes cannot run attached scripts."
	if not scene_value(&"process_material", null) is ParticleProcessMaterial:
		return "Particle emitter requires a ParticleProcessMaterial."
	return _timing_error()


func is_one_shot() -> bool:
	return bool(scene_value(&"one_shot", false))


func scene_value(property: StringName, fallback: Variant) -> Variant:
	if emitter_scene == null:
		return fallback
	var state := emitter_scene.get_state()
	if state.get_node_count() == 0:
		return fallback
	for index: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, index) == property:
			return state.get_node_property_value(0, index)
	return fallback


func _timing_error() -> String:
	var lifetime := float(scene_value(&"lifetime", 1.0))
	var amount := int(scene_value(&"amount", 8))
	if not is_finite(lifetime) or lifetime <= 0.0 or lifetime > 5.0:
		return "Particle lifetime must be above zero and at most 5 seconds."
	if amount < 1 or amount > 256:
		return "Particle preset amount must be between 1 and 256."
	if float(scene_value(&"speed_scale", 1.0)) != 1.0:
		return "Particle preset speed_scale must be 1 for the playback timing contract."
	return ""
