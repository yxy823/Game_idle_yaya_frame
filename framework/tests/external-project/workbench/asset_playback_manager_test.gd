extends GdUnitTestSuite

## E5: target leases must not cancel later manual playback or lose pending audio.

const Manager = preload("res://components/feedback/feedback_playback_manager.gd")
const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const SOUND = preload("res://yaya/asset_workbench/examples/assets/example_confirmation_a.ogg")


func test_group_cancel_and_handle_cancel_leave_other_targets_and_direct_playback() -> void:
	var manager := _manager()
	var left := _presenter()
	var right := _presenter()
	var direct := _presenter()
	var first := manager.request(left, &"left")
	var second := manager.request(right, &"right")
	direct.trigger()
	manager.cancel_group(&"left")
	assert_bool(manager.is_active(first)).is_false()
	assert_bool(manager.is_active(second)).is_true()
	assert_bool(left.is_playing()).is_false()
	assert_bool(right.is_playing()).is_true()
	assert_bool(direct.is_playing()).is_true()
	manager.cancel(first)
	manager.cancel(second)
	assert_int(manager.active_count()).is_zero()
	assert_bool(direct.is_playing()).is_true()


func test_budget_rejects_equal_priority_and_preempts_oldest_lowest_priority() -> void:
	var manager := _manager(3)
	var ends: Dictionary[int, String] = {}
	var rejected: Array[String] = []
	manager.handle_ended.connect(func(handle: int, reason: String) -> void: ends[handle] = reason)
	manager.request_rejected.connect(func(reason: String) -> void: rejected.append(reason))
	var first := manager.request(_presenter(), &"", 1)
	var second := manager.request(_presenter(), &"", 1)
	var high := manager.request(_presenter(), &"", 5)
	var candidate := _presenter()
	assert_int(manager.request(candidate, &"", 1)).is_zero()
	assert_bool(candidate.is_playing()).is_false()
	assert_int(rejected.size()).is_equal(1)
	var admitted := manager.request(candidate, &"", 2)
	assert_bool(admitted > 0).is_true()
	assert_str(ends[first]).is_equal("preempted")
	assert_bool(manager.is_active(second)).is_true()
	assert_bool(manager.is_active(high)).is_true()
	assert_int(manager.active_count()).is_equal(3)


func test_same_target_replacement_keeps_one_lease_and_old_handle_is_harmless() -> void:
	var manager := _manager(1)
	var target := _presenter()
	var first := manager.request(target, &"old", 5)
	var second := manager.request(target, &"new", 0)
	assert_bool(second > first).is_true()
	assert_bool(manager.is_active(first)).is_false()
	manager.cancel(first)
	manager.cancel_group(&"old")
	assert_bool(manager.is_active(second)).is_true()
	assert_bool(target.is_playing()).is_true()
	assert_int(manager.active_count()).is_equal(1)


func test_delayed_audio_reserves_capacity_until_it_really_finishes() -> void:
	var manager := _manager(1)
	var target := _audio_presenter(0.15)
	var starts: Array[int] = []
	var reasons: Array[String] = []
	target.sound_started.connect(func() -> void: starts.append(1))
	manager.handle_ended.connect(func(_handle: int, reason: String) -> void: reasons.append(reason))
	var handle := manager.request(target)
	assert_bool(manager.is_active(handle)).is_true()
	assert_int(target.active_voice_count()).is_zero()
	assert_int(target.pending_audio_count()).is_equal(1)
	assert_int(manager.request(_presenter())).is_zero()
	await get_tree().create_timer(0.2).timeout
	assert_int(starts.size()).is_equal(1)
	assert_int(target.pending_audio_count()).is_zero()
	await get_tree().create_timer(SOUND.get_length() + 0.2).timeout
	assert_bool(manager.is_active(handle)).is_false()
	assert_array(reasons).contains_exactly(["completed"])


func test_cancel_during_audio_delay_leaves_no_late_sound_or_pending_count() -> void:
	var manager := _manager()
	var target := _audio_presenter(0.15)
	var starts: Array[int] = []
	target.sound_started.connect(func() -> void: starts.append(1))
	manager.cancel(manager.request(target))
	assert_int(target.pending_audio_count()).is_zero()
	await get_tree().create_timer(0.25).timeout
	assert_array(starts).is_empty()
	assert_int(target.active_voice_count()).is_zero()
	assert_int(manager.active_count()).is_zero()


func test_manual_takeover_preserves_subsequent_direct_audio_overlap() -> void:
	var manager := _manager()
	var target := _audio_presenter(0.0)
	var handle := manager.request(target)
	assert_int(target.active_voice_count()).is_equal(1)
	target.trigger()
	assert_int(target.active_voice_count()).is_equal(1)
	target.trigger()
	assert_int(target.active_voice_count()).is_equal(2)
	manager.cancel(handle)
	assert_int(target.active_voice_count()).is_equal(2)
	assert_int(manager.active_count()).is_zero()
	target.stop()


func test_direct_delayed_overlap_and_new_generation_have_independent_pending_counts() -> void:
	var target := _audio_presenter(0.15)
	var starts: Array[int] = []
	target.sound_started.connect(func() -> void: starts.append(1))
	target.trigger()
	target.trigger()
	assert_int(target.pending_audio_count()).is_equal(2)
	await get_tree().create_timer(0.2).timeout
	assert_int(starts.size()).is_equal(2)
	assert_int(target.pending_audio_count()).is_zero()
	target.trigger()
	target.stop()
	target.trigger()
	assert_int(target.pending_audio_count()).is_equal(1)
	await get_tree().create_timer(0.2).timeout
	assert_int(starts.size()).is_equal(3)
	assert_int(target.pending_audio_count()).is_zero()
	target.stop()


