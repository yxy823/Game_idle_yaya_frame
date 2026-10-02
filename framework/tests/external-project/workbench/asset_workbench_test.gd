extends GdUnitTestSuite

## Copy this suite into the designated external Godot project, never run in project-source.

const Session = preload("res://tools/asset_workbench/preview_session.gd")
const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const Playback = preload("res://components/feedback/audio_playback.gd")
const Game = preload("res://examples/asset_workbench/single/example_reward_game.gd")
const WorkbenchScene = preload("res://examples/asset_workbench/single/example_workbench.tscn")
const Result = preload("res://tools/asset_workbench/analysis_result.gd")
const CUE_PATH: String = "res://examples/asset_workbench/single/example_feedback.tres"

var _session: Session
var _cue: FeedbackCue
var _fixture_path: String = ""


func before_test() -> void:
	_fixture_path = get_script().resource_path.get_base_dir().path_join(
		"asset-workbench-cue-%d-%d.tres" % [OS.get_process_id(), Time.get_ticks_usec()])
	_cue = ResourceLoader.load(CUE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FeedbackCue
	assert_bool(FileAccess.file_exists(_fixture_path)).is_false()
	assert_int(ResourceSaver.save(_cue.trial_copy(), _fixture_path)).is_equal(OK)
	_session = Session.new()
	assert_str(_session.open(_fixture_path)).is_empty()


func after_test() -> void:
	_session = null
	_cue = null
	if FileAccess.file_exists(_fixture_path):
		assert_int(DirAccess.remove_absolute(_fixture_path)).is_equal(OK)
	assert_bool(FileAccess.file_exists(_fixture_path)).is_false()
	_fixture_path = ""


func test_trials_do_not_mutate_saved_or_other_alternative() -> void:
	_session.current().gain_db = -24.0
	_session.current().texture = load("res://examples/asset_workbench/assets/example_star.png")
	assert_bool(_session.is_dirty()).is_true()
	assert_float(_session.saved.gain_db).is_equal(-12.0)
	assert_float(_session.drafts[1].gain_db).is_equal(-12.0)
	assert_object(_session.saved.texture).is_same(_cue.texture)
	_session.reset_current()
	assert_bool(_session.is_dirty()).is_false()


func test_save_is_reloaded_by_actual_game_consumer() -> void:
	_session.current().gain_db = -21.0
	_session.current().delay_seconds = 0.15
	assert_str(_session.save_current()).is_empty()
	assert_bool(_session.is_dirty()).is_false()
	var game: Game = auto_free(Game.new())
	game.cue_resource = load(_fixture_path) as FeedbackCue
	add_child(game)
	assert_float(game.cue.gain_db).is_equal(-21.0)
	assert_float(game.cue.delay_seconds).is_equal(0.15)
	assert_int(game.reward_count).is_equal(0)
	game.activate_example()
	assert_int(game.reward_count).is_equal(1)
	assert_bool(game.cue.same_values(_session.current())).is_true()


func test_external_edit_blocks_save_and_keeps_trial() -> void:
	var edited := FileAccess.get_file_as_string(_fixture_path) + "\n; external editor change\n"
	var file := FileAccess.open(_fixture_path, FileAccess.WRITE)
	file.store_string(edited)
	file.close()
	_session.current().gain_db = -20.0
	assert_str(_session.save_current()).contains("File changed on disk")
	assert_str(FileAccess.get_file_as_string(_fixture_path)).is_equal(edited)
	assert_float(_session.current().gain_db).is_equal(-20.0)
	assert_bool(_session.is_dirty()).is_true()


func test_invalid_trial_cannot_overwrite_file() -> void:
	var original := FileAccess.get_file_as_string(_fixture_path)
	_session.current().gain_db = NAN
	assert_str(_session.save_current()).is_not_empty()
	assert_str(FileAccess.get_file_as_string(_fixture_path)).is_equal(original)


func test_documented_parameter_boundaries_are_accepted() -> void:
	_cue.animation_seconds = 0.15
	_cue.delay_seconds = 0.6
	_cue.gain_db = -48.0
	_cue.pitch_scale = 0.5
	_cue.icon_scale = 2.0
	assert_str(_cue.validation_error()).is_empty()


func test_stop_invalidates_pending_audio() -> void:
	var presenter: Presenter = auto_free(Presenter.new())
	add_child(presenter)
	var starts: Array[int] = [0]
	presenter.sound_started.connect(func() -> void: starts[0] += 1)
	_cue.delay_seconds = 0.1
	presenter.configure(_cue)
	presenter.trigger()
	presenter.stop()
	await get_tree().create_timer(0.2).timeout
	assert_int(starts[0]).is_equal(0)
	assert_int(presenter.active_effect_count()).is_equal(0)
	assert_int(presenter.active_voice_count()).is_equal(0)


func test_switch_invalidates_old_delay_but_plays_current() -> void:
	var presenter: Presenter = auto_free(Presenter.new())
	add_child(presenter)
	var starts: Array[int] = [0]
	presenter.sound_started.connect(func() -> void: starts[0] += 1)
	_cue.delay_seconds = 0.1
	presenter.configure(_cue)
	presenter.trigger()
	var replacement := _cue.trial_copy()
	replacement.delay_seconds = 0.0
	presenter.configure(replacement)
	presenter.trigger()
	await get_tree().create_timer(0.2).timeout
	assert_int(starts[0]).is_equal(1)
	presenter.stop()


func test_pool_has_bounded_overlap_and_recovers_after_stop() -> void:
	var playback: Playback = auto_free(Playback.new())
	add_child(playback)
	var bus_gain := AudioServer.get_bus_volume_db(0)
	for _index: int in Playback.MAX_VOICES:
		assert_int(playback.play(_cue.sound, -24.0, 1.0, &"Master")).is_equal(OK)
	assert_int(playback.play(_cue.sound, -24.0, 1.0, &"Master")).is_equal(ERR_BUSY)
	playback.stop_all()
	assert_int(playback.active_voice_count()).is_equal(0)
	assert_int(playback.play(_cue.sound, -6.0, 1.0, &"Master")).is_equal(OK)
	assert_float(AudioServer.get_bus_volume_db(0)).is_equal(bus_gain)
	playback.stop_all()


func test_browsing_does_not_bind_until_requested() -> void:
	var workbench: Control = auto_free(WorkbenchScene.instantiate())
	add_child(workbench)
	var lists := workbench.find_children("*", "ItemList", true, false)
	var candidates := lists[0] as ItemList
	candidates.select(3)
	candidates.item_selected.emit(3)
	assert_bool(workbench.session.is_dirty()).is_false()
	_button(workbench, "试听").pressed.emit()
	assert_array(_playing_sound_paths(workbench)).is_equal([
		"res://examples/asset_workbench/assets/example_confirmation_b.ogg"])
	_button(workbench, "应用到对象 A").pressed.emit()
	assert_bool(workbench.session.is_dirty()).is_true()
	assert_str(workbench.session.current().sound.resource_path).ends_with("confirmation_b.ogg")
	assert_str(workbench.session.saved.sound.resource_path).ends_with("confirmation_a.ogg")
	workbench.stop_all()


func test_ab_buttons_restore_trials_and_stop_repeat() -> void:
	var workbench: Control = auto_free(WorkbenchScene.instantiate())
	add_child(workbench)
	workbench.session.current().gain_db = -24.0
	_button(workbench, "B").pressed.emit()
	assert_float(workbench.session.current().gain_db).is_equal(-12.0)
	_button(workbench, "A").pressed.emit()
	assert_float(workbench.session.current().gain_db).is_equal(-24.0)
	_button(workbench, "快速 0.1 s").pressed.emit()
	await get_tree().create_timer(0.25).timeout
	assert_int(workbench.presenter.active_effect_count()).is_greater(1)
	_button(workbench, "停止全部").pressed.emit()
	await get_tree().create_timer(0.2).timeout
	assert_int(workbench.presenter.active_effect_count()).is_equal(0)
	assert_int(workbench.presenter.active_voice_count()).is_equal(0)


func test_example_ab_actually_plays_different_streams_until_copied() -> void:
	var workbench: Control = auto_free(WorkbenchScene.instantiate())
	add_child(workbench)
	_button(workbench, "触发").pressed.emit()
	await get_tree().create_timer(0.12).timeout
	assert_array(_playing_sound_paths(workbench)).is_equal([
		"res://examples/asset_workbench/assets/example_confirmation_a.ogg"])
	_button(workbench, "B").pressed.emit()
	await get_tree().create_timer(0.12).timeout
	assert_array(_playing_sound_paths(workbench)).is_equal([
		"res://examples/asset_workbench/assets/example_confirmation_b.ogg"])
	assert_bool(workbench.session.is_dirty()).is_true()
	workbench.call("_dispatch_action", &"copy")
	_button(workbench, "A").pressed.emit()
	await get_tree().create_timer(0.12).timeout
	assert_array(_playing_sound_paths(workbench)).is_equal([
		"res://examples/asset_workbench/assets/example_confirmation_b.ogg"])
	workbench.stop_all()


func test_inspection_appearance_does_not_change_trials_or_saved_cue() -> void:
	var original := FileAccess.get_file_as_string(CUE_PATH)
	var workbench: Control = auto_free(WorkbenchScene.instantiate())
	add_child(workbench)
	var texture: Texture2D = workbench.session.current().texture
	var alternative_before: FeedbackCue = workbench.session.drafts[1].trial_copy()
	assert_bool(workbench.get_theme_color("font_color", "Label") == Color.BLACK).is_true()
	var appearance: MenuButton = workbench.get("_ui").get("_appearance")
	appearance.get_popup().id_pressed.emit(0)
	appearance.get_popup().id_pressed.emit(1)
	assert_bool(workbench.get_theme_color("font_color", "Label") == Color.WHITE).is_true()
	assert_bool(workbench.session.is_dirty()).is_false()
	assert_bool(workbench.session.drafts[1].same_values(alternative_before)).is_true()
	assert_object(workbench.session.current().texture).is_same(texture)
	assert_str(FileAccess.get_file_as_string(CUE_PATH)).is_equal(original)


func test_candidate_actions_follow_type_and_analysis_does_not_change_trial() -> void:
	var workbench: Control = auto_free(WorkbenchScene.instantiate())
	add_child(workbench)
	var browser: Control = workbench.get("_browser")
	assert_bool(browser.get("_apply").disabled).is_true()
	assert_bool(browser.get("_analyze").disabled).is_true()
	browser.call("_select", 0)
	assert_bool(browser.get("_audition").disabled).is_true()
	assert_bool(browser.get("_apply").disabled).is_false()
	assert_object(browser.get("_list").get_item_icon(0)).is_not_null()
	assert_str(browser.get("_details").text).contains("导入后")
	browser.call("_select", 2)
	assert_bool(browser.get("_audition").disabled).is_false()
	var cue_before: FeedbackCue = workbench.session.current().trial_copy()
	workbench.call("_analyze_object")
	assert_int(workbench.get("_batch").batch.group.assets.size()).is_equal(2)
	assert_bool(workbench.session.current().same_values(cue_before)).is_true()
	workbench.get("_batch").call("_close")


func test_analysis_identity_survives_browsing_and_late_completion() -> void:
	var workbench: Control = auto_free(WorkbenchScene.instantiate())
	add_child(workbench)
	var panel: Window = workbench.get("_analysis")
	panel.call("open_asset", workbench.session.current().sound)
	panel.call("_analyze", 0)
	var deadline := Time.get_ticks_msec() + 15000
	while panel.results[0].is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var result: Dictionary = panel.results[0]
	assert_str(result.get("status", "")).is_equal("success")
	panel.set("_tasks", [987654, 0] as Array[int])
	panel.call("open_results", result, result)
	var path := "res://examples/asset_workbench/assets/example_star.png"
	panel.call("_completed", 987654, Result.failure(path, "image", "cancelled", "old task"))
	assert_str(panel.results[0].asset.path).is_equal(result.asset.path)
	panel.call("open_asset", load(path))
	assert_str(panel.get("_selection_label").text).contains("example_star.png")
	assert_str(panel.get("_summaries")[0].text).contains("example_confirmation_a.ogg")
	assert_str(panel.get("_summaries")[0].text).not_contains("example_star.png")
	assert_str(panel.call("source_status", path)).contains("未分析")
	assert_bool(workbench.session.is_dirty()).is_false()
	panel.call("_close")


func _playing_sound_paths(root: Node) -> Array[String]:
	var paths: Array[String] = []
	for node: Node in root.find_children("*", "AudioStreamPlayer", true, false):
		var player := node as AudioStreamPlayer
		if player.playing and player.stream != null:
			paths.append(player.stream.resource_path)
	return paths


func _button(root: Node, text: String) -> Button:
	for node: Node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == text:
			return button
	assert_bool(false).override_failure_message("Missing button: " + text).is_true()
	return null
