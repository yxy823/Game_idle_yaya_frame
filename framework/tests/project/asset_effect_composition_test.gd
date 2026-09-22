extends GdUnitTestSuite

const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Controls = preload("res://tools/asset_workbench/cue_controls.gd")
const Session = preload("res://tools/asset_workbench/preview_session.gd")
const Workbench = preload("res://examples/asset_workbench/effects_composition/example-workbench.tscn")
const BURST = preload("res://examples/asset_workbench/effects_composition/example-burst-cue.tres")
const STREAM = preload("res://examples/asset_workbench/effects_composition/example-stream-preset.tres")
const CLIP = preload("res://examples/asset_workbench/effects_composition/example-wobble-animation.tres")
const FIXTURE: String = "res://tests/features/asset_effect_composition/test-effect-cue.tres"
const INVALID_CLIP: String = "res://tests/features/asset_effect_composition/test-invalid-clip.tres"


func after_test() -> void:
	for path: String in [FIXTURE, INVALID_CLIP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_optional_particle_tween_and_clip_do_not_create_media_bindings() -> void:
	var presenter := _presenter()
	var errors: Array[String] = []
	presenter.playback_failed.connect(func(message: String) -> void: errors.append(message))
	for mask: int in 8:
		var cue := FeedbackCue.new()
		cue.particle_preset = STREAM if mask & 1 else null
		cue.tween_enabled = bool(mask & 2)
		cue.animation_clip = CLIP if mask & 4 else null
		assert_str(cue.validation_error()).is_empty()
		presenter.configure(cue)
		presenter.trigger()
		assert_bool(presenter.active_effect_count() > 0).is_equal(mask != 0)
		assert_int(presenter.active_voice_count()).is_zero()
		assert_object(cue.texture).is_null()
		assert_object(cue.shader_preset).is_null()
		presenter.stop()
		assert_int(presenter.active_effect_count()).is_zero()
	assert_array(errors).is_empty()


func test_particle_delay_stop_and_reconfigure_discard_old_playback() -> void:
	var presenter := _presenter()
	var cue := FeedbackCue.new()
	cue.particle_preset = STREAM
	cue.particle_delay_seconds = 0.2
	presenter.configure(cue)
	presenter.trigger()
	var particles: Node2D = presenter.get("_particles")
	var emitter: GPUParticles2D = particles.get("_emitter")
	assert_bool(emitter.visible).is_false()
	presenter.stop()
	await get_tree().create_timer(0.3).timeout
	assert_bool(emitter.visible).is_false()
	assert_int(presenter.active_effect_count()).is_zero()
	presenter.trigger()
	presenter.configure(FeedbackCue.new())
	await get_tree().create_timer(0.3).timeout
	assert_int(particles.get_child_count()).is_zero()
	assert_int(presenter.active_effect_count()).is_zero()


func test_continuous_emission_drains_and_stop_hides_immediately() -> void:
	var presenter := _presenter()
	var cue := FeedbackCue.new()
	cue.particle_preset = STREAM
	cue.particle_emission_seconds = 0.15
	presenter.configure(cue)
	presenter.trigger()
	var emitter: GPUParticles2D = presenter.get("_particles").get("_emitter")
	await get_tree().create_timer(0.25).timeout
	assert_bool(emitter.emitting).is_false()
	assert_bool(emitter.visible).is_true()
	await get_tree().create_timer(0.9).timeout
	assert_bool(emitter.visible).is_false()
	assert_int(presenter.active_effect_count()).is_zero()
	presenter.trigger()
	presenter.stop()
	assert_bool(emitter.visible).is_false()
	assert_bool(emitter.emitting).is_false()


func test_repeated_particle_trigger_reuses_one_isolated_emitter() -> void:
	var left := _presenter()
	var right := _presenter()
	left.configure(BURST)
	right.configure(BURST)
	var particles: Node2D = left.get("_particles")
	var emitter: GPUParticles2D = particles.get("_emitter")
	var other: GPUParticles2D = right.get("_particles").get("_emitter")
	var source: Material = BURST.particle_preset.scene_value(&"process_material", null)
	assert_object(emitter.process_material).is_not_same(other.process_material)
	assert_object(emitter.process_material).is_not_same(source)
	assert_object(emitter.texture).is_same(other.texture)
	for _repeat_index: int in 30:
		left.trigger()
	assert_int(particles.get_child_count()).is_equal(1)
	assert_object(particles.get("_emitter")).is_same(emitter)
	assert_bool(other.emitting).is_false()
	left.stop()
	assert_bool(emitter.visible).is_false()


func test_tween_and_clip_have_distinct_layers_and_restore_their_transforms() -> void:
	var presenter := _presenter()
	var cue := FeedbackCue.new()
	cue.tween_enabled = true
	cue.tween_seconds = 0.5
	cue.animation_clip = CLIP
	presenter.position = Vector2(15, 25)
	presenter.configure(cue)
	presenter.trigger()
	var motion: Node2D = presenter.get("_motion")
	var tween_root: Node2D = motion.get("_tween_root")
	var content: Node2D = motion.get("content")
	await get_tree().create_timer(0.2).timeout
	assert_float(tween_root.position.y).is_less(0.0)
	assert_bool(content.transform != Transform2D.IDENTITY).is_true()
	assert_bool(presenter.position == Vector2(15, 25)).is_true()
	assert_float(content.position.y).is_zero()
	presenter.stop()
	assert_bool(tween_root.position == Vector2.ZERO).is_true()
	assert_bool(content.transform == Transform2D.IDENTITY).is_true()
	presenter.trigger()
	await get_tree().create_timer(1.0).timeout
	assert_int(presenter.active_effect_count()).is_zero()
	assert_bool(content.transform == Transform2D.IDENTITY).is_true()
	assert_bool(tween_root.position == Vector2.ZERO).is_true()


func test_motion_retrigger_switch_and_tree_exit_cancel_without_late_restore() -> void:
	var presenter := _presenter()
	var cue := FeedbackCue.new()
	cue.tween_enabled = true
	cue.animation_clip = CLIP
	presenter.configure(cue)
	for _repeat_index: int in 10:
		presenter.trigger()
	assert_int(presenter.active_effect_count()).is_equal(2)
	presenter.configure(FeedbackCue.new())
	await get_tree().create_timer(0.9).timeout
	assert_int(presenter.active_effect_count()).is_zero()
	presenter.configure(cue)
	presenter.trigger()
	remove_child(presenter)
	assert_int(presenter.active_effect_count()).is_zero()
	add_child(presenter)
	await get_tree().create_timer(0.1).timeout
	assert_int(presenter.active_effect_count()).is_zero()


func test_effect_fields_round_trip_and_consumer_uses_saved_current_trial() -> void:
	assert_int(ResourceSaver.save(BURST.trial_copy(), FIXTURE)).is_equal(OK)
	var session := Session.new()
	assert_str(session.open(FIXTURE)).is_empty()
	var other_before := session.drafts[1].trial_copy()
	var cue := session.current()
	cue.particle_preset = STREAM
	cue.particle_scale = 0.7
	cue.particle_delay_seconds = 0.12
	cue.particle_emission_seconds = 0.35
	cue.tween_distance = 18.0
	cue.tween_seconds = 0.4
	cue.animation_clip = CLIP
	cue.animation_speed = 1.5
	assert_bool(session.is_dirty()).is_true()
	assert_str(session.save_current()).is_empty()
	assert_bool(session.is_dirty()).is_false()
	assert_bool(session.drafts[1].same_values(other_before)).is_true()
	var object: ObjectView = auto_free(ObjectView.new())
	object.cue_path = FIXTURE
	add_child(object)
	assert_bool(object.cue.same_values(cue)).is_true()
	object.pressed.emit()
	assert_bool(object.presenter.get("_particles").call("is_active")).is_true()
	assert_int(object.presenter.get("_motion").call("active_count")).is_equal(2)
	object.presenter.stop()


func test_every_new_edit_is_dirty_and_copying_preserves_read_only_definitions() -> void:
	assert_int(ResourceSaver.save(BURST.trial_copy(), FIXTURE)).is_equal(OK)
	var session := Session.new()
	assert_str(session.open(FIXTURE)).is_empty()
	var changes: Dictionary[StringName, Variant] = {
		&"particle_preset": STREAM, &"particle_scale": 0.75, &"particle_delay_seconds": 0.1,
		&"particle_emission_seconds": 0.5, &"tween_enabled": false, &"tween_distance": 15.0,
		&"tween_seconds": 0.5, &"animation_clip": CLIP, &"animation_speed": 1.5,
	}
	for field: StringName in changes:
		session.reset_current()
		session.current().set(field, changes[field])
		assert_bool(session.is_dirty()).is_true()
		session.copy_to_other()
		assert_bool(session.current().same_values(session.drafts[1])).is_true()
	assert_object(session.current().particle_preset).is_same(BURST.particle_preset)
	session.current().tween_distance = 30.0
	assert_float(session.drafts[1].tween_distance).is_equal(BURST.tween_distance)


func test_controls_preserve_unlisted_bindings_and_disable_inapplicable_parameters() -> void:
	var controls: Controls = auto_free(Controls.new())
	add_child(controls)
	controls.build([], [])
	var cue := BURST.trial_copy()
	cue.animation_clip = CLIP
	controls.display(cue)
	controls.apply_to(cue)
	var effects: Control = controls.get("_effects")
	assert_object(cue.particle_preset).is_same(BURST.particle_preset)
	assert_object(cue.animation_clip).is_same(CLIP)
	assert_bool(effects.get("_emission").editable).is_false()
	assert_bool(effects.get("_speed").editable).is_true()
	effects.get("_particle").select(0)
	controls.apply_to(cue)
	controls.display(cue)
	assert_object(cue.particle_preset).is_null()
	assert_object(cue.texture).is_same(BURST.texture)
	assert_object(cue.sound).is_same(BURST.sound)
	assert_object(cue.animation_clip).is_same(CLIP)
	assert_bool(effects.get("_particle_scale").editable).is_false()


func test_workbench_edits_and_scene_ab_preserve_other_trials_and_source_scope() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Control = workbench.get("_composition")
	var other_before: FeedbackCue = panel.stage.objects[1].cue.trial_copy()
	var trial_before: FeedbackCue = workbench.session.drafts[1].trial_copy()
	var effects: Control = workbench.get("_controls").get("_effects")
	effects.get("_particle").select(2)
	effects.get("_particle").item_selected.emit(2)
	assert_object(workbench.session.current().particle_preset).is_same(STREAM)
	assert_bool(workbench.session.drafts[1].same_values(trial_before)).is_true()
	assert_bool(panel.stage.objects[1].cue.same_values(other_before)).is_true()
	assert_str(workbench.get("_state").text).contains("未保存")
	panel.select_all_alternatives(1)
	assert_object(panel.stage.objects[0].cue.particle_preset).is_same(BURST.particle_preset)
	panel.select_all_alternatives(0)
	assert_object(panel.stage.objects[0].cue.particle_preset).is_same(STREAM)
	panel.trigger_all()
	workbench.stop_all()
	for object: ObjectView in panel.stage.objects:
		assert_int(object.presenter.active_effect_count()).is_zero()
	for asset: Resource in panel.assets(false):
		assert_bool(asset is Texture2D or asset is AudioStream).is_true()


func test_invalid_animation_tracks_and_looping_are_rejected_before_playback() -> void:
	var clip := CLIP.duplicate(false) as Animation
	clip.loop_mode = Animation.LOOP_LINEAR
	assert_int(ResourceSaver.save(clip, INVALID_CLIP)).is_equal(OK)
	var cue := FeedbackCue.new()
	cue.animation_clip = load(INVALID_CLIP) as Animation
	assert_str(cue.validation_error()).contains("non-looping")
	cue.animation_clip.loop_mode = Animation.LOOP_NONE
	cue.animation_clip.track_set_path(0, NodePath("../Other:rotation"))
	assert_str(cue.validation_error()).contains("local")
	cue.animation_clip.track_set_path(0, NodePath(".:rotation"))
	cue.animation_clip.track_set_key_value(0, 0, NAN)
	assert_str(cue.validation_error()).contains("finite")
	assert_float(CLIP.track_get_key_value(0, 0)).is_zero()


func test_invalid_particle_scene_and_effect_ranges_are_explained() -> void:
	var preset := FeedbackParticlePreset.new()
	assert_str(preset.validation_error()).contains("saved emitter")
	preset.emitter_scene = Workbench
	assert_str(preset.validation_error()).contains("GPUParticles2D")
	var cue := BURST.trial_copy()
	cue.particle_scale = NAN
	assert_str(cue.validation_error()).contains("Particle scale")
	cue.particle_scale = 1.0
	cue.tween_seconds = -1.0
	assert_str(cue.validation_error()).contains("Tween")
	cue.tween_seconds = 0.5
	cue.animation_clip = CLIP
	cue.animation_speed = 0.0
	assert_str(cue.validation_error()).contains("Animation speed")


func _presenter() -> Presenter:
	var presenter: Presenter = auto_free(Presenter.new())
	presenter.size = Vector2(190, 185)
	add_child(presenter)
	return presenter
