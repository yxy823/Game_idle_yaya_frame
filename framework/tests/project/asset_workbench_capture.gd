extends SceneTree

## External-project render check. Needs a real renderer; it is not human acceptance.

const WorkbenchScene = preload("res://examples/asset_workbench/single/example-workbench.tscn")
const GameScene = preload("res://examples/asset_workbench/single/example-game.tscn")

var _layout_failed: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Capture requires a rendering display driver.")
		quit(1)
		return
	root.size = Vector2i(1280, 860)
	var workbench: Control = WorkbenchScene.instantiate()
	root.add_child(workbench)
	await process_frame
	var candidates := workbench.find_children("*", "ItemList", true, false)[0] as ItemList
	candidates.select(0)
	candidates.item_selected.emit(0)
	workbench.presenter.trigger()
	await create_timer(0.15).timeout
	await _save_frame("workbench.png")
	workbench.stop_all()
	_button(workbench, "Dark background").button_pressed = true
	await _save_frame("workbench-dark.png")
	_button(workbench, "Transparency grid").button_pressed = true
	await _save_frame("workbench-grid.png")
	await _check_compact_window(workbench, Vector2i(1152, 648))
	await _check_compact_window(workbench, Vector2i(900, 540))
	await _check_compact_window(workbench, Vector2i(720, 480))
	workbench.queue_free()
	await process_frame
	root.size = Vector2i(1280, 860)
	await _capture_game()


func _capture_game() -> void:
	var game: Control = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game.activate_example()
	await create_timer(0.15).timeout
	await _save_frame("example-game.png")
	game.queue_free()
	await process_frame
	# Let the audio mixer consume queued stop/free commands before ending the test process.
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	quit(1 if _layout_failed else 0)


func _check_compact_window(workbench: Control, resolution: Vector2i) -> void:
	root.size = resolution
	await process_frame
	await process_frame
	var body := workbench.find_child("WorkbenchBody", true, false) as ScrollContainer
	var asset := workbench.find_child("AssetColumn", true, false) as ScrollContainer
	var event := workbench.find_child("EventColumn", true, false) as ScrollContainer
	var parameters := workbench.find_child("ParameterColumn", true, false) as ScrollContainer
	var status := workbench.get("_status") as Label
	var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
	_check(root.size == resolution, "The requested client size was overridden.")
	_check(viewport.encloses(body.get_global_rect()), "Workbench body escaped the viewport.")
	_check(viewport.encloses(status.get_global_rect()), "Status escaped the viewport.")
	for scroll: ScrollContainer in [body, asset, event, parameters]:
		scroll.scroll_horizontal = 0
		scroll.scroll_vertical = 0
	var suffix := "%dx%d.png" % [resolution.x, resolution.y]
	await _save_frame("workbench-compact-" + suffix)
	await _check_reachable(body, asset, _button(workbench, "Use selection in active A/B"))
	await _check_reachable(body, event, _button(workbench, "Open example game using saved cue"))
	await _save_frame("workbench-actions-" + suffix)
	var controls := parameters.get_child(0) as Container
	var shader_controls: Container = controls.get("_shader")
	await _check_reachable(body, parameters, shader_controls.get_child(-1) as Control)


func _check_reachable(body: ScrollContainer, column: ScrollContainer, control: Control) -> void:
	column.ensure_control_visible(control)
	await process_frame
	body.ensure_control_visible(control)
	await process_frame
	_check(column.get_global_rect().encloses(control.get_global_rect()),
		"Control cannot be reached vertically: " + str(control.name))
	_check(body.get_global_rect().encloses(control.get_global_rect()),
		"Control cannot be reached horizontally: " + str(control.name))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_layout_failed = true
		push_error(message)


func _save_frame(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://reports/workbench/" + filename)
	if error != OK:
		push_error("Capture failed: " + error_string(error))
		quit(1)


func _button(node: Node, text: String) -> Button:
	for child: Node in node.find_children("*", "Button", true, false):
		if (child as Button).text == text:
			return child as Button
	return null
