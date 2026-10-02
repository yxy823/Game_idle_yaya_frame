extends SceneTree

const Workbench = preload("res://asset_workbench/examples/single/example_workbench.tscn")
const Composition = preload("res://asset_workbench/examples/composition/example_workbench.tscn")
const Group = preload("res://asset_workbench/ui/analysis_group.gd")
const DIRECTORY: String = "res://reports/asset-workbench-ui-20260922/group/"

var _failed: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	var workbench: Control = Workbench.instantiate()
	root.add_child(workbench)
	current_scene = workbench
	await process_frame
	await process_frame
	await _save(root, "workbench-large.png")
	var state := {"actual_window": [root.size.x, root.size.y],
		"project_width": ProjectSettings.get_setting("display/window/size/viewport_width"),
		"project_height": ProjectSettings.get_setting("display/window/size/viewport_height"),
		"engine": Engine.get_version_info().string}
	_check(Group.write_json(DIRECTORY + "window-state.json", state).is_empty(), "Window evidence")
	await _batch_capture(workbench)
	workbench.queue_free()
	await process_frame
	var composed: Control = Composition.instantiate()
	root.add_child(composed)
	current_scene = composed
	var composition: Control = composed.get("_composition")
	composition.stage.objects[0].pressed.emit()
	composition.call("apply_gain", -22.0)
	await _save(root, "composition-light.png")
	composed.call("_set_dark_theme", true)
	await _save(root, "composition-dark.png")
	root.size = Vector2i(900, 600)
	await _save(root, "composition-compact.png")
	composed.get("_ui").call("_show_region", 2)
	var parameters := composed.find_child("ParameterColumn", true, false) as ScrollContainer
	await process_frame
	_check(parameters.is_visible_in_tree(), "Compact inspector must remain accessible")
	await _save(root, "composition-compact-scrolled.png")
	composed.queue_free()
	await process_frame
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _batch_capture(workbench: Control) -> void:
	var panel: Window = workbench.get("_batch")
	var expected_paths := _load_batch_fixture(panel)
	if expected_paths.is_empty():
		return
	panel.batch.group.rules.append({"type": "image", "metric": "transparent_ratio",
		"unit": "ratio", "operator": "max", "value": 0.75})
	panel.call("open_assets", [] as Array[Resource])
	panel.call("_start", true)
	var deadline := Time.get_ticks_msec() + 30000
	while panel.batch.busy() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not panel.batch.busy(), "Batch timed out")
	var actual_paths: Array = panel.batch.results.keys()
	expected_paths.sort()
	actual_paths.sort()
	_check(actual_paths == expected_paths, "Batch results must cover exactly the requested assets")
	for path: String in expected_paths:
		var data: Dictionary = panel.batch.results.get(path, {})
		_check(data.get("status", "") == "success", "Batch result missing or failed: " + path)
		_check(Group.project_path(data.get("asset", {}).get("path", "")) == path,
			"Batch result source does not match: " + path)
	await process_frame
	panel.get("_members").get_root().get_child(1).select(0)
	panel.call("_show_selection")
	await _save(panel, "group-light.png")
	_check(Group.write_json(DIRECTORY + "batch-results.json", panel.batch.snapshot()).is_empty(),
		"Batch snapshot evidence")
	workbench.call("_set_dark_theme", true)
	await _save(panel, "group-dark.png")
	panel.size = Vector2i(620, 440)
	await _save(panel, "group-compact.png")
	var scroll := panel.get_node("GroupScroll") as ScrollContainer
	scroll.ensure_control_visible(panel.get("_details"))
	await process_frame
	_check(scroll.scroll_vertical > 0, "Compact group details must remain reachable")
	await _save(panel, "group-compact-details.png")
	await _unsupported_source_capture(workbench, panel)


func _load_batch_fixture(panel: Window) -> Array[String]:
	var example := Group.read_json("res://asset_workbench/examples/example_analysis_group.json")
	_check(not example.has("error"), "Cannot read batch fixture: " + example.get("error", ""))
	if example.has("error"):
		return []
	var issue: String = panel.batch.load_group(example.data)
	_check(issue.is_empty(), "Cannot load batch fixture: " + issue)
	if not issue.is_empty():
		return []
	var expected_paths: Array[String] = []
	for asset: Dictionary in example.data.assets:
		expected_paths.append(asset.path)
	_check(expected_paths.size() == 4, "Batch fixture must contain four source assets")
	return expected_paths if expected_paths.size() == 4 else []


func _unsupported_source_capture(workbench: Control, panel: Window) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://asset_workbench/examples/assets/example_star.png")
	var assets: Array[Resource] = [atlas]
	var count: int = panel.batch.group.assets.size()
	panel.call("open_assets", assets)
	_check(panel.batch.group.assets.size() == count, "Indirect texture must not join source files")
	var notice: Label = panel.get("_notice")
	_check(notice.text.contains("本次新增 0") and notice.text.contains("跳过 1 项"),
		"Collection must report real additions and skipped resources")
	workbench.call("_set_dark_theme", false)
	panel.size = Vector2i(1600, 900)
	var scroll := panel.get_node("GroupScroll") as ScrollContainer
	scroll.scroll_vertical = 0
	await _save(panel, "group-unsupported-source.png")
	panel.size = Vector2i(620, 440)
	await process_frame
	scroll.ensure_control_visible(notice)
	await _save(panel, "group-unsupported-source-compact.png")


func _save(window: Window, filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_check(window.get_texture().get_image().save_png(DIRECTORY + filename) == OK, filename)


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failed = true
		push_error(message)
