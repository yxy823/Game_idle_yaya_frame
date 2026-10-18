extends GdUnitTestSuite
## The real window on the sample game: switching targets keeps unsaved edits under the close
## question and gives a shown comparison back first; a long preset name leaves the inspector's
## controls visible.

const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const SlotPanel := preload("res://dev/debug/_shared/slot_panel.gd")
const PINS := "user://debug/pinned-slots.json"
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const EFFECT := "sample/feedback/effect"

var _window: Window
var _defaults: Dictionary = {}


func before_test() -> void:
	Session.pins_path = "user://tests/debug-pins-%d.json" % Time.get_ticks_usec()
	Session.game_root = SAMPLE + "game"
	Session.debug_root = SAMPLE + "debug"
	_window = WINDOW.instantiate() as Window
	_window.force_native = true
	get_tree().root.add_child(_window)
	_window.configure("user://tests/debug-switch-save.json")
	# Picking a target opens its main scene; the test runner's scene stays.
	_window.playback.reload_scene = func(_path: String) -> Error: return OK
	_defaults.clear()
	for slot: Slot in _window.session.slots:
		var values: Dictionary = {}
		for field in Codec.fields(slot.live):
			values[field.name] = Codec.copy_value(slot.live.get(field.name))
		_defaults[slot.id] = values


func after_test() -> void:
	for slot: Slot in _window.session.opened_slots():
		Codec.apply_fields(slot.live, _defaults[slot.id])
		slot.preset_name = ""
	_window.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.remove_absolute(Session.pins_path)
	Session.pins_path = PINS
	Session.game_root = "res://game"
	Session.debug_root = "res://dev/debug"


func test_closing_after_switching_targets_asks_about_the_first_targets_edits() -> void:
	var quits: Array[int] = []
	_window.quit_game = func() -> void: quits.append(1)
	var effect := _slot(EFFECT)
	effect.live.candidate_params.size += 10.0
	_window.toolbar.target_selected.emit("shared")
	assert_bool(effect in _window.session.slots).is_false()
	_window.get_tree().root.close_requested.emit()
	assert_int(quits.size()).is_equal(0)
	assert_str(_window.dialogs.current.dialog_text).starts_with("有 1 个插槽的改动还没保存，关闭后会丢失。")
	_window.dialogs.button("取消").pressed.emit()
	_window.toolbar.target_selected.emit("sample")


func test_switching_targets_while_comparing_gives_the_edits_back() -> void:
	var effect := _slot(EFFECT)
	var game_size: float = effect.live.candidate_params.size
	effect.live.candidate_params.size = game_size + 10.0
	assert_str(_window.session.compare.toggle(false).text).contains("正在显示：游戏原值")
	assert_float(effect.live.candidate_params.size).is_equal(game_size)
	_window.toolbar.target_selected.emit("shared")
	assert_bool(_window.session.compare.showing).is_false()
	assert_float(effect.live.candidate_params.size).is_equal(game_size + 10.0)
	_window.toolbar.target_selected.emit("sample")
	assert_float(_slot(EFFECT).live.candidate_params.size).is_equal(game_size + 10.0)
	assert_bool(_window.session.slot_dirty(_slot(EFFECT))).is_true()


func test_a_long_preset_name_is_cut_and_the_preset_buttons_stay_in_the_inspector() -> void:
	var effect := _slot(EFFECT)
	var long_name := "很长的预设名".repeat(12)
	effect.preset_name = long_name
	var names := func(_directory: String) -> PackedStringArray: return PackedStringArray([long_name])
	_window.panel.bind(effect, names)
	await get_tree().process_frame
	var select: Control = _window.panel.preset_select
	assert_float(select.size.x).is_less_equal(SlotPanel.PRESET_WIDTH)
	assert_str(select.tooltip_text).contains(long_name)
	var inspector: Rect2 = _window.panel.get_global_rect()
	for tool: Control in select.get_parent().get_children():
		assert_bool(inspector.encloses(tool.get_global_rect())).is_true()


## An adapter that declares neither FIXTURES nor matches can be picked and followed on a
## scene change without a script error; the playback bar offers no fixture.
func test_target_whose_adapter_has_no_fixtures_or_matches_is_browse_only() -> void:
	for target: RefCounted in _window.session.targets:
		if target.id == "shared":
			target.adapter = RefCounted.new()
	_window.toolbar.target_selected.emit("shared")
	assert_str(_window.toolbar.chosen_fixture()).is_empty()
	_window.toolbar.target_selected.emit("sample")
	get_tree().scene_changed.emit()
	assert_str(_window.session.active.id).is_equal("shared")


func _slot(identity: String) -> Slot:
	for slot: Slot in _window.session.opened_slots():
		if slot.id == identity:
			return slot
	return null
