# gdlint:ignore-file:file-length=559
# gdlint:ignore-file:god-class-functions=24
# 保留原因：公开函数是 22 个测试用例加前后准备，全部共用同一个真实窗口夹具；拆文件要复制夹具或新建夹具基类。用户同意于 2026-10-08，2026-10-18 按实际数更新。
extends GdUnitTestSuite

const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const PINS := "user://debug/pinned-slots.json"
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Playback := preload("res://dev/debug/_shared/playback_controller.gd")
const Controls := preload("res://dev/debug/_shared/property_controls.gd")
const Dialogs := preload("res://dev/debug/_shared/debug_dialogs.gd")
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


func test_status_bar_shows_plain_words_and_keeps_raw_details() -> void:
	_window.show()
	_window.report({"error": ERR_INVALID_DATA, "message": "res://dev/x.tres",
		"issues": PackedStringArray(["volume_db"])})
	var shown: String = _window.status.message.text
	assert_str(shown).is_equal("这一步没有完成：文件内容和当前参数对不上。点“详情”看原始信息")
	assert_bool(_window.status.details.visible).is_true()
	assert_str(_window.status.detail_text.text).contains("res://dev/x.tres")
	assert_str(_window.status.detail_text.text).contains("Invalid data")
	assert_bool(_window.status.detail_text.is_visible_in_tree()).is_false()
	_window.status.details.pressed.emit()
	assert_bool(_window.status.detail_text.is_visible_in_tree()).is_true()


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
	assert_array(groups).contains_exactly(["样例", "反馈", "共享"])
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
	# Nothing is edited or playing yet, so neither state may be claimed.
	assert_bool(bare.status._combo_note.visible).is_false()
	assert_bool(bare.status._unsaved.visible).is_false()
	assert_bool(bare.toolbar.lock_chip.visible).is_false()
	bare.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.remove_absolute(empty)


## "另存" never overwrites silently: the name box offers a free name, and a taken name asks
## first, naming the combos that use it. "换个名字" writes nothing.
func test_save_preset_as_an_existing_name_asks_before_overwriting() -> void:
	var directory := "user://tests/debug-save-as-%d" % Time.get_ticks_usec()
	_window.session.store.root = directory
	var slot := _slot(EFFECT)
	slot.preset_name = "甲"
	assert_int(_window.session.store.save_slot(slot, "甲").error).is_equal(OK)
	assert_int(_window.session.save_combo("组A").error).is_equal(OK)
	var path: String = _window.session.store.preset_path(slot.id, "甲")
	var original := FileAccess.get_file_as_bytes(path)
	slot.live.candidate_params.size += 10.0
	_window.session.select_slot(slot)
	_window._slot_command("另存")
	assert_str(_name_box().text).is_equal("甲-2")
	_name_box().text = "甲"
	_window.dialogs.current.get_ok_button().pressed.emit()
	assert_str(_window.dialogs.current.dialog_text.replace(Dialogs.WORD_JOINER, "")).starts_with(
		"预设“甲”已存在，保存会覆盖它。它被 1 个组合使用（“组A”），覆盖后它们也会变。")
	_assert_overwrite_buttons()
	_window.dialogs.button("换个名字").pressed.emit()
	assert_array(FileAccess.get_file_as_bytes(path)).is_equal(original)
	assert_str(_name_box().text).is_equal("甲-2")
	_name_box().text = "甲"
	_window.dialogs.current.get_ok_button().pressed.emit()
	_window.dialogs.button("覆盖").pressed.emit()
	assert_str(_window.status.message.text).is_equal("已保存预设 甲，游戏文件不变")
	assert_array(FileAccess.get_file_as_bytes(path)).is_not_equal(original)
	slot.preset_name = ""
	_window.session.forget_combo()
	_remove(directory)


