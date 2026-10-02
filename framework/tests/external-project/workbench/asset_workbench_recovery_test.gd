extends GdUnitTestSuite

## E7: run only in the designated external project; fixtures belong to this suite's directory.

const Single = preload("res://examples/asset_workbench/single/example_workbench.tscn")
const Composition = preload("res://examples/asset_workbench/composition/example_workbench.tscn")
const ShaderWorkbench = preload(
	"res://examples/asset_workbench/shader_composition/example_workbench.tscn")
const Effects = preload("res://examples/asset_workbench/effects_composition/example_workbench.tscn")
const BatchPanel = preload("res://tools/asset_workbench/analysis_batch_panel.gd")
const Group = preload("res://tools/asset_workbench/analysis_group.gd")
const Session = preload("res://tools/asset_workbench/preview_session.gd")
const CUE = preload("res://examples/asset_workbench/single/example_feedback.tres")
const IMAGE = preload("res://examples/asset_workbench/assets/example_trophy.png")
const STAR = preload("res://examples/asset_workbench/assets/example_star.png")
const SOUND = preload("res://examples/asset_workbench/assets/example_confirmation_a.ogg")

var _workbenches: Array[Control] = []
var _owned_files: Array[String] = []


func after_test() -> void:
	for workbench: Control in _workbenches:
		workbench.call("stop_all")
		workbench.get("_batch").batch.cancel()
		workbench.get("_analysis").call("_cancel")
	_workbenches.clear()
	for path: String in _owned_files:
		if FileAccess.file_exists(path):
			assert_int(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))).is_equal(OK)
	_owned_files.clear()


func test_four_cold_workbench_entries_return_to_exact_orphan_baseline() -> void:
	for scene: PackedScene in [Single, Composition, ShaderWorkbench, Effects]:
		var baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var workbench := scene.instantiate()
		assert_bool(workbench.is_inside_tree()).is_false()
		workbench.free()
		assert_int(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))) \
			.override_failure_message("Cold release leaked nodes: " + scene.resource_path) \
			.is_equal(baseline)


func test_missing_initial_cue_keeps_collection_and_recovers_after_reload() -> void:
	var workbench := _workbench(Single, _fixture_path("missing-cue.tres"))
	var panel: BatchPanel = workbench.get("_batch")
	assert_object(workbench.session.saved).is_null()
	assert_array(workbench.session.drafts).is_empty()
	assert_str(workbench.get("_status").text).contains("Cue file is missing")
	assert_str(panel.batch.add_paths([STAR.resource_path])).is_empty()
	var members: Array = panel.batch.group.assets.duplicate(true)
	for _attempt: int in 2:
		workbench.call("_analyze_object")
		assert_str(workbench.get("_status").text).contains("尚未加载有效 Cue")
		assert_array(panel.batch.group.assets).is_equal(members)
		assert_bool(panel.visible).is_false()
	_assert_candidate_tools_available(workbench)
	var fixed_path := _save_cue(CUE.trial_copy())
	workbench.cue_path = fixed_path
	workbench.call("_load_session")
	assert_object(workbench.session.saved).is_not_null()
	assert_int(workbench.session.drafts.size()).is_equal(2)
	assert_str(workbench.get("_state").text).is_equal("与已保存 Cue 一致")
	workbench.call("_analyze_object")
	assert_int(panel.batch.group.assets.size()).is_equal(3)
	assert_str(panel.get("_notice").text).contains("本次新增 2 个源文件")
	assert_bool(workbench.session.is_dirty()).is_false()


func test_missing_initial_cue_does_not_start_trigger_or_repeat() -> void:
	var workbench := _workbench(Single, _fixture_path("missing-playback-cue.tres"))
	workbench.call("_trigger_once")
	assert_str(workbench.get("_status").text).contains("尚未加载有效 Cue")
	workbench.call("_start_repeat", 0.1)
	assert_str(workbench.get("_status").text).contains("尚未加载有效 Cue")
	assert_bool(workbench.get("_repeat").is_stopped()).is_true()
	assert_int(workbench.presenter.active_effect_count()).is_zero()
	assert_int(workbench.presenter.active_voice_count()).is_zero()


