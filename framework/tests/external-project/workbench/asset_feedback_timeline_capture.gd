extends SceneTree

## Real-render E5/E6 evidence; does not save Cue files or claim human visual/listening acceptance.

const Workbench = preload(
	"res://yaya/asset_workbench/examples/effects_composition/example_workbench.tscn")
const Consumer = preload("res://yaya/asset_workbench/examples/effects_composition/example_consumer.tscn")
const Stage = preload("res://components/feedback/feedback_composition.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const TimelinePlayer = preload("res://components/feedback/feedback_timeline_player.gd")
const REPORT: String = "res://reports/asset-workbench-e5-e6-20260922/"

var _failed: bool = false
var _output: String
var _results: Dictionary = {}
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Timeline capture requires a real rendering display driver.")
		quit(1)
		return
	_output = REPORT + String(RenderingServer.get_current_rendering_method()) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	_results["display_driver"] = DisplayServer.get_name()
	_results["renderer"] = String(RenderingServer.get_current_rendering_method())
	await _workbench()
	await _consumer()
	await _lifecycle_cycles()
	_results["passed"] = not _failed
	_results["failures"] = _failures
	_results["limits"] = ["No Cue writes; save accessibility only.",
		"Pixel changes establish rendered activity, not image quality or perceived timing.",
		"Ten short cycles check cleanup, not performance or long-duration stability.",
		"Human listening, visual acceptance and interaction comfort remain unverified."]
	var file := FileAccess.open(_output + "timeline-render-results.json", FileAccess.WRITE)
	if file == null:
		_check(false, "Cannot write timeline render results.")
	else:
		file.store_string(JSON.stringify(_results, "  ") + "\n")
		file.close()
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _failed else 0)


func _workbench() -> void:
	root.size = Vector2i(1600, 900)
	var workbench: Control = Workbench.instantiate()
	root.add_child(workbench)
	await _settle_layout()
	var layout: Control = workbench.get("_ui")
	var panel: Control = workbench.get("_composition")
	var stage: Stage = panel.get("stage")
	var checks: Array[Dictionary] = []
	var sizes: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1152, 648),
		Vector2i(900, 540), Vector2i(720, 480)]
	for dark: bool in [false, true]:
		workbench.call("_set_dark_theme", dark)
		for resolution: Vector2i in sizes:
			root.size = resolution
			await _settle_layout()
			layout.call("_show_region", 1)
			await _settle_layout()
			checks.append(await _workbench_case(workbench, stage, resolution, dark))
	workbench.call("stop_all")
	workbench.queue_free()
	await process_frame
	_results["workbench"] = checks


func _workbench_case(workbench: Control, stage: Stage,
		resolution: Vector2i, dark: bool) -> Dictionary:
	var initial_failures := _failures.size()
	_check(root.size == resolution, "Requested workbench size was overridden.")
	var play := _button(workbench, "播放编排")
	var repeat := _button(workbench, "循环编排")
	var stop := _button(workbench, "停止全部")
	_button(workbench, "保存当前方案")
	if play != null and repeat != null and stop != null:
		# Real pointer input also proves the new toolbar is not occluded by another Control.
		if repeat.button_pressed:
			await _click(repeat.get_global_rect().get_center())
		await _click(play.get_global_rect().get_center())
		_check(stage.timeline_player.is_playing(), "Workbench play pointer input did not start.")
		_check(not stage.timeline_player.looping, "Unchecked repeat must start a single run.")
		await _click(stop.get_global_rect().get_center())
		_check_stopped(stage, "Workbench single stop")
		await _click(repeat.get_global_rect().get_center())
		await _click(play.get_global_rect().get_center())
		_check(stage.timeline_player.looping and stage.timeline_player.is_playing(),
			"Workbench repeat pointer input did not start loop mode.")
		await create_timer(0.2).timeout
		_check_running_layout(workbench, resolution)
		await _save_window("timeline-workbench-%s-%dx%d.png" % [
			"dark" if dark else "light", resolution.x, resolution.y])
		await _click(stop.get_global_rect().get_center())
		_check_stopped(stage, "Workbench looping stop")
	return {"size": [resolution.x, resolution.y], "dark": dark,
		"passed": _failures.size() == initial_failures}


