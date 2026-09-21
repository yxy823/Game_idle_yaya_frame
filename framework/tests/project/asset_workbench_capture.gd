extends SceneTree

## External-project render check. Needs a real renderer; it is not human acceptance.

const WorkbenchScene = preload("res://examples/asset_workbench/example-workbench.tscn")
const GameScene = preload("res://examples/asset_workbench/example-game.tscn")


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
	root.size = Vector2i(1100, 860)
	await _save_frame("workbench-minimum.png")
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
	quit(0)


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