func test_save_combo_as_an_existing_name_asks_before_overwriting() -> void:
	var directory := "user://tests/debug-save-combo-as-%d" % Time.get_ticks_usec()
	_window.session.store.root = directory
	assert_int(_window.session.save_combo("组A").error).is_equal(OK)
	var path: String = _window.session.store.combo_path(_window.session.active.id, "组A")
	var original := FileAccess.get_file_as_bytes(path)
	_window.presets.save_combo("另存组合")
	assert_str(_name_box().text).is_equal("组A-2")
	_name_box().text = "组A"
	_window.dialogs.current.get_ok_button().pressed.emit()
	assert_str(_window.dialogs.current.dialog_text.replace(Dialogs.WORD_JOINER, "")).starts_with(
		"组合“组A”已存在，保存会覆盖它。")
	_assert_overwrite_buttons()
	_window.dialogs.button("换个名字").pressed.emit()
	assert_array(FileAccess.get_file_as_bytes(path)).is_equal(original)
	assert_str(_name_box().text).is_equal("组A-2")
	_window.dialogs.button("取消").pressed.emit()
	_window.session.forget_combo()
	_remove(directory)


## slot.gd's value_text words the value box and the revert tooltip; typing still sees numbers.
func test_value_text_words_the_value_box_and_the_revert_tooltip() -> void:
	var timing := _slot("sample/timing")
	_window.slot_list.items[timing.id].pressed.emit()
	var number := _row("hold").find_children("*", "SpinBox", true, false)[0] as SpinBox
	await get_tree().process_frame
	assert_str(number.get_line_edit().text).is_equal("300 ms")
	number.value = 0.45
	await get_tree().process_frame
	assert_str(number.get_line_edit().text).is_equal("450 ms")
	assert_float(timing.live.hold).is_equal_approx(0.45, 0.0001)
	assert_str(_row("hold").revert.tooltip_text).is_equal("还原这一项（游戏原值：300 ms）")


func test_target_dropdown_shows_each_targets_title() -> void:
	var names: PackedStringArray = []
	var menu: PopupMenu = _window.toolbar.target.get_popup()
	for index in range(menu.item_count):
		names.append(menu.get_item_text(index))
	assert_array(names).contains_exactly_in_any_order(["样例", "共享"])
	assert_str(_window.toolbar.target.value_label.text).is_equal("样例")
	assert_str(_window.toolbar.target.tooltip_text).is_equal(
		"调试对象：列表显示它和“共享”的插槽；切换场景时自动跟随")


func test_empty_list_names_the_filter_and_the_search() -> void:
	var list: Control = _window.slot_list
	list.search.text = "不存在的插槽"
	list.refresh(true)
	assert_str(_empty_hint()).is_equal(
		"筛选“全部”、搜索“不存在的插槽”：没有符合条件的插槽。清空搜索框可看到所有插槽")
	list.set_filter(list.Filter.MODIFIED)
	assert_str(_empty_hint()).is_equal("筛选“已修改”、搜索“不存在的插槽”：没有符合条件的插槽。"
		+ "点“全部”并清空搜索框可看到所有插槽")
	list.search.text = ""
	list.set_filter(list.Filter.PINNED)
	assert_str(_empty_hint()).is_equal("筛选“钉选”：没有符合条件的插槽。点“全部”可看到所有插槽")


## A result clears after real seconds or on the next edit; open details and the startup notes stay.
func test_status_result_clears_on_edit_and_timeout_but_keeps_open_details_and_notes() -> void:
	var status: Control = _window.status
	assert_bool(status.clear_timer.ignore_time_scale).is_true()
	_window.report({"error": OK, "text": "已保存预设 甲，游戏文件不变"})
	assert_bool(status.clear_timer.is_stopped()).is_false()
	status.clear_timer.timeout.emit()
	assert_str(status.message.text).is_empty()
	_window.slot_list.items[EFFECT].pressed.emit()
	_window.report({"error": OK, "text": "已保存预设 甲，游戏文件不变"})
	var size := _row("candidate_params/size").find_children("*", "SpinBox", true, false)[0] as SpinBox
	size.value += 5.0
	assert_str(status.message.text).is_empty()
	_window.report({"error": ERR_INVALID_DATA, "message": "res://dev/x.tres"})
	status.details.pressed.emit()
	status.clear_timer.timeout.emit()
	size.value += 5.0
	assert_str(status.message.text).is_not_empty()
	status.details.pressed.emit()
	assert_bool(status.clear_timer.is_stopped()).is_false()
	_window.configure("")
	assert_bool(status.clear_timer.is_stopped()).is_true()
	status.clear_timer.timeout.emit()
	size.value += 5.0
	_window.report({"error": OK})
	assert_str(status.message.text).is_equal(_window.NO_SAVE_HOOK)


