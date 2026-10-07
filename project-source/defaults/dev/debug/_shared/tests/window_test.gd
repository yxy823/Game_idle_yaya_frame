extends GdUnitTestSuite

const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const PINS := "user://debug/pinned-slots.json"
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Playback := preload("res://dev/debug/_shared/playback_controller.gd")
const Params := preload("res://dev/debug/_shared/tests/fixtures/params.gd")
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const EFFECT := "sample/feedback/effect"

var _window: Window
var _defaults: Dictionary


func before_test() -> void:
	Session.pins_path = "user://tests/debug-pins-%d.json" % Time.get_ticks_usec()
	Session.game_root = SAMPLE + "game"
	Session.debug_root = SAMPLE + "debug"
	_window = WINDOW.instantiate() as Window
	_window.force_native = true
	get_tree().root.add_child(_window)
	_window.configure("user://tests/debug-window-save.json")
	_defaults = {}
	for slot: Slot in _window.session.slots:
		var values: Dictionary = {}
		for field in Codec.fields(slot.live):
			values[field.name] = Codec.copy_value(slot.live.get(field.name))
		_defaults[slot.id] = values


func after_test() -> void:
	for slot: Slot in _window.session.slots:
		Codec.apply_fields(slot.live, _defaults[slot.id])
	_window.queue_free()
	await get_tree().process_frame
	# The persistent root input bridge queues its own removal in window._exit_tree.
	await get_tree().process_frame
	# Only now: restoring the values above may still save pins, which belong to the test file.
	DirAccess.remove_absolute(Session.pins_path)
	Session.pins_path = PINS
	Session.game_root = "res://game"
	Session.debug_root = "res://dev/debug"


func test_root_and_debug_viewports_receive_shortcuts_before_text_fields() -> void:
	_window.show()
	var input := LineEdit.new()
	_window.add_child(input)
	input.grab_focus()
	_send(_window, KEY_F1)
	assert_bool(_window.visible).is_false()
	_send(get_tree().root, KEY_F1)
	assert_bool(_window.visible).is_true()
	_send(_window, KEY_F1, true)
	assert_bool(_window.visible).is_true()
	assert_str(input.text).is_empty()


func test_embedded_popup_has_its_own_input_bridge_and_close_hides_window() -> void:
	var popup := PopupPanel.new()
	_window.add_child(popup)
	await get_tree().process_frame
	assert_bool(popup.force_native).is_false()
	assert_bool(popup.has_node("DebugInputBridge")).is_true()
	_window.show()
	_send(popup, KEY_F1)
	assert_bool(_window.visible).is_false()
	_send(get_tree().root, KEY_F1)
	_window.close_requested.emit()
	assert_bool(_window.visible).is_false()
	assert_bool(_window.is_inside_tree()).is_true()


func test_grave_switches_to_game_values_once_and_consumes_character_in_text_field() -> void:
	var slot := _slot(EFFECT)
	var edited: float = slot.live.candidate_params.size + 10.0
	slot.live.candidate_params.size = edited
	_window.show()
	var input := LineEdit.new()
	_window.add_child(input)
	input.grab_focus()
	_send(_window, KEY_QUOTELEFT)
	assert_bool(_window.session.comparing).is_true()
	assert_float(slot.live.candidate_params.size).is_equal(edited - 10.0)
	assert_str(input.text).is_empty()
	_send(_window, KEY_QUOTELEFT, true)
	assert_bool(_window.session.comparing).is_true()
	_send(get_tree().root, KEY_QUOTELEFT)
	assert_bool(_window.session.comparing).is_false()
	assert_float(slot.live.candidate_params.size).is_equal(edited)


func test_grave_without_changes_only_hints() -> void:
	_send(get_tree().root, KEY_QUOTELEFT)
	assert_bool(_window.session.comparing).is_false()
	assert_str(_window.status.message.text).is_equal("还没有改动可对比")
	assert_bool(_window.status.details.visible).is_false()


