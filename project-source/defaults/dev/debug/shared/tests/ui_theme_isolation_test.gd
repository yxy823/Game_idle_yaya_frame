extends GdUnitTestSuite
## The debug window keeps its own look while the game's UI tokens change: every item the game
## theme defines resolves to the same value in the debug window before and after the change.

const SignalAssertImpl := preload("res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd")
const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const PINS := "user://debug/pinned-slots.json"
const PRIMITIVES := "res://game/shared/tuning/ui/primitives/"

var _window: Window
var _saved: Dictionary[Resource, Dictionary] = {}


func before_test() -> void:
	Session.pins_path = "user://tests/debug-pins-%d.json" % Time.get_ticks_usec()
	_window = WINDOW.instantiate() as Window
	_window.force_native = true
	get_tree().root.add_child(_window)
	_window.configure("user://tests/debug-window-save.json")


func after_test() -> void:
	for token: Resource in _saved:
		for field: String in _saved[token]:
			token.set(field, _saved[token][field])
	_saved.clear()
	_window.queue_free()
	await get_tree().process_frame
	# The persistent root input bridge queues its own removal in window._exit_tree.
	await get_tree().process_frame
	DirAccess.remove_absolute(Session.pins_path)
	Session.pins_path = PINS


func test_debug_window_look_ignores_game_ui_tokens() -> void:
	# A semantic slot: its rows stay in place while only the primitives change.
	var slot: Slot = _window.session.slots.filter(func(item: Slot) -> bool:
		return item.id == "shared/ui/semantic/buttons/primary")[0]
	_window.session.select_slot(slot)
	_window.panel.bind(slot, _window.session.store.list_names)
	var theme := ThemeDB.get_project_theme()
	var original := _snapshot(theme)
	for file in DirAccess.get_files_at(PRIMITIVES):
		_change_every_field(load(PRIMITIVES + file))
	await _theme_rebuilt()
	var current := _snapshot(theme)
	assert_array(original.keys().filter(func(key: String) -> bool:
		return original[key] != current[key])).is_empty()


## Every Color, int and Vector2 field gets a value no default uses.
func _change_every_field(token: Resource) -> void:
	var values := {}
	for property in token.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		values[property.name] = token.get(property.name)
		match typeof(values[property.name]):
			TYPE_COLOR:
				token.set(property.name, Color("ff00ff"))
			TYPE_INT:
				token.set(property.name, 37)
			TYPE_VECTOR2:
				token.set(property.name, Vector2(9, 9))
	_saved[token] = values


## What each debug control resolves for each item name the game theme defines.
func _snapshot(theme: Theme) -> Dictionary:
	var result := {}
	var controls: Array[Node] = _window.find_children("*", "Control", true, false)
	for control: Control in controls:
		var path := String(_window.get_path_to(control))
		for type in theme.get_color_type_list():
			for item in theme.get_color_list(type):
				result["%s color %s" % [path, item]] = control.get_theme_color(item)
		for type in theme.get_font_size_type_list():
			for item in theme.get_font_size_list(type):
				result["%s size %s" % [path, item]] = control.get_theme_font_size(item)
		for type in theme.get_stylebox_type_list():
			for item in theme.get_stylebox_list(type):
				result["%s box %s" % [path, item]] = _box_values(control.get_theme_stylebox(item))
	return result


## Compared by stored values: the debug window rebuilds some override boxes on every refresh.
func _box_values(box: StyleBox) -> String:
	var values := []
	for property in box.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE:
			values.append(box.get(property.name))
	return var_to_str(values)


## The UiTheme autoload rebuilds one frame after a token changes; assert_signal waits 2000 ms.
func _theme_rebuilt() -> void:
	var signal_assert := assert_signal(ThemeDB.get_project_theme()) as SignalAssertImpl
	await signal_assert.is_emitted("changed")
