extends GdUnitTestSuite
## The style overview: which interfaces use each style and the hints that follow, token fields
## listed by reflection, and "打开" picking a debug target the way the target dropdown does.

const OVERVIEW := preload("res://dev/debug/shared/overview/style_overview.tscn")
const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Usage := preload("res://dev/debug/shared/overview/style_usage.gd")
const FIXTURES := "res://dev/debug/shared/tests/fixtures/"
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const SAMPLE_MAIN := SAMPLE + "game/sample/sample_main.tscn"
const PINS := "user://debug/pinned-slots.json"

var _window: Window


func after_test() -> void:
	if _window != null:
		_window.queue_free()
		_window = null
		await get_tree().process_frame
		# The persistent root input bridge queues its own removal in window._exit_tree.
		await get_tree().process_frame
		DirAccess.remove_absolute(Session.pins_path)
	Session.pins_path = PINS
	Session.game_root = "res://game"
	Session.debug_root = "res://dev/debug"


func test_a_shared_variation_only_one_interface_uses_can_move_back() -> void:
	var primary := _entry(_scan().shared, "ButtonPrimary")
	assert_array(primary.users).contains_exactly(["alpha"])
	assert_str(primary.hint()).is_equal("可以移回该界面")


func test_an_interfaces_own_variation_two_interfaces_use_can_move_into_shared() -> void:
	var card := _entry(_scan().own, "AlphaCard")
	assert_str(card.owner).is_equal("alpha")
	assert_array(card.users).contains_exactly_in_any_order(["alpha", "beta"])
	assert_str(card.hint()).is_equal("可以搬进 shared")


func test_a_field_added_to_a_token_resource_is_listed() -> void:
	var overview: Control = OVERVIEW.instantiate()
	overview.tokens_root = FIXTURES + "tokens"
	add_child(auto_free(overview))
	var card := overview.find_child("primitives_spacing", true, false)
	var texts: PackedStringArray = []
	for label: Label in card.find_children("*", "Label", true, false):
		texts.append(label.text)
	assert_array(texts).contains(["huge", "48 px", "大", "16 px"])


func test_open_picks_the_interface_like_the_target_dropdown() -> void:
	Session.pins_path = "user://tests/debug-pins-%d.json" % Time.get_ticks_usec()
	Session.game_root = SAMPLE + "game"
	Session.debug_root = SAMPLE + "debug"
	_window = WINDOW.instantiate() as Window
	_window.force_native = true
	get_tree().root.add_child(_window)
	_window.configure("user://tests/style-overview-save.json")
	var opened: Array[String] = []
	_window.playback.reload_scene = func(path: String) -> Error:
		opened.append(path)
		return OK
	var overview: Control = OVERVIEW.instantiate()
	add_child(auto_free(overview))
	var open: Button = overview.find_child("sample", true, false).get_node("Open")
	open.pressed.emit()
	assert_str(_window.session.active.id).is_equal("sample")
	assert_array(opened).contains_exactly([SAMPLE_MAIN])


func _scan() -> Usage:
	var usage := Usage.new()
	usage.scan(FIXTURES + "usage/game", PackedStringArray(["alpha", "beta"]),
		Usage.variations(ThemeDB.get_project_theme()))
	return usage


func _entry(entries: Array[Usage.Entry], entry_name: String) -> Usage.Entry:
	for entry in entries:
		if entry.name == entry_name:
			return entry
	return null
