extends GdUnitTestSuite

## E6 entry-point integration; the audio wait proves cancelled delays cannot play later.

const Workbench = preload("res://yaya/asset_workbench/examples/effects_composition/example_workbench.tscn")
const Consumer = preload("res://yaya/asset_workbench/examples/effects_composition/example_consumer.tscn")
const CompositionPanel = preload("res://yaya/asset_workbench/ui/composition_panel.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const SOUND = preload("res://yaya/asset_workbench/examples/assets/example_confirmation_a.ogg")


func test_workbench_uses_current_trial_and_stop_cancels_loop_and_delayed_audio() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: CompositionPanel = workbench.get("_composition")
	_prepare_workbench_trials(panel)
	var session := panel.sessions["GroupA/Core"]
	session.drafts[1].sound = SOUND
	session.drafts[1].delay_seconds = 0.25
	session.drafts[1].tween_distance = 51.0
	session.active_index = 1
	panel.select_object("GroupA/Core")
	var saved_a := session.drafts[0].trial_copy()
	var saved_b := session.drafts[1].trial_copy()
	var played: Array[int] = [0]
	var presenter := panel.current_object().presenter
	presenter.sound_started.connect(func() -> void: played[0] += 1)
	(panel.get("_timeline_repeat") as CheckButton).button_pressed = true
	panel.play_timeline()
	panel.stage.timeline_player.set_process(false)
	assert_bool(panel.stage.timeline_player.looping).is_true()
	assert_str(panel.get("_timeline_state").text).contains("循环播放")
	assert_bool(panel.current_object().cue.same_values(saved_b)).is_true()
	assert_int(presenter.pending_audio_count()).is_equal(1)
	workbench.call("stop_all")
	assert_bool(panel.stage.timeline_player.is_playing()).is_false()
	assert_int(presenter.pending_audio_count()).is_zero()
	await get_tree().create_timer(0.35).timeout
	assert_int(played[0]).is_zero()
	assert_int(presenter.active_voice_count()).is_zero()
	assert_bool(session.drafts[0].same_values(saved_a)).is_true()
	assert_bool(session.drafts[1].same_values(saved_b)).is_true()
	await _check_trial_switch_stops_timeline(workbench, panel)


func test_native_consumer_exposes_managed_groups_without_workbench_dependencies() -> void:
	var consumer: Control = auto_free(Consumer.instantiate())
	add_child(consumer)
	for object: ObjectView in consumer.objects:
		object.preview(_motion_cue())
	assert_int(consumer.objects.size()).is_equal(6)
	assert_int(consumer.manager.max_active).is_equal(3)
	consumer.call("_play_group", "GroupA", &"group_a", 0)
	assert_int(consumer.manager.active_count()).is_equal(3)
	consumer.call("_play_group", "GroupB", &"group_b", 1)
	assert_int(consumer.manager.active_count()).is_equal(3)
	for object: ObjectView in consumer.objects:
		assert_bool(object.presenter.is_playing()).is_equal(
			String(consumer.get_path_to(object)).begins_with("GroupB/"))
	consumer.manager.cancel_group(&"group_a")
	assert_int(consumer.manager.active_count()).is_equal(3)
	assert_str(consumer.play_timeline(true)).is_empty()
	consumer.timeline_player.set_process(false)
	assert_bool(consumer.timeline_player.looping).is_true()
	consumer.stop()
	assert_bool(consumer.timeline_player.is_playing()).is_false()
	assert_int(consumer.manager.active_count()).is_zero()
	await get_tree().process_frame


func _prepare_workbench_trials(panel: CompositionPanel) -> void:
	for path: String in panel.sessions:
		panel.sessions[path].drafts[0] = _motion_cue()
		panel.sessions[path].drafts[1] = _motion_cue()
		panel.update_trial(path)


func _check_trial_switch_stops_timeline(workbench: Control, panel: CompositionPanel) -> void:
	panel.play_timeline()
	panel.stage.timeline_player.set_process(false)
	workbench.call("_select_alternative", 0)
	assert_bool(panel.stage.timeline_player.is_playing()).is_false()
	assert_int(panel.stage.manager.active_count()).is_zero()
	assert_int(panel.sessions["GroupA/Core"].active_index).is_zero()
	panel.play_timeline()
	panel.stage.timeline_player.set_process(false)
	panel.select_all_alternatives(1)
	assert_bool(panel.stage.timeline_player.is_playing()).is_false()
	assert_int(panel.stage.manager.active_count()).is_zero()
	for path: String in panel.sessions:
		assert_int(panel.sessions[path].active_index).is_equal(1)
	workbench.call("stop_all")
	await get_tree().process_frame


func _motion_cue() -> FeedbackCue:
	var cue := FeedbackCue.new()
	cue.tween_enabled = true
	cue.tween_seconds = 3.0
	return cue
