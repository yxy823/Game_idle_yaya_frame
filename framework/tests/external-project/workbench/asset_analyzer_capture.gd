extends SceneTree

## Real rendered UI, real worker results. This is evidence, not human acceptance.

const Workbench = preload("res://yaya/asset_workbench/examples/single/example_workbench.tscn")
const ASSETS: String = "res://yaya/asset_workbench/examples/assets/"
const OUTPUT: String = "res://reports/asset-workbench-ui-20260922/analysis/"

var _failed: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1600, 900)
	var workbench: Control = Workbench.instantiate()
	root.add_child(workbench)
	await process_frame
	var panel: Window = workbench.get("_analysis")
	await _compare(panel, "example_confirmation_a.ogg", "example_confirmation_b.ogg")
	await _save(panel, "audio-analysis.png")
	_save_json(panel, "audio-results.json")
	panel.get("_threshold").value = -30
	await _save(panel, "audio-stale-settings.png")
	panel.get("_threshold").value = -50
	await _compare(panel, "example_trophy.png", "example_star.png")
	await _save(panel, "image-analysis.png")
	_save_json(panel, "image-results.json")
	workbench.call("_set_dark_theme", true)
	await _save(panel, "analysis-dark.png")
	workbench.call("_set_dark_theme", false)
	await _compact(panel)
	workbench.queue_free()
	await process_frame
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _compact(panel: Window) -> void:
	panel.size = Vector2i(600, 450)
	await _save(panel, "analysis-compact.png")
	var scroll := panel.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	var details := panel.get("_details") as Label
	(details.get_parent().get_parent() as FoldableContainer).expand()
	await process_frame
	scroll.ensure_control_visible(details)
	await process_frame
	if scroll.scroll_vertical <= 0:
		_failed = true
		push_error("Compact analysis cannot scroll to result details")
	await _save(panel, "analysis-compact-details.png")


func _compare(panel: Window, first: String, second: String) -> void:
	for index: int in 2:
		panel.call("open_asset", load(ASSETS + [first, second][index]))
		panel.call("_analyze", index)
		panel.call("_reanalyze", index)
	var deadline := Time.get_ticks_msec() + 15000
	while panel.get("_tasks") != [0, 0] and Time.get_ticks_msec() < deadline:
		await process_frame
	for data: Dictionary in panel.get("results"):
		if data.get("status") != "success":
			_failed = true
			push_error("Actual analysis did not succeed: " + JSON.stringify(data))


func _save(panel: Window, filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := panel.get_texture().get_image().save_png(OUTPUT + filename)
	if error != OK:
		_failed = true
		push_error("Capture failed: " + error_string(error))


func _save_json(panel: Window, filename: String) -> void:
	var file := FileAccess.open(OUTPUT + filename, FileAccess.WRITE)
	file.store_string(JSON.stringify(panel.get("results"), "  "))
	file.close()
