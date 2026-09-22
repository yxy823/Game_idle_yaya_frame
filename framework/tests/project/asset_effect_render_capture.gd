extends SceneTree

## Real GPU output, lifecycle and UI evidence. Run with a real display driver.

const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const Workbench = preload("res://examples/asset_workbench/effects_composition/example-workbench.tscn")
const Composition = preload("res://examples/asset_workbench/effects_composition/example-composition.tscn")
const EXAMPLES: String = "res://examples/asset_workbench/effects_composition/"
const REPORT: String = "res://reports/asset-workbench-effects-20260922/"

var _failed: bool = false
var _metrics: Dictionary = {}
var _output: String


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Effects capture requires a real rendering display driver.")
		quit(1)
		return
	_output = REPORT + String(RenderingServer.get_current_rendering_method()) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	await _check_particles()
	await _check_motion()
	await _capture_workbench()
	await _capture_consumer()
	var file := FileAccess.open(_output + "render-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": not _failed, "checks": _metrics}, "  ") + "\n")
	file.close()
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _check_particles() -> void:
	var viewport := _surface()
	var presenter := Presenter.new()
	presenter.size = Vector2(256, 256)
	viewport.add_child(presenter)
	for kind: String in ["burst", "stream"]:
		var cue := FeedbackCue.new()
		cue.particle_preset = load(EXAMPLES + "example-" + kind + "-preset.tres")
		cue.particle_emission_seconds = 0.3
		presenter.configure(cue)
		var before := await _read_surface(viewport)
		presenter.trigger()
		await create_timer(0.2).timeout
		var effect := await _read_surface(viewport)
		_save(effect, kind + "-visible.png")
		var count := _visible_pixels(effect)
		_check(_visible_pixels(before) == 0 and count > 10, kind + " must draw real particles")
		presenter.trigger()
		await create_timer(0.15).timeout
		_check(_visible_pixels(await _read_surface(viewport)) > 0, kind + " must restart visibly")
		presenter.stop()
		_check(_visible_pixels(await _read_surface(viewport)) == 0, kind + " stop must clear output")
		presenter.trigger()
		await create_timer(1.5).timeout
		var ended := await _read_surface(viewport)
		_check(presenter.active_effect_count() == 0, kind + " must finish naturally")
		_check(_visible_pixels(ended) == 0, kind + " natural end must clear output")
		_metrics[kind] = {"visible_pixels": count, "natural_end_pixels": _visible_pixels(ended)}
	viewport.queue_free()
	await process_frame


func _check_motion() -> void:
	var viewport := _surface()
	var presenter := Presenter.new()
	presenter.size = Vector2(256, 256)
	viewport.add_child(presenter)
	var cue := FeedbackCue.new()
	cue.texture = load("res://examples/asset_workbench/assets/example-star.png")
	cue.tween_enabled = true
	cue.animation_clip = load(EXAMPLES + "example-wobble-animation.tres")
	presenter.configure(cue)
	var before := await _read_surface(viewport)
	presenter.trigger()
	await create_timer(0.2).timeout
	var moving := await _read_surface(viewport)
	_save(moving, "motion-playing.png")
	_check(moving.get_data() != before.get_data(), "Motion must change actual output")
	presenter.stop()
	var stopped := await _read_surface(viewport)
	_check(stopped.get_data() == before.get_data(), "Motion stop must restore original output")
	presenter.trigger()
	await create_timer(1.2).timeout
	var ended := await _read_surface(viewport)
	_check(ended.get_data() == before.get_data(), "Natural motion end must restore original output")
	_metrics["motion"] = {"restored_after_stop": stopped.get_data() == before.get_data(),
		"restored_after_end": ended.get_data() == before.get_data()}
	viewport.queue_free()
	await process_frame


func _capture_workbench() -> void:
	root.size = Vector2i(1600, 900)
	var workbench: Control = Workbench.instantiate()
	root.add_child(workbench)
	await process_frame
	await process_frame
	var panel: Control = workbench.get("_composition")
	for dark: bool in [false, true]:
		workbench.call("_set_dark_theme", dark)
		panel.trigger_all()
		await create_timer(0.2).timeout
		await _save_window("workbench-dark.png" if dark else "workbench-light.png")
		workbench.stop_all()
	var layout: Control = workbench.get("_ui")
	var effects: Control = workbench.get("_controls").get("_effects")
	var resolutions: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1152, 648),
		Vector2i(900, 540), Vector2i(720, 480)]
	for resolution: Vector2i in resolutions:
		root.size = resolution
		await process_frame
		await process_frame
		layout.call("_show_region", 2)
		await process_frame
		for field: String in ["_particle", "_clip", "_emission", "_tween", "_speed"]:
			await _check_reachable(layout.properties, effects.get(field))
		await _save_window("effect-controls-%dx%d.png" % [resolution.x, resolution.y])
		_check_buttons(workbench)
	workbench.queue_free()
	await process_frame


func _capture_consumer() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Control = Composition.instantiate()
	root.add_child(scene)
	await process_frame
	scene.trigger_all()
	await create_timer(0.2).timeout
	await _save_window("saved-consumer-playing.png")
	scene.stop()
	await _save_window("saved-consumer-stopped.png")
	scene.queue_free()
	await process_frame


func _check_buttons(workbench: Control) -> void:
	var counts: Dictionary[String, int] = {"停止全部": 0, "保存当前方案": 0}
	for node: Node in workbench.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text in counts:
			counts[button.text] += 1
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()),
				"Main action must remain visible: " + button.text)
	_check(counts["停止全部"] == 1 and counts["保存当前方案"] == 1, "One visible stop and save")


func _check_reachable(column: ScrollContainer, control: Control) -> void:
	column.ensure_control_visible(control)
	await process_frame
	_check(column.get_global_rect().encloses(control.get_global_rect()),
		"Effect field must scroll into view")
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()),
		"Effect field must fit the viewport")


func _surface() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport


func _read_surface(viewport: SubViewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _save_window(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), filename)


func _save(picture: Image, filename: String) -> void:
	_check(picture.save_png(_output + filename) == OK, "Cannot save render evidence: " + filename)


func _visible_pixels(picture: Image) -> int:
	var count: int = 0
	for y: int in picture.get_height():
		for x: int in picture.get_width():
			if picture.get_pixel(x, y).a > 0.05:
				count += 1
	return count


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)
