extends Node
## Every confirmation of the debug window comes from ask(): buttons in a fixed order
## [main action] [other actions] … [取消], cancel always last, styled from the debug theme.
## Dialogs inherit the debug viewport; none force a second native child window.

const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
## Button styles: the recommended action, an action that loses edits or changes game files,
## and a plain one.
const PRIMARY := &"PrimaryButton"
const DANGER := &"DangerButton"
const PLAIN := &""
const WIDTH := 460
const BUTTON_WIDTH := 88
const BUTTON_GAP := 8
const WORD_JOINER := "⁠"

var host: Window
## The dialog shown last; tests answer it through button().
var current: AcceptDialog
var _buttons: Dictionary[String, Button] = {}


## `actions` lists [caption, style, Callable] with the main action first; 取消 is appended.
## `body` is an optional control under the text, such as a name field.
func ask(text: String, actions: Array, title: String = "请确认", body: Control = null) -> void:
	var previous := host.gui_get_focus_owner()
	if is_instance_valid(current):
		current.hide()
		if not current.is_queued_for_deletion():
			current.queue_free()
	var dialog := AcceptDialog.new()
	dialog.title = title
	# The trailing line keeps the same gap above the buttons in every dialog.
	dialog.dialog_text = unbroken_quotes(text) + ("\n" if not text.is_empty() else "")
	dialog.dialog_autowrap = true
	_add_buttons(dialog, actions)
	if body != null:
		dialog.add_child(body)
	host.add_child(dialog)
	current = dialog
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exited.connect(func() -> void:
		if is_instance_valid(previous) and previous.is_visible_in_tree():
			previous.grab_focus())
	dialog.popup_centered(Vector2i(WIDTH, 0))


## The main action on the OK button, the others after it, then 取消, all the same size.
func _add_buttons(dialog: AcceptDialog, actions: Array) -> void:
	dialog.add_theme_constant_override("buttons_separation", BUTTON_GAP)
	dialog.add_theme_constant_override("buttons_min_width", BUTTON_WIDTH)
	dialog.add_theme_constant_override("buttons_min_height", int(Kit.CONTROL))
	_buttons.clear()
	_style(dialog.get_ok_button(), actions[0])
	dialog.confirmed.connect(actions[0][2], CONNECT_ONE_SHOT)
	for index in range(1, actions.size()):
		_style(dialog.add_button(actions[index][0], true, "action%d" % index), actions[index])
	_style(dialog.add_button("取消", true, "cancel"), ["取消", PLAIN])
	# AcceptDialog puts an expanding spacer beside every button; only the first one stays, so
	# the buttons sit together at the right with a fixed gap.
	var spacers := dialog.get_ok_button().get_parent().get_children(true).filter(
		func(child: Node) -> bool: return not child is Button)
	for index in range(spacers.size()):
		(spacers[index] as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL \
			if index == 0 else Control.SIZE_FILL
	dialog.custom_action.connect(func(action: StringName) -> void:
		dialog.hide()
		dialog.queue_free()
		if action != &"cancel":
			actions[String(action).trim_prefix("action").to_int()][2].call())


func confirm(text: String, callback: Callable, accept: String = "确定",
		title: String = "请确认", style: StringName = PRIMARY) -> void:
	ask(text, [[accept, style, callback]], title)


## `title` says what is saved, for example "保存 按钮音效 的预设" or "保存组合".
func ask_name(value: String, callback: Callable, title: String = "输入保存名称") -> void:
	var input := LineEdit.new()
	input.text = value
	input.custom_minimum_size = Vector2(360, Kit.CONTROL)
	ask("", [["保存", PRIMARY, func() -> void: callback.call(input.text)]], title, input)
	current.register_text_enter(input)
	input.grab_focus()
	input.select_all()


## Names in “…” never wrap inside: a word joiner (U+2060) sits between their characters, so
## “载入前-日期时间” moves to the next line as a whole.
static func unbroken_quotes(text: String) -> String:
	var result := text
	for found in RegEx.create_from_string("“([^“”]+)”").search_all(text):
		var fragment := found.get_string(1)
		result = result.replace("“%s”" % fragment, "“%s”" % WORD_JOINER.join(fragment.split("")))
	return result


## A button of the current dialog by its caption; null when it has none.
func button(caption: String) -> Button:
	return _buttons.get(caption)


func _style(target: Button, action: Array) -> void:
	target.text = action[0]
	target.theme_type_variation = action[1]
	target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_buttons[action[0]] = target
