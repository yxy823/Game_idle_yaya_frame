extends GdUnitTestSuite

## E6 public components use real presenters with a manually advanced scheduling clock.

const Composition = preload("res://asset_workbench/examples/effects_composition/example_composition.tscn")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const PlaybackManager = preload("res://components/feedback/feedback_playback_manager.gd")
const TimelinePlayer = preload("res://components/feedback/feedback_timeline_player.gd")
const DIRECTORY: String = "res://tests/features/asset_feedback_timeline/"

var _scene: Control
var _manager: PlaybackManager
var _player: TimelinePlayer
var _issues: Array[String] = []
var _owned: Array[String] = []


func before_test() -> void:
	_scene = auto_free(Composition.instantiate())
	add_child(_scene)
	for object: ObjectView in _scene.objects:
		object.preview(_motion_cue())
	_manager = auto_free(PlaybackManager.new())
	add_child(_manager)
	_manager.set_process(false)
	_player = auto_free(TimelinePlayer.new())
	add_child(_player)
	_player.playback_issue.connect(func(message: String) -> void: _issues.append(message))
	_issues.clear()
	# Original sample emitters replaced by the pure-motion fixtures are released at frame end.
	await get_tree().process_frame


func after_test() -> void:
	if is_instance_valid(_player):
		_player.stop()
	if is_instance_valid(_manager):
		_manager.stop_all()
	if is_instance_valid(_scene):
		_scene.stop()
	for path: String in _owned:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_owned.clear()
	await get_tree().process_frame


func test_saved_definition_round_trip_and_running_snapshot_are_independent() -> void:
	var definition := _timeline([
		_clip("GroupA/Core", 0.0, 0.5), _clip("GroupB/Core", 0.5, 0.5)], 1.0)
	var path := DIRECTORY + "test-timeline-roundtrip.tres"
	_owned.append(path)
	assert_int(ResourceSaver.save(definition, path)).is_equal(OK)
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as FeedbackTimeline
	assert_object(loaded).is_not_null()
	assert_str(loaded.validation_error()).is_empty()
	assert_int(loaded.clips.size()).is_equal(2)
	assert_str(String(loaded.clips[1].target)).is_equal("GroupB/Core")
	assert_float(loaded.clips[1].start_seconds).is_equal(0.5)
	_start(loaded)
	loaded.length_seconds = 0.1
	loaded.clips[1].target = NodePath("GroupB/World")
	loaded.clips.clear()
	_player.advance(0.5)
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()
	assert_bool(_object("GroupB/Core").presenter.is_playing()).is_true()
	assert_bool(_object("GroupB/World").presenter.is_playing()).is_false()
	assert_bool(_player.is_playing()).is_true()
	assert_str(String(definition.clips[1].target)).is_equal("GroupB/Core")


func test_validation_rejects_overlap_but_allows_touching_and_parallel_windows() -> void:
	var definition := _timeline([
		_clip("GroupA/Core", 0.0, 0.5), _clip("GroupA/Core", 0.5, 0.5),
		_clip("GroupB/Core", 0.0, 1.0)], 1.0)
	assert_str(definition.validation_error()).is_empty()
	definition.clips[1].start_seconds = 0.4
	assert_str(definition.validation_error()).contains("Overlapping")
	definition.clips[1].start_seconds = 0.5
	definition.clips[1].duration_seconds = 0.6
	assert_str(definition.validation_error()).contains("ends after")
	definition.clips[1].duration_seconds = 0.5
	definition.clips[1].target = NodePath("../outside")
	assert_str(definition.validation_error()).contains("below the composition")
	definition.clips[1].target = NodePath("%Core")
	assert_str(definition.validation_error()).contains("below the composition")
	definition.clips[1].target = NodePath("GroupA/Core:position")
	assert_str(definition.validation_error()).contains("relative object")
	definition.clips[1].target = NodePath("GroupA/Core")
	definition.clips[1].start_seconds = NAN
	assert_str(definition.validation_error()).contains("finite")


func test_sequential_boundary_releases_before_admitting_next_parallel_pair() -> void:
	_manager.max_active = 2
	_start(_timeline([
		_clip("GroupA/Core", 0.0, 0.5), _clip("GroupB/Core", 0.0, 1.0),
		_clip("GroupA/Core", 0.5, 0.5)], 1.0))
	assert_int(_manager.active_count()).is_equal(2)
	var revision := _object("GroupA/Core").presenter.playback_revision()
	_player.advance(0.5)
	assert_int(_manager.active_count()).is_equal(2)
	assert_int(_object("GroupA/Core").presenter.playback_revision()).is_greater(revision)
	assert_bool(_object("GroupB/Core").presenter.is_playing()).is_true()
	assert_int(_issues.size()).is_zero()
	_player.advance(0.5)
	assert_bool(_player.is_playing()).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()
	assert_bool(_object("GroupB/Core").presenter.is_playing()).is_false()