func _check_running_layout(workbench: Control, resolution: Vector2i) -> void:
	_check(root.size == resolution, "Playing status enlarged the requested window.")
	_button(workbench, "停止全部")
	_button(workbench, "保存当前方案")
	var panel: Control = workbench.get("_composition")
	for field: String in ["_scene_state", "_timeline_state"]:
		var label: Label = panel.get(field)
		_check(label.get_line_count() == 1, "Playback status wrapped into a vertical label.")
		_check(root.get_visible_rect().encloses(label.get_global_rect()),
			"Playback status escaped the viewport.")


func _consumer() -> void:
	root.size = Vector2i(1600, 900)
	var scene := Consumer.instantiate() as Stage
	root.add_child(scene)
	await _settle_layout()
	var before := await _window_image()
	_save(before, "timeline-consumer-before.png")
	var play := _button(scene, "播放编排")
	if play != null:
		await _click(play.get_global_rect().get_center())
	_check(scene.timeline_player.is_playing(), "Consumer pointer play did not start.")
	var phases: Array[Dictionary] = []
	phases.append(await _phase(scene, before, "group-a", 0.3, [true, false]))
	phases.append(await _phase(scene, before, "group-b", 2.0, [false, true]))
	phases.append(await _phase(scene, before, "parallel-cores", 3.7, [true, true]))
	var deadline := Time.get_ticks_msec() + 6000
	while scene.timeline_player.is_playing() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check_stopped(scene, "Consumer natural end")
	await _save_window("timeline-consumer-ended.png")
	await _consumer_stop(scene)
	scene.queue_free()
	await process_frame
	_results["consumer_phases"] = phases


func _phase(scene: Stage, before: Image, caption: String,
		position: float, expected: Array[bool]) -> Dictionary:
	await _wait_position(scene.timeline_player, position)
	var picture := await _window_image()
	var actual_position := scene.timeline_player.position_seconds
	_check(actual_position >= position and actual_position < position + 0.5,
		"Render sample missed the open phase: " + caption)
	var observations: Array[Dictionary] = []
	for index: int in 2:
		var path := ("GroupA" if index == 0 else "GroupB") + "/Core"
		var object := scene.object_at(path)
		var active := object.presenter.is_playing()
		var changed := _changed_pixels(before, picture, _object_region(object.presenter))
		_check(active == expected[index], caption + " active target mismatch: " + path)
		if expected[index]:
			_check(changed > 10, caption + " has no rendered change for " + path)
		observations.append({"target": path, "active": active, "changed_pixels": changed})
	_save(picture, "timeline-consumer-" + caption + ".png")
	return {"phase": caption, "position_seconds": actual_position, "objects": observations}


func _consumer_stop(scene: Stage) -> void:
	var loop_button := _button(scene, "循环编排")
	if loop_button != null:
		await _click(loop_button.get_global_rect().get_center())
	await _wait_position(scene.timeline_player, 0.6)
	_check(scene.timeline_player.looping, "Consumer loop action did not enable looping.")
	var stop := _button(scene, "停止全部")
	if stop != null:
		await _click(stop.get_global_rect().get_center())
	_check_stopped(scene, "Consumer explicit stop")
	await create_timer(0.25).timeout
	_check_stopped(scene, "Consumer no delayed restart")
	await _save_window("timeline-consumer-stopped.png")


