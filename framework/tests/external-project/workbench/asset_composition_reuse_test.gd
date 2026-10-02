extends GdUnitTestSuite

## E3: reusable native instances have independent drafts and explicit shared-file saves.

const Workbench = preload("res://asset_workbench/examples/effects_composition/example_workbench.tscn")
const Consumer = preload("res://asset_workbench/examples/effects_composition/example_consumer.tscn")
const Session = preload("res://asset_workbench/ui/preview_session.gd")
const CompositionPanel = preload("res://asset_workbench/ui/composition_panel.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const CORE = preload("res://asset_workbench/examples/effects_composition/example_cluster_core_cue.tres")
const DIRECTORY: String = "res://tests/features/asset_composition_reuse/"

var _workbench: Control
var _panel: CompositionPanel
var _owned: Array[String] = []


func before_test() -> void:
	_workbench = auto_free(Workbench.instantiate())
	add_child(_workbench)
	_panel = _workbench.get("_composition")


func after_test() -> void:
	_workbench.call("stop_all")
	for path: String in _owned:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_owned.clear()


func test_shared_cue_instances_keep_selection_and_both_trials_independent() -> void:
	collect_orphan_node_details()
	assert_int(_panel.stage.objects.size()).is_equal(6)
	assert_int(_panel.sessions.size()).is_equal(6)
	var left := _panel.stage.object_at("GroupA/Core")
	var right := _panel.stage.object_at("GroupB/Core")
	assert_str(left.cue_path).is_equal(right.cue_path)
	left.pressed.emit()
	_workbench.session.current().tween_distance = 36.0
	_workbench.call("_refresh")
	assert_float(left.cue.tween_distance).is_equal(36.0)
	assert_float(right.cue.tween_distance).is_equal(CORE.tween_distance)
	right.pressed.emit()
	_workbench.call("_select_alternative", 1)
	_workbench.session.current().tween_distance = 12.0
	_workbench.call("_refresh")
	assert_object(_workbench.presenter).is_same(right.presenter)
	assert_str(_panel.object_name()).contains("GroupB / ")
	assert_str(_panel.get("_status").text).contains("2 个对象共享")
	assert_bool(right.button_pressed).is_true()
	assert_bool(left.button_pressed).is_false()
	assert_str(_panel.get("_scene_state").text).contains("混合方案")
	left.pressed.emit()
	assert_int(_workbench.session.active_index).is_zero()
	assert_float(_workbench.session.current().tween_distance).is_equal(36.0)
	assert_float(_workbench.session.drafts[1].tween_distance).is_equal(CORE.tween_distance)
	_panel.select_all_alternatives(1)
	assert_float(left.cue.tween_distance).is_equal(CORE.tween_distance)
	assert_float(right.cue.tween_distance).is_equal(12.0)
	# Reconfiguring releases replaced emitters with queue_free at the end of this frame.
	await get_tree().process_frame


func test_shared_identical_save_writes_one_target_and_preserves_inactive_drafts() -> void:
	var first := _file_session("matching")
	var second := Session.new()
	assert_str(second.open(first.target_path)).is_empty()
	first.current().tween_distance = 27.0
	second.current().tween_distance = 27.0
	second.drafts[1].tween_distance = 11.0
	_panel.sessions = {"first": first, "second": second}
	_panel.save_all()
	assert_str(_panel.get("_status").text).contains("已保存 1/1")
	assert_bool(first.is_dirty()).is_false()
	assert_bool(second.is_dirty()).is_false()
	assert_float(second.drafts[1].tween_distance).is_equal(11.0)
	assert_str(second.save_error()).is_empty()
	var object: ObjectView = auto_free(ObjectView.new())
	object.cue_resource = load(first.target_path) as FeedbackCue
	add_child(object)
	assert_float(object.cue.tween_distance).is_equal(27.0)


func test_shared_divergent_drafts_are_skipped_while_other_file_is_saved() -> void:
	var first := _file_session("divergent")
	var second := Session.new()
	assert_str(second.open(first.target_path)).is_empty()
	var independent := _file_session("independent")
	var original_text := FileAccess.get_file_as_string(first.target_path)
	first.current().tween_distance = 21.0
	second.current().tween_distance = 29.0
	independent.current().tween_distance = 33.0
	_panel.sessions = {"first": first, "second": second, "independent": independent}
	_panel.save_all()
	assert_str(_panel.get("_status").text).contains("已保存 1/2")
	assert_str(_workbench.get("_status").text).contains("引用同一 Cue 但内容不同")
	assert_str(FileAccess.get_file_as_string(first.target_path)).is_equal(original_text)
	assert_bool(first.is_dirty()).is_true()
	assert_bool(second.is_dirty()).is_true()
	assert_bool(independent.is_dirty()).is_false()


func test_current_save_keeps_other_instance_draft_and_requires_reload_before_overwrite() -> void:
	var first := _file_session("current")
	var second := Session.new()
	assert_str(second.open(first.target_path)).is_empty()
	first.current().tween_distance = 25.0
	second.current().tween_distance = 31.0
	assert_str(first.save_current()).is_empty()
	assert_float(second.current().tween_distance).is_equal(31.0)
	assert_str(second.save_current()).contains("File changed on disk")
	assert_float(second.drafts[1].tween_distance).is_equal(CORE.tween_distance)
	assert_str(second.open(second.target_path)).is_empty()
	assert_float(second.drafts[0].tween_distance).is_equal(25.0)
	assert_float(second.drafts[1].tween_distance).is_equal(25.0)


func test_any_stale_session_blocks_shared_save_without_masking_disk_conflict() -> void:
	var first := _file_session("conflict")
	var second := Session.new()
	assert_str(second.open(first.target_path)).is_empty()
	var file := FileAccess.open(first.target_path, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_string("\n; external edit\n")
	file.close()
	assert_str(first.open(first.target_path)).is_empty()
	first.current().tween_distance = 20.0
	second.current().tween_distance = 20.0
	_panel.sessions = {"fresh": first, "stale": second}
	_panel.save_all()
	assert_str(_panel.get("_status").text).contains("已保存 0/1")
	assert_str(_workbench.get("_status").text).contains("File changed on disk")
	assert_bool(first.is_dirty()).is_true()


func test_native_consumer_reuses_clusters_with_isolated_effects_and_transforms() -> void:
	var scene: Control = auto_free(Consumer.instantiate())
	add_child(scene)
	assert_int(scene.objects.size()).is_equal(6)
	var left: ObjectView = scene.object_at("GroupA/Core")
	var right: ObjectView = scene.object_at("GroupB/Core")
	assert_str(left.get_parent().scene_file_path).is_equal(right.get_parent().scene_file_path)
	assert_float(left.get_parent().rotation).is_less(0.0)
	assert_float(right.get_parent().rotation).is_greater(0.0)
	assert_int(left.z_index).is_equal(1)
	scene.trigger_all()
	var emitter: GPUParticles2D = left.presenter.get("_particles").get("_emitter")
	var other: GPUParticles2D = right.presenter.get("_particles").get("_emitter")
	assert_object(emitter.process_material).is_not_same(other.process_material)
	assert_object(left.presenter.get("_visual").material).is_not_same(
		right.presenter.get("_visual").material)
	assert_object(left.presenter.get("_motion")).is_not_same(right.presenter.get("_motion"))
	left.presenter.stop()
	assert_int(left.presenter.active_effect_count()).is_zero()
	assert_int(right.presenter.active_effect_count()).is_greater(0)
	scene.stop()
	for object: ObjectView in scene.objects:
		assert_int(object.presenter.active_effect_count()).is_zero()


func test_removing_cluster_prunes_stage_and_cancels_its_delays_without_stopping_other() -> void:
	var scene: Control = auto_free(Consumer.instantiate())
	add_child(scene)
	var group: Control = scene.get_node("GroupA")
	var removed: ObjectView = scene.object_at("GroupA/Core")
	var kept: ObjectView = scene.object_at("GroupB/Core")
	var cue := removed.cue.trial_copy()
	cue.delay_seconds = 0.25
	cue.particle_delay_seconds = 0.25
	removed.preview(cue)
	scene.trigger_all()
	scene.remove_child(group)
	assert_int(removed.presenter.active_effect_count()).is_zero()
	assert_int(scene.objects.size()).is_equal(3)
	assert_int(kept.presenter.active_effect_count()).is_greater(0)
	await get_tree().create_timer(0.35).timeout
	assert_int(removed.presenter.active_voice_count()).is_zero()
	group.queue_free()
	await get_tree().process_frame
	assert_bool(is_instance_valid(removed)).is_false()
	scene.trigger_all()
	scene.stop()
	assert_int(kept.presenter.active_effect_count()).is_zero()


func test_local_and_scene_coordinates_belong_to_presets_not_image_bindings() -> void:
	for key: String in ["GroupA/Local", "GroupA/World"]:
		var object := _panel.stage.object_at(key)
		var emitter: GPUParticles2D = object.presenter.get("_particles").get("_emitter")
		assert_bool(emitter.local_coords).is_equal(key.ends_with("Local"))
		assert_object(object.cue.texture).is_null()
		assert_object(object.cue.sound).is_null()
		assert_object(object.cue.shader_preset).is_null()
		assert_bool(object.cue.tween_enabled).is_true()


func _file_session(stem: String) -> Session:
	var path := DIRECTORY + "test-" + stem + ".tres"
	_owned.append(path)
	assert_int(ResourceSaver.save(CORE.trial_copy(), path)).is_equal(OK)
	var session := Session.new()
	assert_str(session.open(path)).is_empty()
	return session