func test_panel_editing_uses_live_resource_and_locks_while_paused() -> void:
	var slot: Slot = _window.session.slots[0]
	_window.session.select_slot(slot)
	_window.panel.bind(slot, _window.session.store.list_names)
	assert_bool(_window.panel.slot.live == ResourceLoader.load(slot.game_path)).is_true()
	_window.playback.state = Playback.State.PAUSED
	_window.playback.changed.emit()
	assert_bool(_window.panel.locked).is_true()
	assert_bool(_window.compare.save.disabled).is_true()
	assert_bool(_window.compare.compare_menu.disabled).is_false()
	assert_bool(_window.toolbar.lock_chip.visible).is_true()
	assert_bool(_window.panel.adopt.disabled).is_true()
	assert_str(_window.toolbar.playback_status.text).is_equal("已暂停")
	_window.playback.cancel()
	assert_bool(_window.panel.locked).is_false()
	assert_bool(_window.compare.save.disabled).is_false()


func test_only_selected_slot_creates_parameter_controls() -> void:
	assert_array(_window.panel.rows).is_empty()
	assert_bool(_window.panel.slot == null).is_true()
	var slot: Slot = _window.session.slots[0]
	_window.session.select_slot(slot)
	_window.panel.bind(slot, _window.session.store.list_names)
	assert_bool(_window.panel.slot == slot).is_true()
	assert_array(_window.panel.rows).is_not_empty()
	assert_int(_window.session.slots.size()).is_equal(4)


func test_list_selection_names_rows_and_marks_then_reverts_one_field() -> void:
	assert_int(_window.slot_list.items.size()).is_equal(4)
	_window.slot_list.items[EFFECT].pressed.emit()
	var slot: Slot = _window.session.selected
	assert_str(slot.id).is_equal(EFFECT)
	assert_str(_window.panel.title.text).is_equal("点击特效")
	assert_str(_window.slot_list.items[slot.id].text).is_equal("点击特效")
	var row := _row("candidate_params/size")
	assert_str(row.caption.text).is_equal("尺寸")
	var original: float = slot.live.candidate_params.size
	slot.live.candidate_params.size = original + 20.0
	assert_bool(row.modified and row.revert.visible).is_true()
	assert_bool(_window.slot_list.items[slot.id].get_node("Marks/Dot").visible).is_true()
	_window.slot_list.set_filter(_window.slot_list.Filter.MODIFIED)
	assert_array(_window.slot_list.items.keys()).contains_exactly([slot.id])
	row.revert.pressed.emit()
	assert_float(slot.live.candidate_params.size).is_equal(original)
	assert_bool(_row("candidate_params/size").modified).is_false()
	assert_array(_window.slot_list.items.keys()).is_empty()


func test_compare_bar_counts_differences_shows_the_side_and_the_deferred_switch() -> void:
	var slot := _slot(EFFECT)
	assert_str(_chip(_window.compare.differences)).is_equal("0 处不同")
	slot.live.candidate_params.size += 10.0
	assert_str(_chip(_window.compare.differences)).is_equal("1 处不同")
	assert_bool(_window.compare.current_side.button_pressed).is_true()
	assert_bool(_window.compare.compare_side.button_pressed).is_false()
	_window.playback.state = Playback.State.PLAYING
	_window.playback.changed.emit()
	_send(get_tree().root, KEY_QUOTELEFT)
	assert_bool(_window.compare.pending.visible).is_true()
	assert_str(_chip(_window.compare.pending)).is_equal("下一遍切到游戏原值")
	assert_str(_window.compare.pending.theme_type_variation).is_equal("ChipAccent")
	assert_str(_window.toolbar.lock_chip.theme_type_variation).is_equal("Chip")
	assert_bool(_window.compare.current_side.button_pressed).is_true()
	_window.playback.next_pass.emit()
	assert_bool(_window.compare.compare_side.button_pressed).is_true()
	assert_bool(_window.compare.pending.visible).is_false()
	assert_str(_chip(_window.compare.differences)).is_equal("1 处不同")
	_window.playback.cancel()
	assert_bool(_window.panel.locked).is_true()
	assert_bool(_window.panel.adopt.disabled).is_true()
	assert_bool(_window.compare.save.disabled).is_true()
	_send(get_tree().root, KEY_QUOTELEFT)
	assert_bool(_window.panel.locked).is_false()