func test_late_frame_skips_closed_windows_and_starts_only_still_open_windows() -> void:
	var missed := _object("GroupA/Local").presenter
	var revision := missed.playback_revision()
	_start(_timeline([
		_clip("GroupA/Core", 0.0, 0.1), _clip("GroupA/Local", 0.2, 0.2),
		_clip("GroupB/Core", 0.5, 0.4)], 1.0))
	_player.advance(0.6)
	assert_int(missed.playback_revision()).is_equal(revision)
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()
	assert_bool(_object("GroupB/Core").presenter.is_playing()).is_true()
	assert_int(_manager.active_count()).is_equal(1)
	_player.advance(0.4)
	assert_int(_manager.active_count()).is_zero()
	assert_bool(_player.is_playing()).is_false()


func test_loop_stall_does_not_replay_missed_cycles_and_stop_is_final() -> void:
	var ended: Array[String] = []
	_manager.handle_ended.connect(func(_handle: int, reason: String) -> void: ended.append(reason))
	var missed := _object("GroupB/Core").presenter
	var revision := missed.playback_revision()
	_start(_timeline([
		_clip("GroupA/Core", 0.0, 0.5), _clip("GroupB/Core", 0.7, 0.2)], 1.0), true)
	_player.advance(3.25)
	assert_float(_player.position_seconds).is_equal(0.25)
	assert_bool(_player.looping).is_true()
	assert_int(ended.size()).is_equal(1)
	assert_int(missed.playback_revision()).is_equal(revision)
	assert_int(_manager.active_count()).is_equal(1)
	_player.stop()
	_player.advance(10.0)
	assert_bool(_player.is_playing()).is_false()
	assert_bool(_player.looping).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()


func test_invalid_new_request_leaves_current_run_untouched() -> void:
	_start(_timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0))
	_player.advance(0.25)
	var revision := _object("GroupA/Core").presenter.playback_revision()
	var invalid := _timeline([_clip("Missing", 0.0, 1.0)], 1.0)
	assert_str(_player.play(invalid, _scene, _manager)).contains("unavailable")
	assert_bool(_player.is_playing()).is_true()
	assert_float(_player.position_seconds).is_equal(0.25)
	assert_int(_object("GroupA/Core").presenter.playback_revision()).is_equal(revision)
	_player.advance(-1.0)
	_player.advance(NAN)
	assert_float(_player.position_seconds).is_equal(0.25)
	assert_int(_manager.active_count()).is_equal(1)


func test_budget_rejection_and_preemption_leave_all_cues_unchanged() -> void:
	_manager.max_active = 1
	var snapshots: Array[FeedbackCue] = []
	for object: ObjectView in _scene.objects:
		snapshots.append(object.cue.trial_copy())
	_start(_timeline([
		_clip("GroupA/Core", 0.0, 1.0), _clip("GroupA/Local", 0.0, 1.0),
		_clip("GroupA/World", 0.0, 1.0, 2)], 1.0))
	assert_int(_issues.size()).is_equal(1)
	assert_str(_issues[0]).contains("GroupA/Local")
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()
	assert_bool(_object("GroupA/Local").presenter.is_playing()).is_false()
	assert_bool(_object("GroupA/World").presenter.is_playing()).is_true()
	assert_int(_manager.active_count()).is_equal(1)
	_object("GroupA/World").presenter.stop()
	_player.advance(0.1)
	assert_int(_manager.active_count()).is_zero()
	assert_int(_issues.size()).is_equal(1)
	for index: int in _scene.objects.size():
		assert_bool(_scene.objects[index].cue.same_values(snapshots[index])).is_true()


func test_direct_playback_takeover_survives_old_timeline_stop() -> void:
	_start(_timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0))
	var presenter := _object("GroupA/Core").presenter
	presenter.trigger()
	var manual_revision := presenter.playback_revision()
	_player.stop()
	assert_int(presenter.playback_revision()).is_equal(manual_revision)
	assert_bool(presenter.is_playing()).is_true()
	assert_int(_manager.active_count()).is_zero()


func test_detaching_player_cancels_its_handles_and_keeps_other_manager_group() -> void:
	var independent := _object("GroupB/Core").presenter
	var other_handle := _manager.request(independent, &"independent", 0)
	assert_int(other_handle).is_greater(0)
	_start(_timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0), true)
	remove_child(_player)
	assert_bool(_player.is_playing()).is_false()
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()
	assert_bool(_manager.is_active(other_handle)).is_true()
	assert_bool(independent.is_playing()).is_true()
	# Detachment is the assertion subject; the fixture still owns and must release the node.
	_player.free()
	_player = null


