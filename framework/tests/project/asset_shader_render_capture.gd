extends SceneTree

## Real-render evidence for the same visual component used by both game and workbench.

const Workbench = preload("res://examples/asset_workbench/shader_composition/example-workbench.tscn")
const Composition = preload("res://examples/asset_workbench/shader_composition/example-composition.tscn")
const Visual = preload("res://components/feedback/feedback_visual.gd")
const EXAMPLES: String = "res://examples/asset_workbench/shader_composition/"
const OUTPUT: String = "res://reports/asset-workbench-ui-20260922/shader/"

var _failed: bool = false
var _metrics: Dictionary = {}


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Shader capture requires a real rendering display driver.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _check_shader_pixels()
	await _capture_workbench()
	await _capture_consumer()
	var file := FileAccess.open(OUTPUT + "render-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": not _failed, "pixels": _metrics}, "  ") + "\n")
	file.close()
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _check_shader_pixels() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var visual := Visual.new()
	visual.size = Vector2(128, 128)
	viewport.add_child(visual)
	for kind: String in ["outline", "dissolve", "noise"]:
		var saved := load(EXAMPLES + "example-" + kind + "-cue.tres") as FeedbackCue
		var cue := saved.trial_copy()
		# Half strength leaves a measurable partial silhouette; the saved 0.9 peak can erase it fully.
		if kind == "dissolve":
			cue.shader_strength = 0.5
		visual.configure(cue)
		var plain := await _read_surface(viewport)
		_save_image(plain, kind + "-plain.png")
		visual.trigger()
		visual.set_process(false)
		visual.call("_process", cue.shader_delay_seconds + cue.shader_duration_seconds * 0.5)
		var effect := await _read_surface(viewport)
		_save_image(effect, kind + "-peak.png")
		_check_effect(kind, plain, effect)
		visual.stop()
		var stopped := await _read_surface(viewport)
		_save_image(stopped, kind + "-stopped.png")
		_check(stopped.get_data() == plain.get_data(), "Stop must restore pixels: " + kind)
	viewport.queue_free()
	await process_frame


func _check_effect(kind: String, plain: Image, effect: Image) -> void:
	var plain_pixels := _visible_pixels(plain)
	var effect_pixels := _visible_pixels(effect)
	_metrics[kind] = {"plain_visible": plain_pixels, "effect_visible": effect_pixels}
	match kind:
		"outline":
			_check(effect_pixels > plain_pixels, "Outline must expand the visible silhouette.")
		"dissolve":
			_check(effect_pixels > 0 and effect_pixels < plain_pixels,
				"Dissolve must remove part of the input image.")
		"noise":
			_check(plain_pixels == 0 and effect_pixels == 128 * 128,
				"Shader-only cue must render without an image.")
			_check(_color_range(effect) > 0.2, "Noise shader must vary over the quad's UVs.")


func _capture_workbench() -> void:
	root.size = Vector2i(1600, 900)
	var workbench: Control = Workbench.instantiate()
	root.add_child(workbench)
	await process_frame
	await process_frame
	var panel: Control = workbench.get("_composition")
	panel.trigger_all()
	await create_timer(0.55).timeout
	await _save_window("workbench-light.png")
	workbench.stop_all()
	workbench.call("_set_dark_theme", true)
	panel.trigger_all()
	await create_timer(0.55).timeout
	await _save_window("workbench-dark.png")
	workbench.stop_all()
	var parameters := workbench.find_child("ParameterColumn", true, false) as ScrollContainer
	var shader_controls: Control = workbench.get("_controls").get("_shader")
	await _check_reachable(parameters, shader_controls.get("_duration"))
	await _save_window("workbench-shader-controls.png")
	root.size = Vector2i(900, 540)
	await process_frame
	await process_frame
	workbench.get("_ui").call("_show_region", 2)
	await process_frame
	await _check_reachable(parameters, shader_controls.get("_duration"))
	await _save_window("workbench-compact-controls.png")
	workbench.queue_free()
	await process_frame


func _capture_consumer() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Control = Composition.instantiate()
	root.add_child(scene)
	await process_frame
	scene.trigger_all()
	await create_timer(0.55).timeout
	await _save_window("saved-composition-consumer.png")
	scene.stop()
	await _save_window("saved-composition-stopped.png")
	scene.queue_free()
	await process_frame


func _check_reachable(column: ScrollContainer, control: Control) -> void:
	column.ensure_control_visible(control)
	await process_frame
	_check(column.get_global_rect().encloses(control.get_global_rect()),
		"Shader duration must be reachable vertically.")
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()),
		"Shader duration must be reachable horizontally.")


func _read_surface(viewport: SubViewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _save_window(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_save_image(root.get_texture().get_image(), filename)


func _save_image(picture: Image, filename: String) -> void:
	_check(picture.save_png(OUTPUT + filename) == OK, "Cannot save render evidence: " + filename)


func _visible_pixels(picture: Image) -> int:
	var count: int = 0
	for y: int in picture.get_height():
		for x: int in picture.get_width():
			if picture.get_pixel(x, y).a > 0.05:
				count += 1
	return count


func _color_range(picture: Image) -> float:
	var lowest: float = 1.0
	var highest: float = 0.0
	for y: int in picture.get_height():
		for x: int in picture.get_width():
			var red := picture.get_pixel(x, y).r
			lowest = minf(lowest, red)
			highest = maxf(highest, red)
	return highest - lowest


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)
