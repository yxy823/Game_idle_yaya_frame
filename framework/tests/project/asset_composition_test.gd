extends GdUnitTestSuite

const Workbench = preload("res://examples/asset_workbench/composition/example-workbench.tscn")
const Composition = preload("res://examples/asset_workbench/composition/example-composition.tscn")
const Session = preload("res://tools/asset_workbench/preview_session.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")

var _workbench: Control
var _panel: Control
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


func test_object_click_selects_real_instance_and_preserves_each_trial() -> void:
	var objects: Array = _panel.stage.objects
	assert_int(objects.size()).is_equal(3)
	objects[0].pressed.emit()
	assert_str(_workbench.cue_path).is_equal(objects[0].cue_path)
	_workbench.session.current().icon_scale = 1.6
	_workbench.call("_refresh")
	assert_float(objects[0].cue.icon_scale).is_equal(1.6)
	objects[1].pressed.emit()
	assert_float(_workbench.session.current().icon_scale).is_equal(0.8)
	objects[0].pressed.emit()
	assert_float(_workbench.session.current().icon_scale).is_equal(1.6)
	assert_str(_workbench.get("_target").text).contains(objects[0].cue_path)
	assert_object(_workbench.presenter).is_same(objects[0].presenter)
	assert_bool(_panel.has_method("_return_original")).is_false()
	assert_bool(_workbench.has_method("_fit_workspace")).is_false()


func test_batch_gain_updates_only_active_trials_and_keeps_assets_unmodified() -> void:
	var paths: Array = _panel.sessions.keys()
	var source := FileAccess.get_file_as_string(paths[0])
	var session: Session = _panel.sessions[paths[0]]
	var texture := session.saved.texture
	var sound := session.saved.sound
	_panel.call("apply_gain", -25.0)
	for current: Session in _panel.sessions.values():
		assert_float(current.current().gain_db).is_equal(-25.0)
		assert_float(current.drafts[1].gain_db).is_equal(-18.0)
		assert_object(current.drafts[1].sound).is_not_same(current.drafts[0].sound)
		assert_bool(current.is_dirty()).is_true()
	assert_object(session.current().texture).is_same(texture)
	assert_object(session.current().sound).is_same(sound)
	assert_str(FileAccess.get_file_as_string(paths[0])).is_equal(source)
	_panel.call("apply_gain", NAN)
	assert_float(session.current().gain_db).is_equal(-25.0)


func test_scene_resources_are_deduplicated_and_forwarded_to_existing_batch() -> void:
	var path: String = _panel.sessions.keys()[0]
	_panel.call("select_object", path)
	assert_int(_panel.call("assets", true).size()).is_equal(2)
	var assets: Array[Resource] = _panel.call("assets", false)
	assert_int(assets.size()).is_equal(4)
	_panel.analysis_requested.emit(assets)
	var batch: Node = _workbench.get("_batch").batch
	assert_int(batch.group.assets.size()).is_equal(4)
	assert_object(batch.service).is_same(_workbench.get("_analysis").service)
	_workbench.get("_batch").call("_close")


func test_save_all_reports_conflict_and_game_object_reads_saved_resource() -> void:
	var sessions: Dictionary[String, Session] = {}
	for index: int in 2:
		var path := "res://reports/asset-analyzer/composition-%d-%d.tres" % [
			Time.get_ticks_usec(), index]
		_owned.append(path)
		var original: Session = _panel.sessions.values()[index]
		ResourceSaver.save(original.saved.trial_copy(), path)
		var session := Session.new()
		assert_str(session.open(path)).is_empty()
		session.current().gain_db = -23
		sessions[path] = session
	var conflict_path: String = sessions.keys()[1]
	var file := FileAccess.open(conflict_path, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_string("\n; external edit\n")
	file.close()
	_panel.sessions = sessions
	_panel.call("save_all")
	assert_str(_panel.get("_status").text).contains("Saved 1/2")
	assert_str(_panel.get("_status").text).contains("File changed on disk")
	assert_bool(sessions[conflict_path].is_dirty()).is_true()
	var object: ObjectView = auto_free(ObjectView.new())
	object.cue_path = sessions.keys()[0]
	add_child(object)
	assert_float(object.cue.gain_db).is_equal(-23.0)


func test_scene_trigger_and_stop_use_existing_playback_and_clear_delays() -> void:
	_panel.stage.trigger_all()
	await get_tree().create_timer(0.23).timeout
	var voices: int = 0
	for object: ObjectView in _panel.stage.objects:
		voices += object.presenter.active_voice_count()
	assert_int(voices).is_greater(0)
	_workbench.call("stop_all")
	for object: ObjectView in _panel.stage.objects:
		assert_int(object.presenter.active_voice_count()).is_equal(0)
		assert_int(object.presenter.active_effect_count()).is_equal(0)


func test_composition_stop_button_cancels_repeat_audition_and_delayed_audio() -> void:
	var objects: Array = _panel.stage.objects
	var starts: Array[int] = [0]
	for object: ObjectView in objects:
		object.presenter.sound_started.connect(func() -> void: starts[0] += 1)
	_workbench.session.current().delay_seconds = 0.3
	_workbench.call("_refresh")
	var browser: Control = _workbench.get("_browser")
	browser.call("_select", 2)
	_workbench.call("_start_repeat", 0.1)
	browser.call("_set_repeat", true)
	await get_tree().create_timer(0.15).timeout
	var stop_button: Button
	for node: Node in _panel.find_children("*", "Button", true, false):
		if (node as Button).text == "Stop all":
			stop_button = node as Button
	assert_object(stop_button).is_not_null()
	stop_button.pressed.emit()
	var count_at_stop: int = starts[0]
	await get_tree().create_timer(0.7).timeout
	assert_int(starts[0]).is_equal(count_at_stop)
	for object: ObjectView in objects:
		assert_int(object.presenter.active_voice_count()).is_equal(0)
		assert_int(object.presenter.active_effect_count()).is_equal(0)
	for node: Node in browser.find_children("*", "AudioStreamPlayer", true, false):
		assert_bool((node as AudioStreamPlayer).playing).is_false()
	assert_bool(browser.get("_timer").is_stopped()).is_true()
	assert_bool(_workbench.get("_repeat").is_stopped()).is_true()


func test_composition_is_an_independently_runnable_native_scene() -> void:
	var scene: Control = auto_free(Composition.instantiate())
	add_child(scene)
	assert_int(scene.objects.size()).is_equal(3)
	scene.objects[1].pressed.emit()
	await get_tree().create_timer(0.05).timeout
	assert_int(scene.objects[1].presenter.active_voice_count()).is_greater(0)
	scene.stop()


func test_repeat_targets_current_object_after_selection_changes() -> void:
	var objects: Array = _panel.stage.objects
	objects[1].pressed.emit()
	_workbench.call("_start_repeat", 0.1)
	await get_tree().create_timer(0.24).timeout
	assert_int(objects[1].presenter.active_voice_count()).is_greater(0)
	assert_int(objects[0].presenter.active_voice_count()).is_equal(0)
	objects[2].pressed.emit()
	_workbench.call("_start_repeat", 0.1)
	await get_tree().create_timer(0.24).timeout
	assert_int(objects[2].presenter.active_voice_count()).is_greater(0)
	assert_int(objects[1].presenter.active_voice_count()).is_equal(0)