func test_missing_future_target_reports_failure_and_cancels_remaining_owned_effects() -> void:
	_start(_timeline([
		_clip("GroupB/Core", 0.0, 1.0), _clip("GroupA/Core", 0.5, 0.5)], 1.0))
	var group := _scene.get_node("GroupA")
	_scene.remove_child(group)
	group.queue_free()
	_player.advance(0.5)
	assert_bool(_player.is_playing()).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_bool(_object("GroupB/Core").presenter.is_playing()).is_false()
	assert_int(_issues.size()).is_equal(1)
	assert_str(_issues[0]).contains("GroupA/Core")
	await get_tree().process_frame


func test_detaching_target_root_ends_run_without_restarting_detached_objects() -> void:
	_start(_timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0), true)
	var presenter := _object("GroupA/Core").presenter
	remove_child(_scene)
	_player.advance(0.25)
	assert_bool(_player.is_playing()).is_false()
	assert_bool(presenter.is_playing()).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_int(_issues.size()).is_equal(1)
	assert_str(_issues[0]).contains("left the scene")
	_scene.free()
	_scene = null


func test_each_window_uses_current_target_cue_without_rebinding_other_targets() -> void:
	_start(_timeline([_clip("GroupA/Core", 0.5, 0.5)], 1.0))
	var object := _object("GroupA/Core")
	var original := _object("GroupB/Core").cue.trial_copy()
	var current := _motion_cue()
	current.tween_distance = 51.0
	object.preview(current)
	_player.advance(0.5)
	assert_bool(object.presenter.is_playing()).is_true()
	assert_bool(object.cue.same_values(current)).is_true()
	assert_bool(_object("GroupB/Core").cue.same_values(original)).is_true()
	assert_bool(_object("GroupB/Core").presenter.is_playing()).is_false()


func test_state_notification_can_stop_idempotently_before_any_clip_starts() -> void:
	var notifications: Array[int] = [0]
	var revision := _object("GroupA/Core").presenter.playback_revision()
	_player.state_changed.connect(func() -> void:
		notifications[0] += 1
		_player.stop())
	_start(_timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0))
	assert_int(notifications[0]).is_equal(2)
	assert_bool(_player.is_playing()).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_int(_object("GroupA/Core").presenter.playback_revision()).is_equal(revision)
	_player.stop()
	assert_int(notifications[0]).is_equal(2)


func test_handle_end_listener_can_stop_loop_but_cannot_reenter_play() -> void:
	var definition := _timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0)
	var replies: Array[String] = []
	_start(definition, true)
	_manager.handle_ended.connect(func(_handle: int, _reason: String) -> void:
		_player.stop()
		replies.append(_player.play(definition, _scene, _manager)))
	_player.advance(1.0)
	assert_int(replies.size()).is_equal(1)
	assert_str(replies[0]).contains("defer")
	assert_bool(_player.is_playing()).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()


func test_stop_from_old_handle_notification_cancels_replacement_before_it_starts() -> void:
	_start(_timeline([_clip("GroupA/Core", 0.0, 1.0)], 1.0))
	var replacement := _timeline([_clip("GroupB/Core", 0.0, 1.0)], 1.0)
	var revision := _object("GroupB/Core").presenter.playback_revision()
	_manager.handle_ended.connect(func(_handle: int, _reason: String) -> void:
		_player.stop(), CONNECT_ONE_SHOT)
	assert_str(_player.play(replacement, _scene, _manager)).contains("cancelled")
	assert_bool(_player.is_playing()).is_false()
	assert_int(_manager.active_count()).is_zero()
	assert_int(_object("GroupB/Core").presenter.playback_revision()).is_equal(revision)
	assert_bool(_object("GroupA/Core").presenter.is_playing()).is_false()


func _start(definition: FeedbackTimeline, repeat: bool = false) -> void:
	assert_str(_player.play(definition, _scene, _manager, repeat)).is_empty()
	# Production uses automatic process; only this fixture supplies manual time instead.
	_player.set_process(false)


func _object(path: String) -> ObjectView:
	return _scene.object_at(path)


func _motion_cue() -> FeedbackCue:
	var cue := FeedbackCue.new()
	cue.tween_enabled = true
	cue.tween_seconds = 3.0
	return cue


func _timeline(clips: Array[FeedbackTimelineClip], length_seconds: float) -> FeedbackTimeline:
	var definition := FeedbackTimeline.new()
	definition.length_seconds = length_seconds
	definition.clips = clips
	return definition


func _clip(target: String, start: float, duration: float, priority: int = 0) -> FeedbackTimelineClip:
	var clip := FeedbackTimelineClip.new()
	clip.target = NodePath(target)
	clip.start_seconds = start
	clip.duration_seconds = duration
	clip.priority = priority
	return clip