func test_saved_atlas_cue_reports_only_its_analyzable_sound_without_mutation() -> void:
	var cue: FeedbackCue = CUE.trial_copy()
	cue.texture = _saved_atlas()
	var path := _save_cue(cue)
	var original := FileAccess.get_file_as_string(path)
	var workbench := _workbench(Single, path)
	var trial_before: FeedbackCue = workbench.session.current().trial_copy()
	var alternative: FeedbackCue = workbench.session.drafts[1].trial_copy()
	assert_bool(workbench.session.current().texture is AtlasTexture).is_true()
	var panel: BatchPanel = workbench.get("_batch")
	workbench.call("_analyze_object")
	assert_array(panel.batch.group.assets).is_equal([
		{"path": SOUND.resource_path, "type": "audio"}])
	assert_str(panel.get("_notice").text).contains("本次新增 1 个源文件；已在集合 0 个；跳过 1 项")
	assert_str(panel.get("_notice").text).contains("indirect texture")
	assert_str(panel.get("_notice").text).contains(cue.texture.resource_path)
	assert_bool(workbench.session.current().same_values(trial_before)).is_true()
	assert_bool(workbench.session.drafts[1].same_values(alternative)).is_true()
	assert_bool(workbench.session.is_dirty()).is_false()
	assert_str(FileAccess.get_file_as_string(path)).is_equal(original)


func test_candidate_collection_reports_real_additions_duplicates_and_source_rejections() -> void:
	var workbench := _workbench()
	var panel: BatchPanel = workbench.get("_batch")
	var browser: Control = workbench.get("_browser")
	var atlas := _saved_atlas()
	var unsupported := _unsupported_svg()
	var textures: Array[Texture2D] = [IMAGE, IMAGE, atlas, unsupported]
	var sounds: Array[AudioStream] = [SOUND]
	browser.call("populate", textures, sounds)
	var trial_before: FeedbackCue = workbench.session.current().trial_copy()
	var saved_text := FileAccess.get_file_as_string(workbench.cue_path)
	assert_str(panel.batch.add_paths([STAR.resource_path])).is_empty()
	browser.call("_group_filtered")
	assert_int(panel.batch.group.assets.size()).is_equal(3)
	assert_str(panel.get("_notice").text).contains("本次新增 2 个源文件；已在集合 0 个；跳过 2 项")
	assert_str(panel.get("_notice").text).contains("indirect texture")
	assert_str(panel.get("_notice").text).contains("Source extension is not supported")
	assert_str(panel.get("_notice").text).contains(unsupported.resource_path)
	browser.call("_group_filtered")
	assert_int(panel.batch.group.assets.size()).is_equal(3)
	assert_str(panel.get("_notice").text).contains("本次新增 0 个源文件；已在集合 2 个；跳过 2 项")
	assert_bool(workbench.session.current().same_values(trial_before)).is_true()
	assert_bool(workbench.session.is_dirty()).is_false()
	assert_str(FileAccess.get_file_as_string(workbench.cue_path)).is_equal(saved_text)


func test_scene_collection_shares_counts_without_changing_object_trials() -> void:
	var workbench := _workbench(Composition)
	var composition: Control = workbench.get("_composition")
	var trials_before: Array[FeedbackCue] = []
	for session: Session in composition.sessions.values():
		trials_before.append(session.current().trial_copy())
	var panel: BatchPanel = workbench.get("_batch")
	composition.call("_scene_action", 0)
	assert_int(panel.batch.group.assets.size()).is_equal(4)
	assert_str(panel.get("_notice").text).contains("本次新增 4 个源文件；已在集合 0 个；跳过 0 项")
	composition.call("_scene_action", 0)
	assert_int(panel.batch.group.assets.size()).is_equal(4)
	assert_str(panel.get("_notice").text).contains("本次新增 0 个源文件；已在集合 4 个；跳过 0 项")
	var index: int = 0
	for session: Session in composition.sessions.values():
		assert_bool(session.current().same_values(trials_before[index])).is_true()
		assert_bool(session.is_dirty()).is_false()
		index += 1


func test_empty_and_null_collection_input_preserves_existing_members() -> void:
	var panel: BatchPanel = _workbench().get("_batch")
	assert_str(panel.batch.add_paths([STAR.resource_path])).is_empty()
	panel.open_assets([])
	assert_int(panel.batch.group.assets.size()).is_equal(1)
	assert_str(panel.get("_notice").text).contains("本次新增 0 个源文件；已在集合 0 个；跳过 0 项")
	panel.open_assets([null])
	assert_int(panel.batch.group.assets.size()).is_equal(1)
	assert_str(panel.get("_notice").text).contains("跳过 1 项")
	assert_str(panel.get("_notice").text).contains("空资源")