func test_empty_cue_completes_without_consuming_capacity_or_creating_fallback_effects() -> void:
	var manager := _manager(1)
	var target := _presenter()
	target.configure(FeedbackCue.new())
	var handle := manager.request(target)
	assert_bool(handle > 0).is_true()
	assert_bool(manager.is_active(handle)).is_false()
	assert_int(manager.active_count()).is_zero()
	assert_bool(target.is_playing()).is_false()
	assert_bool(manager.request(_presenter()) > 0).is_true()


func test_external_stop_configure_and_second_manager_invalidate_old_ownership() -> void:
	var manager := _manager()
	var other := _manager()
	var target := _presenter()
	var first := manager.request(target)
	var second := other.request(target)
	manager.cancel(first)
	assert_bool(other.is_active(second)).is_true()
	target.configure(_motion_cue())
	target.trigger()
	other.cancel(second)
	assert_bool(target.is_playing()).is_true()
	var third := manager.request(target)
	target.stop()
	assert_bool(manager.is_active(third)).is_false()
	assert_bool(target.is_playing()).is_false()


func test_target_and_manager_tree_exit_cancel_owned_playback_immediately() -> void:
	var manager := _manager()
	var target := _presenter()
	var first := manager.request(target)
	remove_child(target)
	assert_bool(target.is_playing()).is_false()
	assert_bool(manager.is_active(first)).is_false()
	add_child(target)
	var second := manager.request(target)
	remove_child(manager)
	assert_bool(target.is_playing()).is_false()
	assert_bool(manager.is_active(second)).is_false()
	add_child(manager)
	assert_bool(manager.request(target) > 0).is_true()


func test_invalid_detached_and_queued_targets_are_rejected_without_displacing_active_work() -> void:
	var manager := _manager(1)
	var valid := manager.request(_presenter())
	var invalid := _presenter()
	var cue := _motion_cue()
	cue.tween_seconds = NAN
	invalid.configure(cue)
	assert_int(manager.request(invalid, &"", 10)).is_zero()
	assert_bool(manager.is_active(valid)).is_true()
	# 优先级高于现有播放，拒绝只能来自目标本身无效，不是预算已满。
	var detached := Presenter.new()
	assert_int(manager.request(detached, &"", 10)).is_zero()
	detached.free()
	var queued := _presenter()
	queued.queue_free()
	assert_int(manager.request(queued, &"", 10)).is_zero()
	assert_bool(manager.is_active(valid)).is_true()
	assert_int(manager.request(null)).is_zero()
	await get_tree().process_frame


func test_free_before_tree_entry_releases_every_constructed_component() -> void:
	var baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var target := Presenter.new()
	assert_bool(target.is_inside_tree()).is_false()
	var constructed := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	assert_bool(constructed > baseline).is_true()
	target.free()
	assert_int(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))).is_equal(baseline)


func test_start_notification_can_stop_pending_admission_without_late_playback() -> void:
	var manager := _manager()
	var target := _audio_presenter(0.0)
	target.sound_started.connect(manager.stop_all)
	assert_int(manager.request(target)).is_zero()
	assert_int(manager.active_count()).is_zero()
	assert_bool(target.is_playing()).is_false()
	assert_str(manager.last_error).contains("cancelled or superseded")


func test_start_notification_manual_takeover_is_not_mistaken_for_managed_revision() -> void:
	var manager := _manager()
	var target := _audio_presenter(0.0)
	var once: Array[bool] = [false]
	target.sound_started.connect(func() -> void:
		if not once[0]:
			once[0] = true
			target.trigger())
	assert_int(manager.request(target)).is_zero()
	assert_int(manager.active_count()).is_zero()
	assert_int(target.active_voice_count()).is_equal(1)
	manager.stop_all()
	assert_int(target.active_voice_count()).is_equal(1)
	target.stop()


func test_reentrant_admission_is_rejected_while_cancellation_remains_available() -> void:
	var manager := _manager(1)
	var replacement := _presenter()
	var nested_target := _presenter()
	var nested: Array[int] = []
	manager.request(_presenter())
	manager.handle_ended.connect(func(_handle: int, _reason: String) -> void:
		nested.append(manager.request(nested_target, &"", 100)))
	var handle := manager.request(replacement, &"", 1)
	assert_bool(handle > 0).is_true()
	assert_array(nested).contains_exactly([0])
	assert_int(manager.active_count()).is_equal(1)
	manager.stop_all()
	assert_int(manager.active_count()).is_zero()


func _manager(limit: int = 8) -> Manager:
	var manager: Manager = auto_free(Manager.new())
	manager.max_active = limit
	add_child(manager)
	return manager


func _motion_cue() -> FeedbackCue:
	var cue := FeedbackCue.new()
	cue.tween_enabled = true
	cue.tween_seconds = 1.0
	return cue


func _presenter() -> Presenter:
	var target: Presenter = auto_free(Presenter.new())
	add_child(target)
	target.configure(_motion_cue())
	return target


func _audio_presenter(delay_seconds: float) -> Presenter:
	var target := _presenter()
	var cue := FeedbackCue.new()
	cue.sound = SOUND
	cue.delay_seconds = delay_seconds
	target.configure(cue)
	return target
