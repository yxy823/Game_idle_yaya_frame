extends SceneTree

const Workbench = preload("res://examples/asset_workbench/single/example-workbench.tscn")
const Composition = preload("res://examples/asset_workbench/composition/example-workbench.tscn")
const Group = preload("res://tools/asset_workbench/analysis_group.gd")
const DIRECTORY: String = "res://reports/asset-analysis-group/"

var _failed: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
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
	var scroll := composed.find_child("WorkbenchBody", true, false) as ScrollContainer
	var parameters := composed.find_child("ParameterColumn", true, false) as ScrollContainer
	scroll.ensure_control_visible(parameters)
	await process_frame
	_check(scroll.scroll_horizontal > 0, "Compact workbench must scroll horizontally")
	await _save(root, "composition-compact-scrolled.png")
	composed.queue_free()
	await process_frame
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _batch_capture(workbench: Control) -> void:
	var panel: Window = workbench.get("_batch")
	panel.batch.load_group(Group.read_json(
		"res://examples/asset_workbench/example-analysis-group.json").data)
	panel.batch.group.rules.append({"type": "image", "metric": "transparent_ratio",
		"unit": "ratio", "operator": "max", "value": 0.75})
	panel.call("open_assets", [] as Array[Resource])
	panel.call("_start", true)
	var deadline := Time.get_ticks_msec() + 30000
	while panel.batch.busy() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not panel.batch.busy(), "Batch timed out")
	for data: Dictionary in panel.batch.results.values():
		_check(data.status == "success", "Batch result failed")
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


func _save(window: Window, filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_check(window.get_texture().get_image().save_png(DIRECTORY + filename) == OK, filename)


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failed = true
		push_error(message)
