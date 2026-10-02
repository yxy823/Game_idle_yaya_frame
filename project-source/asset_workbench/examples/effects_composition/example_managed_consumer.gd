extends "res://components/feedback/feedback_composition.gd"

## Native consumer demonstration; no workbench or editor dependency.

var _message: Label
var _playing: Label


func _ready() -> void:
	super()
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	content.offset_left = 16.0
	content.offset_top = 12.0
	content.offset_right = -16.0
	add_child(content)
	var heading := Label.new()
	heading.text = "粒子与动画 · 消费场景（已保存 Cue）"
	content.add_child(heading)
	var actions := HFlowContainer.new()
	content.add_child(actions)
	_button(actions, "播放编排", _play_sequence.bind(false))
	_button(actions, "循环编排", _play_sequence.bind(true))
	_button(actions, "受管触发 A 组", _play_group.bind("GroupA", &"group_a", 0))
	_button(actions, "高优先级 B 组", _play_group.bind("GroupB", &"group_b", 1))
	_button(actions, "取消受管 A 组", manager.cancel_group.bind(&"group_a"))
	_button(actions, "停止全部", stop)
	_playing = Label.new()
	content.add_child(_playing)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.text = "并发限额为 3 个受管对象；高优先级可以抢占。点击对象仍可直接触发。"
	content.add_child(_message)
	playback_reported.connect(_show_message)
	for object: ObjectView in objects:
		object.presenter.playback_failed.connect(_show_message)


func _process(_delta: float) -> void:
	var mode := "循环" if timeline_player.looping else "单次"
	_playing.text = "编排：%s · 受管对象：%d / %d" % [
		mode if timeline_player.is_playing() else "停止", manager.active_count(), manager.max_active]


func _play_sequence(repeat: bool) -> void:
	var issue := play_timeline(repeat)
	_show_message(issue if not issue.is_empty() else "编排按 A 组 → B 组 → 两组核心并行播放。")


func _play_group(prefix: String, group: StringName, priority: int) -> void:
	timeline_player.stop()
	var accepted: int = 0
	for object: ObjectView in objects:
		if String(get_path_to(object)).begins_with(prefix + "/"):
			accepted += int(manager.request(object.presenter, group, priority) != 0)
	_show_message("%s 接受 %d 个对象；同优先级满额拒绝，更高优先级抢占。" % [prefix, accepted])


func _show_message(message: String) -> void:
	_message.text = message


func _button(parent: Container, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, Color.BLACK)
	button.pressed.connect(action)
	parent.add_child(button)