func test_tabs_switch_pages_without_touching_playback() -> void:
	assert_bool(_window.tabs[0].button_pressed).is_true()
	assert_bool(_window.pages[0].visible and not _window.pages[1].visible).is_true()
	_window.playback.state = Playback.State.PLAYING
	_window.tabs[1].pressed.emit()
	assert_bool(_window.pages[1].visible and not _window.pages[0].visible).is_true()
	assert_bool(_window.screenshots.is_visible_in_tree() or not _window.visible).is_true()
	assert_str(_window.screenshots.capture_button.text).is_equal("截图分析")
	assert_int(_window.playback.state).is_equal(Playback.State.PLAYING)
	_window.tabs[0].pressed.emit()
	assert_bool(_window.pages[0].visible).is_true()
	_window.playback.cancel()


func test_status_bar_shows_plain_words_and_keeps_raw_details() -> void:
	_window.report({"error": ERR_INVALID_DATA, "message": "res://dev/x.tres",
		"issues": PackedStringArray(["volume_db"])})
	var shown: String = _window.status.message.text
	assert_str(shown).is_equal("这一步没有完成：文件内容和当前参数对不上。点“详情”看原始信息")
	assert_bool(_window.status.details.visible).is_true()
	assert_str(_window.status.detail_text.text).contains("res://dev/x.tres")
	assert_str(_window.status.detail_text.text).contains("Invalid data")
	_window.status.details.pressed.emit()
	assert_bool(_window.status.detail_text.is_visible_in_tree() or not _window.visible).is_true()


func test_closing_the_game_with_unsaved_edits_asks_first() -> void:
	var quits: Array[int] = []
	_window.quit_game = func() -> void: quits.append(1)
	_window.get_tree().root.close_requested.emit()
	assert_int(quits.size()).is_equal(1)
	var slot := _slot(EFFECT)
	slot.live.candidate_params.size += 10.0
	_window.get_tree().root.close_requested.emit()
	var dialog: AcceptDialog = _window.dialogs.current
	assert_str(dialog.dialog_text).starts_with("有 1 个插槽的改动还没保存，关闭后会丢失。")
	var order: PackedStringArray = []
	var styles: Array[StringName] = []
	for button in dialog.get_ok_button().get_parent().get_children():
		if button is Button and button.visible:
			order.append(button.text)
			styles.append(button.theme_type_variation)
	assert_array(order).contains_exactly(["保存", "不保存直接关闭", "取消"])
	assert_array(styles).contains_exactly([&"PrimaryButton", &"DangerButton", &""])
	_window.dialogs.button("取消").pressed.emit()
	assert_int(quits.size()).is_equal(1)
	_window.get_tree().root.close_requested.emit()
	_window.dialogs.button("不保存直接关闭").pressed.emit()
	assert_int(quits.size()).is_equal(2)
	assert_bool(slot.is_dirty()).is_true()


func test_saving_on_close_stores_presets_then_quits() -> void:
	var directory := "user://tests/debug-close-%d" % Time.get_ticks_usec()
	_window.session.store.root = directory
	var quits: Array[int] = []
	_window.quit_game = func() -> void: quits.append(1)
	var slot := _slot(EFFECT)
	slot.live.candidate_params.size += 10.0
	_window.get_tree().root.close_requested.emit()
	_window.dialogs.current.get_ok_button().pressed.emit()
	assert_int(quits.size()).is_equal(1)
	assert_bool(slot.is_dirty()).is_false()
	assert_str(slot.preset_name).starts_with("关闭前-")
	assert_bool(FileAccess.file_exists(_window.session.store.preset_path(slot.id,
		slot.preset_name))).is_true()
	slot.preset_name = ""
	_remove(directory)


