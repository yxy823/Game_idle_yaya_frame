extends GdUnitTestSuite
## Exercise long confirmation layout without enlarging the shared debug-window fixture.

const Dialogs := preload("res://dev/debug/_shared/debug_dialogs.gd")


func test_long_body_scrolls_to_the_end_and_keeps_actions_inside_the_host() -> void:
	var host := auto_free(Window.new()) as Window
	host.size = Vector2i(720, 480)
	host.hide()
	host.force_native = true
	get_tree().root.add_child(host)
	host.show()
	var dialogs := Dialogs.new()
	dialogs.host = host
	host.add_child(dialogs)
	dialogs.ask("将修改的游戏文件：\n".repeat(100) + "正文最后一行",
		[["采纳", Dialogs.DANGER, func() -> void: host.hide()],
		["换个名字", Dialogs.PLAIN, func() -> void: host.hide()]])
	await get_tree().process_frame
	await get_tree().process_frame
	var dialog := dialogs.current
	var label := dialog.get_label()
	var scroll := label.get_parent() as ScrollContainer
	assert_bool(scroll.get_v_scroll_bar().visible).is_true()
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await get_tree().process_frame
	assert_float(label.position.y + label.size.y).is_less_equal(scroll.size.y + 1.0)
	assert_str(label.text.strip_edges()).ends_with("正文最后一行")
	assert_int(dialog.size.y).is_less_equal(host.size.y)
	var bounds := Rect2(Vector2.ZERO, Vector2(dialog.size))
	for caption: String in ["采纳", "换个名字", "取消"]:
		assert_bool(bounds.encloses(dialogs.button(caption).get_global_rect())).is_true()
	assert_bool(dialogs.button("采纳").get_parent().is_ancestor_of(scroll)).is_false()
	dialogs.button("取消").pressed.emit()
	await get_tree().process_frame
	assert_bool(is_instance_valid(dialog)).is_false()
