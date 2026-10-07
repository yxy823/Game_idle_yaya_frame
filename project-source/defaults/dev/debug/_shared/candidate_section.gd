extends VBoxContainer
## The inspector's "实现" section: one radio row per candidate with the game's adopted entry
## marked, and the slot's trial actions in the section header.

signal chosen(index: int)
signal requested(action: String)
signal reported(result: Dictionary)

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const ROW_HEIGHT := 32.0
const LOCKED_ALPHA := 0.6

var trials: Array[Button] = []
var rows: Array[Button] = []
var _slot: Slot


func _init(slot: Slot) -> void:
	_slot = slot
	name = "Candidates"
	add_theme_constant_override("separation", 0)
	var header := Kit.section_header("实现")
	add_child(header)
	if slot.actions != null and slot.actions.has_method("action_names"):
		for action: String in slot.actions.action_names():
			var trial := Kit.text_button(action, "wand", "用当前候选和参数" + action)
			trial.pressed.connect(func() -> void: requested.emit("试播:" + action))
			header.add_child(trial)
			trials.append(trial)
	var group := ButtonGroup.new()
	var current := _matching_candidate()
	var queued := Adoption.queued_candidate(slot)
	for index in range(slot.candidates.size()):
		var row := _row(index, index == current, group,
			not queued.is_empty() and slot.candidates[index].id == queued)
		add_child(row)
		rows.append(row)


## Locked rows keep showing the selection but ignore the mouse.
func set_locked(value: bool) -> void:
	for trial in trials:
		trial.disabled = value
	for row in rows:
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE if value else Control.MOUSE_FILTER_STOP
		row.modulate.a = LOCKED_ALPHA if value and not row.button_pressed else 1.0


## `queued` marks the candidate adopted this session whose files move at the next start.
func _row(index: int, selected: bool, group: ButtonGroup, queued: bool) -> Button:
	var entry := _slot.candidates[index]
	var adopted := String(entry.id).is_empty()
	var button := Button.new()
	button.name = "Candidate%d" % index
	button.theme_type_variation = &"CandidateRow"
	button.toggle_mode = true
	button.button_group = group
	button.set_pressed_no_signal(selected)
	button.custom_minimum_size.y = ROW_HEIGHT
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: chosen.emit(index))
	var line := Kit.row(10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 8.0
	line.offset_right = -4.0
	var radio := Kit.Radio.new()
	radio.on = selected
	line.add_child(radio)
	var caption := Kit.elided(_adopted_name() if adopted else String(entry.name), &"BodyText")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if selected:
		caption.add_theme_color_override("font_color", Kit.color(&"tx1"))
	line.add_child(caption)
	if adopted:
		var chip := Kit.chip("游戏在用", "check")
		chip.tooltip_text = "游戏文件当前采纳这个实现"
		line.add_child(chip)
	elif queued:
		var next := Kit.chip("下次启动生效", "clock", &"accent")
		next.tooltip_text = "已采纳到游戏；它的脚本和场景在下次启动调试台时移入游戏"
		line.add_child(next)
	var license := Kit.inline_button("license", "许可信息：%s %s" % [entry.license, entry.source])
	license.pressed.connect(func() -> void:
		reported.emit({"error": OK, "message": "%s %s" % [entry.license, entry.source]}))
	line.add_child(license)
	return button


## The adopted entry is named after the game's own candidate resource.
func _adopted_name() -> String:
	var adopted := _adopted_candidate()
	return "未设置" if adopted == null else _slot.candidate_title(adopted)


func _adopted_candidate() -> Resource:
	var defaults := _slot.disk_defaults()
	return defaults.get("candidate") as Resource if defaults != null else null


func _matching_candidate() -> int:
	var live_candidate: Resource = _slot.live.get("candidate")
	var path := "" if live_candidate == null else live_candidate.resource_path
	for index in range(_slot.candidates.size()):
		var entry := _slot.candidates[index]
		var candidate_path := ""
		if String(entry.id).is_empty():
			var adopted := _adopted_candidate()
			candidate_path = "" if adopted == null else adopted.resource_path
		else:
			candidate_path = Codec.resolve_uid(entry.definition.candidate_uid)
		if candidate_path == path:
			return index
	return -1