func test_groups_candidates_and_value_boxes_use_chinese_names_and_units() -> void:
	var groups: PackedStringArray = []
	for button: Button in _window.slot_list.find_children("*", "Button", true, false):
		if button.theme_type_variation == &"GroupHeader":
			groups.append(button.text)
	assert_array(groups).contains_exactly(["样例", "反馈", "全局"])
	var slot := _slot(EFFECT)
	# Fixed values: the adopted ones can change through the debug window.
	var params: Resource = (load(SAMPLE + "game/sample/feedback/effect/ring/ring_params.gd") as Script).new()
	params.frame_count = 27
	params.fps = 30.0
	params.size = 100.0
	slot.live.candidate = load(SAMPLE + "game/sample/feedback/effect/ring/ring_effect.tscn")
	slot.live.candidate_params = params
	_window.slot_list.items[EFFECT].pressed.emit()
	await get_tree().process_frame
	var adopted := _window.panel.find_child("Candidate0", true, false) as Button
	assert_bool(_labels(adopted).has(slot.candidate_title(slot.disk_defaults().candidate))).is_true()
	var values: PackedStringArray = []
	for edit: LineEdit in _window.panel.find_children("*", "LineEdit", true, false):
		values.append(edit.text)
	assert_array(values).contains(["27", "30 fps", "100 px"])


func test_pinned_slots_lead_the_list_and_enum_values_read_in_chinese() -> void:
	var sfx := _slot("sample/feedback/sound")
	sfx.pinned = true
	_window.slot_list.refresh()
	var groups: PackedStringArray = []
	for button: Button in _window.slot_list.find_children("*", "Button", true, false):
		if button.theme_type_variation == &"GroupHeader":
			groups.append(button.text)
	assert_str(groups[0]).is_equal("钉选")
	assert_str((_window.slot_list.items.values()[0] as Button).text).is_equal("按钮音效")
	_window.slot_list.items[sfx.id].pressed.emit()
	var choices: PackedStringArray = []
	for dropdown: OptionButton in _window.panel.find_children("*", "OptionButton", true, false):
		for index in range(dropdown.item_count):
			choices.append(dropdown.get_item_text(index))
	assert_array(choices).contains(["固定", "逐轮升高"])
	_window.panel._pin.toggled.emit(true)
	var restarted := WINDOW.instantiate() as Window
	get_tree().root.add_child(restarted)
	for slot: Slot in restarted.session.slots:
		assert_bool(slot.pinned).is_equal(slot.id == sfx.id)
	restarted.queue_free()
	await get_tree().process_frame
	sfx.pinned = false


func test_status_bar_says_when_targets_or_the_debug_save_are_missing() -> void:
	assert_str(_window.status.message.text).is_empty()
	_window.configure("")
	assert_str(_window.status.message.text).is_equal(_window.NO_SAVE_HOOK)
	var empty := "user://tests/debug-empty-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(empty)
	Session.game_root = empty
	var bare := WINDOW.instantiate() as Window
	get_tree().root.add_child(bare)
	bare.configure("")
	assert_array(bare.session.targets).is_empty()
	assert_str(bare.status.message.text).is_equal(
		"还没有调试对象：在 dev/debug/<对象>/ 下添加；调试会话可能写入真实存档：在 dev/debug/debug_project.gd 设置调试存档位置")
	bare.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.remove_absolute(empty)


func _labels(node: Node) -> PackedStringArray:
	var texts: PackedStringArray = []
	for label: Label in node.find_children("*", "Label", true, false):
		texts.append(label.text)
	return texts


func _slot(identity: String) -> Slot:
	for slot: Slot in _window.session.slots:
		if slot.id == identity:
			return slot
	return null


func _row(path: String) -> Control:
	for row in _window.panel.rows:
		if row.path == path:
			return row
	return null


func _chip(chip: Control) -> String:
	return (chip.get_node("Row/Text") as Label).text


func _remove(directory: String) -> void:
	for child in DirAccess.get_directories_at(directory):
		_remove(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)


func _send(viewport: Viewport, code: Key, echo: bool = false) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.keycode = code
	key.unicode = 96 if code == KEY_QUOTELEFT else 0
	key.pressed = true
	key.echo = echo
	viewport.push_input(key, true)
