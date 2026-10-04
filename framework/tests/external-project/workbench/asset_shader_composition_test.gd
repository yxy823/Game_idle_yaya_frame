extends GdUnitTestSuite

const Workbench = preload("res://yaya/asset_workbench/examples/shader_composition/example_workbench.tscn")
const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Controls = preload("res://yaya/asset_workbench/ui/cue_controls.gd")
const Session = preload("res://yaya/asset_workbench/ui/preview_session.gd")
const OUTLINE = preload("res://yaya/asset_workbench/examples/shader_composition/example_outline_cue.tres")
const NOISE = preload("res://yaya/asset_workbench/examples/shader_composition/example_noise_preset.tres")
const FIXTURE: String = "res://tests/features/asset_shader_composition/test-shader-cue.tres"


func after_test() -> void:
	if FileAccess.file_exists(FIXTURE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE))


func test_all_eight_optional_component_combinations_play_and_stop() -> void:
	var presenter: Presenter = auto_free(Presenter.new())
	add_child(presenter)
	var errors: Array[String] = []
	presenter.playback_failed.connect(func(message: String) -> void: errors.append(message))
	for mask: int in 8:
		var cue := _combination(mask)
		assert_str(cue.validation_error()).is_empty()
		presenter.configure(cue)
		presenter.trigger()
		assert_int(presenter.active_voice_count()).is_equal(1 if mask & 2 else 0)
		assert_bool(presenter.active_effect_count() > 0).is_equal(bool(mask & 5))
		presenter.stop()
		assert_int(presenter.active_effect_count()).is_zero()
		assert_int(presenter.active_voice_count()).is_zero()
	assert_array(errors).is_empty()


func test_material_uniforms_are_isolated_between_objects_and_source() -> void:
	var left: Presenter = auto_free(Presenter.new())
	var right: Presenter = auto_free(Presenter.new())
	add_child(left)
	add_child(right)
	var first := OUTLINE.trial_copy()
	var second := first.trial_copy()
	first.shader_color = Color.RED
	second.shader_color = Color.BLUE
	second.shader_strength = 0.2
	left.configure(first)
	right.configure(second)
	left.trigger()
	right.trigger()
	var left_visual: Control = left.get("_visual")
	var right_visual: Control = right.get("_visual")
	left_visual.set_process(false)
	right_visual.set_process(false)
	left_visual.call("_process", first.shader_duration_seconds * 0.5)
	right_visual.call("_process", second.shader_duration_seconds * 0.5)
	assert_object(left_visual.material).is_not_same(right_visual.material)
	assert_object(left_visual.material).is_not_same(OUTLINE.shader_preset.material)
	assert_float(left_visual.material.get_shader_parameter("line_thickness")).is_equal(7.0)
	assert_float(right_visual.material.get_shader_parameter("line_thickness")).is_equal(2.0)
	assert_bool(left_visual.material.get_shader_parameter("line_color") == Color.RED).is_true()
	assert_bool(right_visual.material.get_shader_parameter("line_color") == Color.BLUE).is_true()
	assert_float(OUTLINE.shader_preset.material.get_shader_parameter("line_thickness")).is_zero()
	left.stop()
	assert_object(left_visual.material).is_null()
	assert_object(right_visual.material).is_not_null()


func test_stop_and_reconfigure_cancel_shader_and_audio_delays() -> void:
	var presenter: Presenter = auto_free(Presenter.new())
	add_child(presenter)
	var cue := OUTLINE.trial_copy()
	cue.shader_delay_seconds = 0.2
	cue.delay_seconds = 0.2
	presenter.configure(cue)
	presenter.trigger()
	assert_object(presenter.get("_visual").material).is_null()
	presenter.stop()
	await get_tree().create_timer(0.3).timeout
	assert_int(presenter.active_effect_count()).is_zero()
	assert_int(presenter.active_voice_count()).is_zero()
	presenter.trigger()
	presenter.configure(_combination(0))
	await get_tree().create_timer(0.3).timeout
	assert_object(presenter.get("_visual").material).is_null()
	assert_int(presenter.active_voice_count()).is_zero()


func test_shader_restart_and_natural_finish_restore_plain_image() -> void:
	var presenter: Presenter = auto_free(Presenter.new())
	add_child(presenter)
	presenter.configure(OUTLINE)
	presenter.trigger()
	var visual: Control = presenter.get("_visual")
	visual.set_process(false)
	visual.call("_process", 0.6)
	assert_float(visual.material.get_shader_parameter("line_thickness")).is_equal(7.0)
	presenter.trigger()
	visual.set_process(false)
	assert_float(visual.material.get_shader_parameter("line_thickness")).is_zero()
	visual.call("_process", 1.3)
	assert_object(visual.material).is_null()
	assert_bool(visual.call("is_active")).is_false()


func test_controls_change_only_explicit_bindings_and_keep_missing_candidates() -> void:
	var controls: Controls = auto_free(Controls.new())
	add_child(controls)
	controls.build([], [], [NOISE])
	var cue := OUTLINE.trial_copy()
	controls.display(cue)
	controls.apply_to(cue)
	assert_bool(cue.same_values(OUTLINE)).is_true()
	controls.get("_texture").select(0)
	controls.apply_to(cue)
	assert_object(cue.texture).is_null()
	assert_object(cue.sound).is_same(OUTLINE.sound)
	assert_object(cue.shader_preset).is_same(OUTLINE.shader_preset)
	controls.get("_shader").get("_choice").select(1)
	controls.apply_to(cue)
	assert_object(cue.shader_preset).is_same(NOISE)
	assert_object(cue.sound).is_same(OUTLINE.sound)
	controls.get("_sound").select(0)
	controls.apply_to(cue)
	assert_object(cue.sound).is_null()
	assert_str(cue.validation_error()).is_empty()