func test_busy_collection_retains_original_error_and_membership() -> void:
	var panel: BatchPanel = _workbench().get("_batch")
	assert_str(panel.batch.add_paths([IMAGE.resource_path])).is_empty()
	var original: Array = panel.batch.group.assets.duplicate(true)
	# Submit real jobs, then cancel synchronously before a process frame can start a worker.
	panel.batch.run()
	assert_bool(panel.batch.busy()).is_true()
	panel.open_assets([IMAGE, SOUND])
	assert_array(panel.batch.group.assets).is_equal(original)
	assert_str(panel.get("_notice").text).contains(
		"Cancel or finish the batch before changing membership.")
	assert_str(panel.get("_notice").text).contains("本次新增 0 个源文件；已在集合 1 个")
	assert_str(panel.get("_notice").text).contains("1 个有效源文件未加入")
	assert_bool(panel.batch.busy()).is_true()
	panel.batch.cancel()
	assert_bool(panel.batch.busy()).is_false()


func test_collection_limit_reports_partial_addition_and_retains_original_error() -> void:
	var panel: BatchPanel = _workbench().get("_batch")
	var paths: Array[String] = []
	for index: int in Group.MAX_ASSETS - 1:
		paths.append("res://tests/features/asset_workbench_recovery/member-%d.png" % index)
	assert_str(panel.batch.add_paths(paths)).is_empty()
	var first: Dictionary = panel.batch.group.assets[0].duplicate()
	panel.open_assets([IMAGE, SOUND])
	assert_int(panel.batch.group.assets.size()).is_equal(Group.MAX_ASSETS)
	assert_dict(panel.batch.group.assets[0]).is_equal(first)
	assert_dict(panel.batch.group.assets.back()).is_equal(
		{"path": IMAGE.resource_path, "type": "image"})
	assert_str(panel.get("_notice").text).contains(
		"Group is limited to 512 assets. Create another group.")
	assert_str(panel.get("_notice").text).contains("本次新增 1 个源文件；已在集合 0 个")
	assert_str(panel.get("_notice").text).contains("1 个有效源文件未加入")
	panel.open_assets([IMAGE, SOUND])
	assert_int(panel.batch.group.assets.size()).is_equal(Group.MAX_ASSETS)
	assert_str(panel.get("_notice").text).contains(
		"Group is limited to 512 assets. Create another group.")
	assert_str(panel.get("_notice").text).contains("本次新增 0 个源文件；已在集合 1 个")


func _workbench(scene: PackedScene = Single, cue_path: String = "") -> Control:
	var workbench: Control = auto_free(scene.instantiate())
	if not cue_path.is_empty():
		workbench.cue_path = cue_path
	_workbenches.append(workbench)
	add_child(workbench)
	return workbench


func _assert_candidate_tools_available(workbench: Control) -> void:
	var browser: Control = workbench.get("_browser")
	browser.call("_select", 2)
	browser.call("audition")
	assert_int(browser.get("_audio").active_voice_count()).is_equal(1)
	browser.call("stop")
	browser.call("_analyze_selected")
	var analysis: Window = workbench.get("_analysis")
	assert_object(analysis.get("_selected")).is_same(SOUND)
	analysis.call("_analyze", 0)
	assert_int(analysis.get("_tasks")[0]).is_greater(0)
	analysis.call("_close")


func _fixture_path(suffix: String) -> String:
	var directory: String = get_script().resource_path.get_base_dir()
	var path := directory.path_join("recovery-%d-%d-%s" % [Time.get_ticks_usec(), randi(), suffix])
	_owned_files.append(path)
	return path


func _save_cue(cue: FeedbackCue) -> String:
	var path := _fixture_path("cue.tres")
	assert_int(ResourceSaver.save(cue, path)).is_equal(OK)
	return path


func _saved_atlas() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = IMAGE
	atlas.region = Rect2(0, 0, 16, 16)
	var path := _fixture_path("atlas.tres")
	assert_int(ResourceSaver.save(atlas, path)).is_equal(OK)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as AtlasTexture


func _unsupported_svg() -> Texture2D:
	var path := _fixture_path("vector.svg")
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"/>'
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(svg)
	file.close()
	var image := Image.new()
	assert_int(image.load_svg_from_string(svg)).is_equal(OK)
	var texture := ImageTexture.create_from_image(image)
	texture.resource_path = path
	return texture
