# 驱动库的操作在 scan_cases.tscn 上逐项生效：点按钮、读文字、注入按键、禁用按钮拒绝点击。
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"

var _clicked: Array = []
var _keys: Array = []


func _run() -> void:
	var scene := open_scene("res://scan_cases.tscn")
	if scene == null:
		return
	var clear := find("Clear") as Button
	clear.pressed.connect(func() -> void: _clicked.append("Clear"))
	var catcher := _KeyCatcher.new()
	catcher.keys = _keys
	scene.add_child(catcher)
	# 场景里打开着的对话框是独占窗口，会挡住发给根窗口的按键，和玩家实际遇到的一样。
	(find("SavedDialog") as Window).hide()
	await wait_frames(1)
	click("Clear")
	await press_key(KEY_F1)
	if not expect(_clicked == ["Clear"], "click emits pressed once"):
		return
	if not expect(_keys == [KEY_F1], "press_key reaches _input once (pressed only), got %s" % [_keys]):
		return
	if not expect(text_of("Vague") == "OK", "text_of reads the button text"):
		return
	click("LockedNoTip")


class _KeyCatcher:
	extends Node

	var keys: Array

	func _input(event: InputEvent) -> void:
		var key := event as InputEventKey
		if key != null and key.pressed:
			keys.append(key.keycode)
