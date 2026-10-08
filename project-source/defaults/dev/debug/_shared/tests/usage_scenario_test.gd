extends GdUnitTestSuite
## Walks _shared/usage-scenarios.md headless through the real window on the sample game: pick a
## sound, adopt it and hear it in the game, compare an edit with the game values, adopt again,
## open analysis. The sound slot is a user:// copy, so no dev/ or game/ file changes. Prints
## what each step shows.

const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Dialogs := preload("res://dev/debug/_shared/debug_dialogs.gd")
const PINS := "user://debug/pinned-slots.json"
const Fixture := preload("res://dev/debug/_shared/tests/fixtures/adoption_fixture.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
## Paths, not preloads: a test-script constant holding a script that cached tuning resources
## use leaks at exit.
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const MAIN := SAMPLE + "game/sample/sample_main.tscn"
const GAME := SAMPLE + "game/sample/sample_game.gd"
const SOUND := "sample/feedback/sound"
const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")

var _window: Window
var _fixture: Fixture
var _sound: Slot
var _defaults: Dictionary = {}
var _seen: PackedStringArray = []
## UID paths as the editor's cache knew them before the adoption moved the files.
var _stale: Dictionary = {}


func before_test() -> void:
	Session.pins_path = "user://tests/debug-pins-%d.json" % Time.get_ticks_usec()
	Session.game_root = SAMPLE + "game"
	Session.debug_root = SAMPLE + "debug"
	_window = WINDOW.instantiate() as Window
	_window.force_native = true
	get_tree().root.add_child(_window)
	_window.configure("user://tests/debug-usage-save.json")
	for slot: Slot in _window.session.slots:
		var values: Dictionary = {}
		for field in Codec.fields(slot.live):
			values[field.name] = Codec.copy_value(slot.live.get(field.name))
		_defaults[slot.id] = values
	_fixture = Fixture.new()
	_window.session.store.root = _fixture.root.path_join("presets")
	_sound = _fixture.sound_slot()
	var index: int = _window.session.slots.find(_slot(SOUND))
	_window.session.slots[index] = _sound
	_sound.changed.connect(_window.session.changed.emit)
	# The comparison cached the real slot's game values before the swap.
	_window.session.invalidate_compare()
	_window.slot_list.refresh(true)
	_seen.clear()
	_stale.clear()
	for number in _fixture.uids:
		_stale[number] = ResourceUID.get_id_path(number)


func after_test() -> void:
	for slot: Slot in _window.session.slots:
		if _defaults.has(slot.id) and slot != _sound:
			Codec.apply_fields(slot.live, _defaults[slot.id])
	_window.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# Only now: restoring the values above may still save pins, which belong to the test file.
	DirAccess.remove_absolute(Session.pins_path)
	Session.pins_path = PINS
	Session.game_root = "res://game"
	Session.debug_root = "res://dev/debug"
	_fixture.cleanup()
	# The walkthrough texts go to the engine log for review.
	printerr("\n".join(_seen))


func test_adopt_a_sound_compare_an_edit_and_open_analysis() -> void:
	_see("场景 1 打开", "%s 页 · %s" % [_window.tabs[0].text, _window.panel.title.text])
	assert_bool(_window.pages[0].visible).is_true()
	_send_grave()
	_see("场景 3 没有改动时按 `", _status())
	assert_str(_status()).is_equal("还没有改动可对比")
	_window.slot_list.items[_sound.id].pressed.emit()
	assert_str(_window.panel.title.text).is_equal("按钮音效")
	_candidate_row("风铃 · chime").pressed.emit()
	_see("场景 4 选候选", _labels(_candidate_row("风铃 · chime")))
	_adopt_and_check()
	_play_in_game()
	_sound.live.volume_db = -12.0
	_see("场景 2 改音量", _unsaved())
	assert_str(_unsaved()).is_equal("1 个插槽未保存")
	_send_grave()
	_see("场景 3 按 `", "%s · %s" % [_status(), _chip(_window.compare.differences)])
	assert_str(_status()).is_equal("正在显示：游戏原值（只读，按 ` 回到当前改动）")
	assert_bool(_window.compare.compare_side.button_pressed).is_true()
	assert_float(_sound.live.volume_db).is_equal(-6.0)
	_send_grave()
	_see("场景 3 再按 `", _status())
	assert_float(_sound.live.volume_db).is_equal(-12.0)
	_window.panel.adopt.pressed.emit()
	_see("场景 5 再次采纳确认框", _question())
	_window.dialogs.current.get_ok_button().pressed.emit()
	_see("场景 5 再次采纳结果", _status())
	assert_str(_status()).is_equal("已采纳：按钮音效的当前设定已写入游戏")
	_save_a_combo_with_unsaved_slots()
	_overwrite_a_preset_used_by_a_combo()
	_save_another_combo_keeps_the_first()
	_save_into_the_current_combos_preset()
	_load_over_unsaved_edits()
	_save_then_load()
	_load_a_preset_whose_implementation_is_gone()
	_restart_before_the_agent_finishes()
	_window.tabs[1].pressed.emit()
	_see("场景 12 分析页", "%s · %s" % [_window.screenshots.capture_button.text,
		_labels(_window.screenshots.tiles)])
	assert_bool(_window.pages[1].visible and not _window.pages[0].visible).is_true()


## Scenario 8 with an unsaved slot: after the name, one confirmation lists where the slot's
## edits go and saves its preset and the combo.
func _save_a_combo_with_unsaved_slots() -> void:
	_sound.live.volume_db = -9.0
	_window.compare.save_as.pressed.emit()
	assert_str(_window.dialogs.current.title).is_equal("保存组合")
	var name_box := _window.dialogs.current.find_children("*", "LineEdit", true, false)[0] as LineEdit
	name_box.text = "晶体"
	_window.dialogs.current.get_ok_button().pressed.emit()
	var question: String = _question()
	_see("场景 8 有未保存插槽时另存组合", question)
	assert_str(question).contains("“一并保存”会：\n· 按钮音效：新建预设“晶体”\n\n然后保存组合“晶体”。")
	assert_str(_window.dialogs.current.get_ok_button().text).is_equal("一并保存")
	_window.dialogs.current.get_ok_button().pressed.emit()
	_see("场景 8 保存组合结果", _status())
	assert_str(_status()).is_equal("已保存组合 晶体，游戏文件不变")
	assert_str(_sound.preset_name).is_equal("晶体")
	assert_bool(_sound.is_dirty()).is_false()


## Scenario 7: the preset belongs to a combo, so overwriting it asks first.
func _overwrite_a_preset_used_by_a_combo() -> void:
	_sound.live.volume_db = -3.0
	_window._slot_command("保存")
	var question: String = _question()
	_see("场景 7 覆盖组合用到的预设", question)
	assert_str(question).is_equal("预设“晶体”被 1 个组合使用（“晶体”），覆盖后它们也会变。")
	assert_str(_window.dialogs.current.get_ok_button().text).is_equal("另存为新预设")
	_window.dialogs.button("覆盖").pressed.emit()
	_see("场景 7 覆盖结果", _status())
	assert_str(_status()).is_equal("已保存预设 晶体，游戏文件不变")


## Saving another combo over edits of a preset that the first combo uses: the edits go to a
## new preset, so the first combo keeps its values.
func _save_another_combo_keeps_the_first() -> void:
	_sound.live.volume_db = -15.0
	_window.compare.save_as.pressed.emit()
	var name_box := _window.dialogs.current.find_children("*", "LineEdit", true, false)[0] as LineEdit
	name_box.text = "粒子"
	_window.dialogs.current.get_ok_button().pressed.emit()
	var question: String = _question()
	_see("一并保存的确认框列出另存的新预设", question)
	assert_str(question).contains("· 按钮音效：预设“晶体”被组合“晶体”使用，改存为新预设“晶体-粒子”")
	_window.dialogs.current.get_ok_button().pressed.emit()
	_see("一并保存时预设被别的组合使用", _status())
	assert_str(_status()).is_equal("已保存组合 粒子，游戏文件不变；预设 晶体 被组合 晶体 使用，"
		+ "已把 按钮音效 的改动另存为 晶体-粒子")
	assert_str(_sound.preset_name).is_equal("晶体-粒子")
	var first: Dictionary = _window.session.store.stored_fields(_sound, "晶体")
	assert_float(first.value.volume_db).is_equal(-3.0)
	var presets: Dictionary = _window.session.store.combo_presets("sample", "晶体", _window.session.slots)
	assert_str(presets[_sound.id]).is_equal("晶体")


## The current combo's own preset is not "used by another combo": saving before a load
## writes into it directly.
func _save_into_the_current_combos_preset() -> void:
	assert_str(_window.session.combo_name).is_equal("粒子")
	_sound.live.volume_db = -12.0
	_window.panel._preset_chosen(0)
	_window.dialogs.current.get_ok_button().pressed.emit()
	_see("当前组合自己的预设直接保存", _status())
	assert_str(_status()).is_equal("已把 按钮音效 的改动存进预设 晶体-粒子；已载入游戏原值")
	var stored: Dictionary = _window.session.store.stored_fields(_sound, "晶体-粒子")
	assert_float(stored.value.volume_db).is_equal(-12.0)


## Loading over unsaved edits with "保存": the status says where the edits went.
func _save_then_load() -> void:
	_sound.live.volume_db = -20.0
	_window.panel._preset_chosen(0)
	_window.dialogs.current.get_ok_button().pressed.emit()
	_see("场景 6 保存后载入", _status())
	assert_str(_status()).starts_with("已把 按钮音效 的改动存进预设 载入前-")
	assert_str(_status()).ends_with("；已载入游戏原值")


## A preset whose implementation is no longer anywhere loads with that one item in game values.
func _load_a_preset_whose_implementation_is_gone() -> void:
	var path: String = _window.session.store.preset_path(_sound.id, "坏")
	var preset := ResourceLoader.load(_window.session.store.preset_path(_sound.id, "晶体"), "",
		ResourceLoader.CACHE_MODE_IGNORE)
	preset.fields.candidate = ResourceUID.id_to_text(ResourceUID.create_id())
	ResourceSaver.save(preset, path)
	_window.session.store.load_slot(_sound, "")
	_window.panel._preset_names = _window.session.store.list_names(path.get_base_dir())
	_window.panel._preset_chosen(_window.panel._preset_names.find("坏") + 1)
	_see("载入实现已不在的预设", _status())
	assert_str(_status()).is_equal("已载入预设 坏；按钮音效用的实现已不在游戏和候选目录里，这一项改用游戏原值")
	assert_str(_status()).not_contains("candidate")
	assert_str(_sound.preset_name).is_equal("坏")
	assert_str(_window.panel.preset_select.value_label.text).is_equal("坏（已修改）")
	_load_a_preset_with_an_old_parameter_name()


## A preset saved before a parameter was renamed: the status counts parameters, the names
## stay in 详情.
func _load_a_preset_with_an_old_parameter_name() -> void:
	var store: RefCounted = _window.session.store
	var preset := ResourceLoader.load(store.preset_path(_sound.id, "晶体"), "",
		ResourceLoader.CACHE_MODE_IGNORE)
	preset.fields.old_volume = preset.fields.volume_db
	preset.fields.erase("volume_db")
	ResourceSaver.save(preset, store.preset_path(_sound.id, "旧"))
	_window.panel._preset_names = store.list_names(store.preset_path(_sound.id, "旧").get_base_dir())
	_window.panel._preset_chosen(_window.panel._preset_names.find("旧") + 1)
	_see("载入有旧参数名的预设", _status())
	assert_str(_status()).is_equal("已载入预设 旧；按钮音效 有 2 项参数和预设对不上（预设里缺少，"
		+ "或是已改名的旧参数），这些参数用游戏原值")
	assert_str(_window.status.detail_text.text).contains("old_volume")


## Scenario 6: loading over unsaved edits asks; "不保存载入" drops them.
func _load_over_unsaved_edits() -> void:
	_sound.live.volume_db = 0.0
	_window.panel._preset_chosen(0)
	var question: String = _question()
	_see("场景 6 有改动时载入游戏原值", question)
	assert_str(question).starts_with("有 1 个插槽的改动还没保存（“按钮音效”），载入游戏原值后会丢失。")
	assert_float(_sound.live.volume_db).is_equal(0.0)
	_window.dialogs.button("不保存载入").pressed.emit()
	_see("场景 6 不保存载入", _status())
	assert_str(_status()).is_equal("已载入游戏原值")
	assert_float(_sound.live.volume_db).is_equal(_sound.disk_defaults().volume_db)


## Restarting before the Agent's follow-up: the editor's UID cache still names dev/.
func _restart_before_the_agent_finishes() -> void:
	for number: int in _stale:
		ResourceUID.set_id(number, _stale[number])
	var restarted := Slot.new()
	ResourceLoader.load(_sound.game_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).take_over_path(
		_sound.game_path)
	restarted.configure("sample", "feedback/sound", _sound.game_path, _sound.debug_root)
	restarted.actions = _sound.actions
	var unrepaired := restarted.refresh_candidates()
	_see("重启（未收尾、UID 未修复）", "%d 个候选 · %s" % [restarted.candidates.size(),
		unrepaired.get("text", "")])
	assert_int(restarted.candidates.size()).is_greater(1)
	Uids.repair(_fixture.root.path_join("game"))
	assert_dict(restarted.refresh_candidates()).is_equal({"error": OK})
	_see("重启（入口修复 UID 后）", "%d 个候选 · 游戏在用 %s" % [restarted.candidates.size(),
		restarted.candidate_title(restarted.disk_defaults().candidate)])
	assert_str(restarted.candidate_title(restarted.disk_defaults().candidate)).is_equal(
		"风铃 · chime")


func _adopt_and_check() -> void:
	_window.panel.adopt.pressed.emit()
	var question: String = _question()
	_see("场景 5 采纳确认框", question)
	assert_str(question).contains("把 风铃 · chime 移入游戏，并把按钮音效改为它")
	assert_str(question).not_contains("res://")
	_window.dialogs.current.get_ok_button().pressed.emit()
	_see("场景 5 采纳结果", _status())
	assert_str(_status()).is_equal("已采纳：按钮音效改为 风铃 · chime")
	assert_bool(_window.status.details.visible).is_false()
	var adopted := _window.panel.find_child("Candidate0", true, false) as Button
	_see("场景 5 游戏在用", _labels(adopted))
	assert_str(_labels(adopted)).is_equal("风铃 · chime 游戏在用")
	assert_str(_unsaved()).is_empty()


func _play_in_game() -> void:
	var game_script := load(GAME) as Script
	var original_save: String = game_script.get("save_path")
	game_script.set("save_path", _fixture.root.path_join("sample.json"))
	var scene := auto_free((load(MAIN) as PackedScene).instantiate()) as Node
	var game := scene.get_node("Game")
	game.sound = _sound.live
	add_child(scene)
	game.play_round(1)
	var player := game.sounds.get_child(game.sounds.get_child_count() - 1) as AudioStreamPlayer
	_see("场景 5 游戏当场播放", player.stream.resource_path.trim_prefix(_fixture.root))
	assert_str(player.stream.resource_path).is_equal(
		_fixture.game_sample().path_join("feedback/sound/chime/chime.wav"))
	assert_bool(player.playing).is_true()
	game_script.set("save_path", original_save)


func _candidate_row(caption: String) -> Button:
	for row in _window.panel.find_children("Candidate*", "Button", true, false):
		if _labels(row).begins_with(caption):
			return row
	return null


func _slot(identity: String) -> Slot:
	for slot: Slot in _window.session.slots:
		if slot.id == identity:
			return slot
	return null


## The current dialog's text without its layout characters.
func _question() -> String:
	return _window.dialogs.current.dialog_text.replace(Dialogs.WORD_JOINER, "").strip_edges()


func _status() -> String:
	return _window.status.message.text


func _unsaved() -> String:
	var marks: Array[Node] = _window.status.find_children("*", "Label", true, false)
	for label: Label in marks:
		if label.theme_type_variation == &"WarnText" and (label.get_parent() as Control).visible:
			return label.text
	return ""


func _labels(node: Node) -> String:
	var texts: PackedStringArray = []
	for label: Label in node.find_children("*", "Label", true, false):
		if not label.text.is_empty():
			texts.append(label.text)
	return " ".join(texts)


func _chip(chip: Control) -> String:
	return (chip.get_node("Row/Text") as Label).text


func _see(step: String, text: String) -> void:
	_seen.append("[%s] %s" % [step, text.replace("\n", " / ")])


func _send_grave() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_QUOTELEFT
	key.keycode = KEY_QUOTELEFT
	key.unicode = 96
	key.pressed = true
	get_tree().root.push_input(key, true)