## Locked dropdowns, row buttons, sliders and value boxes say why; unlocking brings back their
## own tooltips.
func test_locked_controls_explain_why_and_get_their_tooltips_back() -> void:
	var sfx := _slot("sample/feedback/sound")
	_window.slot_list.items[sfx.id].pressed.emit()
	sfx.live.volume_db += 3.0
	var revert: Button = _row("volume_db").revert
	var tooltip := revert.tooltip_text
	assert_str(tooltip).is_equal("还原这一项（游戏原值：-6 dB）")
	var mode := _row("pitch_mode").find_children("*", "OptionButton", true, false)[0] as OptionButton
	var slider := _row("volume_db").find_children("*", "HSlider", true, false)[0] as HSlider
	var box := (_row("volume_db").find_children("*", "SpinBox", true, false)[0] as SpinBox) \
		.get_line_edit()
	_window.playback.state = Playback.State.PAUSED
	_window.playback.changed.emit()
	assert_bool(mode.disabled and revert.disabled).is_true()
	assert_bool(slider.editable or box.editable).is_false()
	for control: Control in [mode, revert, slider, box]:
		assert_str(control.tooltip_text).is_equal(_window.LOCKED_PLAYING)
	_window.playback.cancel()
	assert_bool(mode.disabled or revert.disabled).is_false()
	assert_bool(slider.editable and box.editable).is_true()
	for control: Control in [mode, slider, box]:
		assert_str(control.tooltip_text).is_empty()
	assert_str(revert.tooltip_text).is_equal(tooltip)
	var check := CheckBox.new()
	Controls.set_locked(check, true, "原因")
	assert_str(check.tooltip_text).is_equal("原因")
	Controls.set_locked(check, false, "原因")
	assert_str(check.tooltip_text).is_empty()
	check.free()


## "一并保存" lists where each unsaved slot goes, including a new name beside a preset that
## another combo uses.
func test_saving_a_combo_with_unsaved_slots_lists_their_presets_first() -> void:
	var directory := "user://tests/debug-combo-plan-%d" % Time.get_ticks_usec()
	_window.session.store.root = directory
	var effect := _slot(EFFECT)
	var sound := _slot("sample/feedback/sound")
	assert_int(_window.session.store.save_slot(effect, "甲").error).is_equal(OK)
	assert_int(_window.session.save_combo("组A").error).is_equal(OK)
	_window.session.forget_combo()
	effect.live.candidate_params.size += 10.0
	sound.live.volume_db += 3.0
	_window.presets.save_combo("另存组合")
	_name_box().text = "组B"
	_window.dialogs.current.get_ok_button().pressed.emit()
	assert_str(_window.dialogs.current.dialog_text.replace(Dialogs.WORD_JOINER, "").strip_edges()) \
		.is_equal("组合只记录每个插槽用哪个预设，有未保存改动的插槽要先存成预设。“一并保存”会：\n"
			+ "· 点击特效：预设“甲”被组合“组A”使用，改存为新预设“甲-组B”\n"
			+ "· 按钮音效：新建预设“组B”\n\n然后保存组合“组B”。游戏文件不变。")
	assert_bool(FileAccess.file_exists(_window.session.store.combo_path("sample", "组B"))).is_false()
	_window.dialogs.button("一并保存").pressed.emit()
	assert_str(_window.status.message.text).is_equal("已保存组合 组B，游戏文件不变；"
		+ "预设 甲 被组合 组A 使用，已把 点击特效 的改动另存为 甲-组B")
	assert_str(effect.preset_name).is_equal("甲-组B")
	assert_str(sound.preset_name).is_equal("组B")
	effect.preset_name = ""
	sound.preset_name = ""
	_window.session.forget_combo()
	_remove(directory)


func _empty_hint() -> String:
	return (_window.slot_list.find_child("Empty", true, false) as Label).text


func _name_box() -> LineEdit:
	return _window.dialogs.current.find_children("*", "LineEdit", true, false)[0] as LineEdit


func _assert_overwrite_buttons() -> void:
	var order: PackedStringArray = []
	var styles: Array[StringName] = []
	for button in _window.dialogs.current.get_ok_button().get_parent().get_children():
		if button is Button and button.visible:
			order.append(button.text)
			styles.append(button.theme_type_variation)
	assert_array(order).contains_exactly(["覆盖", "换个名字", "取消"])
	assert_array(styles).contains_exactly([&"DangerButton", &"", &""])


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