func test_all_combinations_round_trip_and_actual_object_consumes_saved_cue() -> void:
	var source_material := FileAccess.get_file_as_string(OUTLINE.shader_preset.resource_path)
	for mask: int in 8:
		assert_int(ResourceSaver.save(OUTLINE.trial_copy(), FIXTURE)).is_equal(OK)
		var session := Session.new()
		assert_str(session.open(FIXTURE)).is_empty()
		session.drafts[0] = _combination(mask)
		session.current().shader_strength = 0.35
		session.current().shader_delay_seconds = 0.12
		session.current().shader_color = Color.GREEN
		assert_str(session.save_current()).is_empty()
		assert_bool(session.is_dirty()).is_false()
		var object: ObjectView = auto_free(ObjectView.new())
		object.cue_resource = load(FIXTURE) as FeedbackCue
		add_child(object)
		assert_bool(object.cue.same_values(session.current())).is_true()
		object.pressed.emit()
		assert_int(object.presenter.active_voice_count()).is_equal(1 if mask & 2 else 0)
		object.presenter.stop()
	var material_after := FileAccess.get_file_as_string(OUTLINE.shader_preset.resource_path)
	assert_str(material_after).is_equal(source_material)


func test_scene_ab_switches_all_objects_and_preserves_independent_trials() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Control = workbench.get("_composition")
	for session: Session in panel.sessions.values():
		session.drafts[0].shader_strength = 0.25
		session.drafts[1].shader_strength = 0.8
	panel.select_all_alternatives(1)
	panel.trigger_all()
	for object: ObjectView in panel.stage.objects:
		assert_float(object.cue.shader_strength).is_equal(0.8)
		assert_int(object.presenter.active_effect_count()).is_greater(0)
	panel.select_all_alternatives(0)
	for object: ObjectView in panel.stage.objects:
		assert_float(object.cue.shader_strength).is_equal(0.25)
		assert_int(object.presenter.active_effect_count()).is_zero()
		var key := String(panel.stage.get_path_to(object))
		assert_float(panel.sessions[key].drafts[1].shader_strength).is_equal(0.8)
	var silent: Session = panel.sessions[String(panel.stage.get_path_to(panel.stage.objects[1]))]
	assert_object(silent.drafts[0].sound).is_null()
	assert_object(silent.drafts[1].sound).is_null()
	assert_array(panel.assets(false)).not_contains([null, OUTLINE.shader_preset])


func test_shader_ui_edits_keep_other_objects_audio_and_image_independent() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Control = workbench.get("_composition")
	var controls: Controls = workbench.get("_controls")
	var other_before: FeedbackCue = panel.stage.objects[1].cue.trial_copy()
	var active_before: FeedbackCue = workbench.session.current().trial_copy()
	var replacement := load("res://yaya/asset_workbench/examples/assets/example_star.png") as Texture2D
	workbench.call("_bind_candidate", replacement)
	assert_object(workbench.session.current().texture).is_same(replacement)
	assert_object(workbench.session.current().sound).is_same(active_before.sound)
	assert_object(workbench.session.current().shader_preset).is_same(OUTLINE.shader_preset)
	var shader_controls: Control = controls.get("_shader")
	shader_controls.get("_choice").select(3)
	shader_controls.get("_choice").item_selected.emit(3)
	assert_object(workbench.session.current().shader_preset).is_same(NOISE)
	assert_object(workbench.session.current().texture).is_same(replacement)
	assert_object(workbench.session.current().sound).is_same(active_before.sound)
	assert_bool(panel.stage.objects[1].cue.same_values(other_before)).is_true()
	assert_object(workbench.session.drafts[1].shader_preset).is_same(OUTLINE.shader_preset)
	controls.get("_sound").select(0)
	controls.get("_sound").item_selected.emit(0)
	assert_str(workbench.get("_state").text).contains("未保存")
	assert_str(controls.get("_sound").get_item_text(0)).is_equal("无音频")
	assert_bool(shader_controls.get("_color").disabled).is_true()
	assert_str(shader_controls.get("_availability").text).contains("颜色")
	assert_str(shader_controls.get("_references").text).contains("canvas_item")
	assert_object(workbench.session.current().shader_preset).is_same(NOISE)


func test_invalid_shader_contract_and_strength_are_explained() -> void:
	var preset := OUTLINE.shader_preset.duplicate(false) as FeedbackShaderPreset
	preset.amount_uniform = &"missing_parameter"
	assert_str(preset.validation_error()).contains("float")
	preset.amount_uniform = &"line_thickness"
	preset.color_uniform = &"line_thickness"
	assert_str(preset.validation_error()).contains("source_color")
	var cue := OUTLINE.trial_copy()
	cue.shader_strength = NAN
	assert_str(cue.validation_error()).contains("strength")
	var invalid_material := ShaderMaterial.new()
	invalid_material.shader = Shader.new()
	invalid_material.shader.code = "shader_type spatial;"
	preset.material = invalid_material
	assert_str(preset.validation_error()).contains("canvas_item")


func _combination(mask: int) -> FeedbackCue:
	var cue := OUTLINE.trial_copy()
	cue.texture = OUTLINE.texture if mask & 1 else null
	cue.sound = OUTLINE.sound if mask & 2 else null
	cue.shader_preset = NOISE if mask & 4 else null
	cue.delay_seconds = 0.0
	return cue
