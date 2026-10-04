extends SceneTree

## E3 real pixels: emitted particles follow local transforms or remain in scene space.

const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const Consumer = preload("res://yaya/asset_workbench/examples/effects_composition/example_consumer.tscn")
const BASE: String = "res://yaya/asset_workbench/examples/effects_composition/"
const REPORT: String = "res://reports/asset-workbench-e3-e4-20260922/"

var _failed: bool = false
var _output: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Coordinate evidence requires real GPU pixels.")
		quit(1)
		return
	_output = REPORT + String(RenderingServer.get_current_rendering_method()) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var results: Dictionary = {}
	for role: String in ["local", "world"]:
		results[role] = await _coordinates(role)
	await _consumer()
	results["passed"] = not _failed
	var file := FileAccess.open(_output + "reuse-render-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  ") + "\n")
	file.close()
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _coordinates(role: String) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 256)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var presenter := Presenter.new()
	presenter.size = Vector2(256, 256)
	viewport.add_child(presenter)
	var source := load(BASE + "example_cluster_" + role + "_cue.tres") as FeedbackCue
	var cue := source.trial_copy()
	cue.tween_enabled = false
	cue.particle_delay_seconds = 0.0
	cue.particle_emission_seconds = 1.0
	presenter.configure(cue)
	presenter.trigger()
	await create_timer(0.25).timeout
	var emitter: GPUParticles2D = presenter.get("_particles").get("_emitter")
	# Freeze only this probe's simulation so pixel motion measures coordinate ownership.
	emitter.emitting = false
	emitter.speed_scale = 0.0
	var before_image := await _image(viewport)
	var before_center := _centroid(before_image)
	presenter.position.x += 120.0
	var after_image := await _image(viewport)
	var after_center := _centroid(after_image)
	_save(before_image, role + "-before.png")
	_save(after_image, role + "-translated.png")
	var displacement := after_center.x - before_center.x
	_check(before_center.x >= 0 and after_center.x >= 0, role + " particles must be visible")
	_check(absf(displacement - (120.0 if role == "local" else 0.0)) < 3.0,
		role + " particle translation disagrees with coordinate space")
	presenter.stop()
	_check(_centroid(await _image(viewport)).x < 0, role + " stop left rendered particles")
	viewport.queue_free()
	await process_frame
	return {"parent_translation_px": 120, "particle_translation_px": displacement,
		"before_centroid_x": before_center.x, "after_centroid_x": after_center.x}


func _consumer() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Control = Consumer.instantiate()
	root.add_child(scene)
	await process_frame
	scene.trigger_all()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "reused-consumer-playing.png")
	scene.stop()
	await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "reused-consumer-stopped.png")
	scene.queue_free()
	await process_frame


func _image(viewport: SubViewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _centroid(picture: Image) -> Vector2:
	var total := Vector2.ZERO
	var count: int = 0
	for y: int in picture.get_height():
		for x: int in picture.get_width():
			if picture.get_pixel(x, y).a > 0.05:
				total += Vector2(x, y)
				count += 1
	return total / count if count > 0 else Vector2(-1, -1)


func _save(picture: Image, filename: String) -> void:
	_check(picture.save_png(_output + filename) == OK, "Could not save " + filename)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)