func _lifecycle_cycles() -> void:
	await process_frame
	var baseline_nodes := get_node_count()
	var baseline_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var cycles: Array[Dictionary] = []
	for index: int in 10:
		var scene := Consumer.instantiate() as Stage
		root.add_child(scene)
		_check(scene.play_timeline(true).is_empty(), "Cycle playback start failed.")
		await _wait_position(scene.timeline_player, 0.45)
		scene.stop()
		_check_stopped(scene, "Cycle %d stop" % (index + 1))
		scene.queue_free()
		await process_frame
		await process_frame
		var nodes := get_node_count()
		var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		_check(nodes == baseline_nodes, "Cycle node count did not return to baseline.")
		_check(orphans == baseline_orphans, "Cycle orphan count grew.")
		cycles.append({"cycle": index + 1, "nodes": nodes, "orphans": orphans})
	_results["lifecycle"] = {"baseline_nodes": baseline_nodes,
		"baseline_orphans": baseline_orphans, "cycles": cycles}


func _check_stopped(scene: Stage, context: String) -> void:
	_check(not scene.timeline_player.is_playing() and not scene.timeline_player.looping,
		context + ": timeline remained active")
	_check(scene.manager.active_count() == 0, context + ": manager retained handles")
	for object: ObjectView in scene.objects:
		var presenter := object.presenter
		_check(not presenter.is_playing() and presenter.pending_audio_count() == 0
			and presenter.active_voice_count() == 0 and presenter.active_effect_count() == 0,
			context + ": target still active: " + String(object.name))
		var motion: Node2D = presenter.get("_motion")
		var content: Node2D = motion.get("content")
		var tween_root: Node2D = motion.get("_tween_root")
		_check(content.transform == Transform2D.IDENTITY and tween_root.position == Vector2.ZERO,
			context + ": motion transform was not restored")
		var emitter: GPUParticles2D = presenter.get("_particles").get("_emitter")
		if emitter != null:
			_check(not emitter.emitting and not emitter.visible, context + ": emitter not cleared")


func _button(owner_node: Node, caption: String) -> Button:
	var visible_buttons: Array[Button] = []
	for node: Node in owner_node.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == caption and button.is_visible_in_tree():
			visible_buttons.append(button)
	_check(visible_buttons.size() == 1, "Expected one visible button: " + caption)
	if visible_buttons.is_empty():
		return null
	var result := visible_buttons[0]
	_check(not result.disabled, "Button is disabled: " + caption)
	_check(root.get_visible_rect().grow(1).encloses(result.get_global_rect()),
		"Button escaped viewport: " + caption)
	result.grab_focus()
	_check(root.gui_get_focus_owner() == result, "Button is not focusable: " + caption)
	return result


func _wait_position(player: TimelinePlayer, requested: float) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while player.is_playing() and player.position_seconds < requested \
			and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(player.is_playing() and player.position_seconds >= requested,
		"Timeline did not reach the requested render phase.")


func _object_region(presenter: Presenter) -> Rect2i:
	# 截图是窗口像素；拉伸模式下画布坐标要先乘上拉伸变换。
	var transform := root.get_stretch_transform() * presenter.get_global_transform_with_canvas()
	var box := Rect2(transform * Vector2.ZERO, Vector2.ZERO)
	for point: Vector2 in [Vector2(presenter.size.x, 0.0), presenter.size,
			Vector2(0.0, presenter.size.y)]:
		box = box.expand(transform * point)
	return Rect2i(box.grow(50.0)).intersection(Rect2i(Vector2i.ZERO, root.size))


func _changed_pixels(before: Image, after: Image, area: Rect2i) -> int:
	var count: int = 0
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var left := before.get_pixel(x, y)
			var right := after.get_pixel(x, y)
			if absf(left.r - right.r) + absf(left.g - right.g) + absf(left.b - right.b) > 0.03:
				count += 1
	return count


func _click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)
	await process_frame


func _settle_layout() -> void:
	await process_frame
	await process_frame


func _window_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _save_window(filename: String) -> void:
	_save(await _window_image(), filename)


func _save(picture: Image, filename: String) -> void:
	_check(picture.save_png(_output + filename) == OK, "Cannot save render evidence: " + filename)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		_failures.append(message)
		push_error(message)
