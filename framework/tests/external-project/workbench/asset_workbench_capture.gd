extends SceneTree

## External-project render check. Needs a real renderer; it is not human acceptance.

const GameScene = preload("res://yaya/asset_workbench/examples/single/example_game.tscn")
const OUTPUT: String = "res://reports/asset-workbench-ui-20260922/"

var _layout_failed: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Capture requires a rendering display driver.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for entry: String in ["single", "composition", "shader_composition"]:
		await _capture_entry(entry)
	root.size = Vector2i(1600, 900)
	await _capture_game()


func _capture_entry(entry: String) -> void:
	root.size = Vector2i(1600, 900)
	var path := "res://yaya/asset_workbench/examples/" + entry + "/example_workbench.tscn"
	var workbench: Control = load(path).instantiate()
	root.add_child(workbench)
	await process_frame
	await process_frame
	await _exercise_input(workbench)
	var candidates := workbench.find_children("*", "ItemList", true, false)[0] as ItemList
	candidates.select(0)
	candidates.item_selected.emit(0)
	workbench.presenter.trigger()
	await create_timer(0.15).timeout
	_check_fixed_actions(workbench, root.size)
	await _save_frame(entry + "-light.png")
	workbench.stop_all()
	workbench.call("_set_dark_theme", true)
	workbench.call("_set_checker", true)
	await _save_frame(entry + "-dark.png")
	for resolution: Vector2i in [Vector2i(1152, 648), Vector2i(900, 540), Vector2i(720, 480)]:
		await _check_compact_window(workbench, resolution, entry)
	workbench.queue_free()
	await process_frame


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
	var file := FileAccess.open(OUTPUT + "layout-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": not _layout_failed,
		"sizes": [[1600, 900], [1152, 648], [900, 540], [720, 480]],
		"entries": ["single", "composition", "shader_composition"]}, "  "))
	file.close()
	quit(1 if _layout_failed else 0)


func _check_compact_window(workbench: Control, resolution: Vector2i, entry: String) -> void:
	root.size = resolution
	await process_frame
	await process_frame
	var layout: Control = workbench.get("_ui")
	var parameters := workbench.find_child("ParameterColumn", true, false) as ScrollContainer
	var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
	_check(root.size == resolution, "The requested client size was overridden.")
	for index: int in 3:
		layout.call("_show_region", index)
		await process_frame
		await process_frame
		_check_fixed_actions(workbench, resolution)
		if index == 0:
			var list: ItemList = workbench.get("_browser").get("_list")
			_check(viewport.encloses(list.get_global_rect()), "Candidates escaped viewport")
			list.select(2)
			list.item_selected.emit(2)
			list.ensure_current_is_visible()
			await process_frame
			await process_frame
			_check_fixed_actions(workbench, resolution)
			await _save_frame("%s-audio-%dx%d.png" % [entry, resolution.x, resolution.y])
			list.select(0)
			list.item_selected.emit(0)
			list.ensure_current_is_visible()
			await process_frame
		elif index == 2:
			var shader: Control = workbench.get("_controls").get("_shader")
			await _check_reachable(parameters, shader.get("_duration"))
			_check_fixed_actions(workbench, resolution)
		var suffix := "%s-%dx%d-%d.png" % [entry, resolution.x, resolution.y, index]
		await _save_frame(suffix)


func _exercise_input(workbench: Control) -> void:
	var browser: Control = workbench.get("_browser")
	var list: ItemList = browser.get("_list")
	var original: Texture2D = workbench.session.current().texture
	var item_rect := list.get_item_rect(1)
	await _click(list.global_position + item_rect.get_center())
	_check(browser.call("selected_path").ends_with("example_star.png"), "Pointer selection failed")
	_check(workbench.session.current().texture == original, "Browsing must not bind")
	await _click(browser.get("_apply").get_global_rect().get_center())
	_check(workbench.session.current().texture.resource_path.ends_with("example_star.png"),
		"Explicit apply button is not clickable")
	_check(workbench.session.drafts[1].texture == original, "Apply changed the other trial")
	workbench.call("_reset_trial")
	var appearance: MenuButton = workbench.get("_ui").get("_appearance")
	appearance.grab_focus()
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)
	await process_frame
	_check(appearance.get_popup().visible, "Appearance menu cannot open from keyboard")
	appearance.get_popup().hide()
	await process_frame


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


func _check_reachable(column: ScrollContainer, control: Control) -> void:
	column.ensure_control_visible(control)
	await process_frame
	_check(column.get_global_rect().encloses(control.get_global_rect()),
		"Control cannot be reached vertically: " + str(control.name))


func _check_fixed_actions(workbench: Control, resolution: Vector2i) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(resolution)).grow(1)
	var body: Control = workbench.find_child("WorkbenchBody", true, false)
	_check(viewport.encloses(body.get_global_rect()), "Workspace escaped viewport")
	_check(viewport.encloses(workbench.get("_status").get_global_rect()), "Status escaped viewport")
	for caption: String in ["停止全部", "保存当前方案"]:
		var count: int = 0
		for node: Node in workbench.find_children("*", "Button", true, false):
			var button := node as Button
			if button.text == caption and button.is_visible_in_tree():
				count += 1
				_check(viewport.encloses(button.get_global_rect()), caption + " escaped viewport")
				button.grab_focus()
				_check(root.gui_get_focus_owner() == button, caption + " is not focusable")
		_check(count == 1, "Expected one visible action: " + caption)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_layout_failed = true
		push_error(message)


func _save_frame(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT + filename)
	if error != OK:
		push_error("Capture failed: " + error_string(error))
		quit(1)
