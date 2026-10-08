## 界面静态扫描：实例化指定场景，检查可见按钮与输入控件，结果写入输出目录的 scan.json。
## 每条结果只是线索，要人工确认。场景的 _ready 会执行，所以同样只在试用副本中运行：
##   run-ui-trial.py --copy <副本> --script res://yaya/tools/ui-trial/ui_scan.gd -- --scenes=res://a.tscn,res://b.tscn
## 其他驱动脚本可以对运行中的界面调用 scan_node(节点)。
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"

## 控件可设元数据 ui_trial_role = "danger" 标出危险按钮；未设置时按名称、文字和提示中的词判断。
const ROLE_META := &"ui_trial_role"
const DANGER_WORDS := ["删除", "出售", "卖出", "重置", "退出", "丢弃", "清空", "覆盖", "放弃",
	"delete", "remove", "sell", "reset", "quit", "discard", "clear", "overwrite"]
const VAGUE_TEXTS := ["ok", "确定", "是", "否", "好", "yes", "no", "x", "button", "按钮", "...", "…", "?", "go"]
const MIN_TARGET := 24.0
const DANGER_GAP := 8.0


func _run() -> void:
	var scenes := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenes="):
			scenes = argument.get_slice("=", 1).split(",", false)
	if not expect(not scenes.is_empty(), "--scenes=res://a.tscn[,res://b.tscn] given"):
		return
	var results: Array = []
	for path in scenes:
		var node := open_scene(path)
		if node == null:
			return
		await wait_frames(2)
		var findings := scan_node(node)
		results.append({"scene": path, "findings": findings})
		step("%s: %d findings" % [path, findings.size()])
		node.queue_free()
		current_scene = null
		await wait_frames(1)
	var file := FileAccess.open(output_directory.path_join("scan.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"tool": "ui-trial scan", "godot": Engine.get_version_info().string,
		"scenes": results}, "\t"))
	file.close()
	step("wrote " + output_directory.path_join("scan.json"))


## 扫描 root_node 之下（含代码创建的节点与子窗口）可见的交互控件，返回结果数组。
static func scan_node(root_node: Node) -> Array:
	var controls: Array = []
	for node in root_node.find_children("*", "Control", true, false):
		var control := node as Control
		if control.is_visible_in_tree() and _is_interactive(control):
			controls.append(control)
	var findings: Array = []
	for control: Control in controls:
		if control is BaseButton:
			findings.append_array(_button_findings(control, root_node))
		var size := control.get_global_rect().size
		if size.x > 0.0 and (size.x < MIN_TARGET or size.y < MIN_TARGET):
			findings.append(_finding("S04", control, root_node,
				"点击区域 %d×%d，小于 %d×%d" % [size.x, size.y, MIN_TARGET, MIN_TARGET]))
		findings.append_array(_danger_findings(control, controls, root_node))
	findings.append_array(_duplicate_findings(controls, root_node))
	return findings


static func _danger_findings(control: Control, controls: Array, root_node: Node) -> Array:
	var nearest := _nearest(control, controls) if _is_danger(control) else {}
	if nearest.is_empty() or nearest.gap >= DANGER_GAP:
		return []
	var other: Control = nearest.control
	var other_name := _text(other) if not _text(other).is_empty() else String(other.name)
	return [_finding("S05", control, root_node,
		"危险按钮与“%s”只隔 %d 像素，容易误点" % [other_name, nearest.gap])]


static func _button_findings(button: BaseButton, root_node: Node) -> Array:
	var findings: Array = []
	var text := _text(button)
	var has_tooltip := not button.tooltip_text.strip_edges().is_empty()
	if text.is_empty() and not has_tooltip:
		findings.append(_finding("S01", button, root_node, "按钮没有文字，也没有悬停提示，玩家不知道它做什么"))
	elif text.to_lower() in VAGUE_TEXTS and not _in_dialog(button):
		findings.append(_finding("S02", button, root_node, "按钮文字“%s”没有说明点了会发生什么" % text))
	if button.disabled and not has_tooltip:
		findings.append(_finding("S10", button, root_node, "按钮是禁用的，但没有悬停提示说明原因"))
	return findings


## 只比较同一窗口内的按钮：对话框自带的“确定”与主界面的按钮不是同一处的重复。
static func _duplicate_findings(controls: Array, root_node: Node) -> Array:
	var by_text := {}
	for control: Control in controls:
		var text := _text(control).to_lower()
		if control is BaseButton and not text.is_empty():
			var key := "%d:%s" % [control.get_window().get_instance_id(), text]
			by_text[key] = by_text.get(key, []) + [control]
	var findings: Array = []
	for key: String in by_text:
		var same: Array = by_text[key]
		if same.size() < 2:
			continue
		var finding := _finding("S03", same[0], root_node,
			"%d 个按钮的文字都是“%s”，确认它们作用相同或改成能区分的文字" % [same.size(), _text(same[0])])
		finding["same_text_controls"] = same.map(
			func(control: Control) -> String: return String(root_node.get_path_to(control)))
		findings.append(finding)
	return findings


static func _is_interactive(control: Control) -> bool:
	return control is BaseButton or control is LineEdit or control is Slider or control is SpinBox


## 按钮显示的文字：按钮自身的文字；没有时取按钮内可见的 Label（自定义内容的按钮常这样做）。
static func _text(control: Control) -> String:
	if control is Button and not control.text.strip_edges().is_empty():
		return control.text.strip_edges()
	if not control is BaseButton:
		return ""
	var parts := PackedStringArray()
	for node in control.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree() and not label.text.strip_edges().is_empty():
			parts.append(label.text.strip_edges())
	return " ".join(parts)


static func _in_dialog(control: Control) -> bool:
	var parent := control.get_parent()
	while parent != null:
		if parent is AcceptDialog:
			return true
		parent = parent.get_parent()
	return false


static func _is_danger(control: Control) -> bool:
	if control.has_meta(ROLE_META):
		return String(control.get_meta(ROLE_META)) == "danger"
	if not control is BaseButton:
		return false
	var words := ("%s %s %s" % [control.name, _text(control), control.tooltip_text]).to_lower()
	for word: String in DANGER_WORDS:
		if words.contains(word):
			return true
	return false


## 同一窗口内与 control 最近的可见交互控件及间距；控件互相包含（如 SpinBox 内部）时不比较。
static func _nearest(control: Control, controls: Array) -> Dictionary:
	var best := {}
	var rect := control.get_global_rect()
	for other: Control in controls:
		if other == control or other.get_window() != control.get_window() \
				or other.is_ancestor_of(control) or control.is_ancestor_of(other):
			continue
		var target := other.get_global_rect()
		var dx := maxf(0.0, maxf(target.position.x - rect.end.x, rect.position.x - target.end.x))
		var dy := maxf(0.0, maxf(target.position.y - rect.end.y, rect.position.y - target.end.y))
		var gap := sqrt(dx * dx + dy * dy)
		if best.is_empty() or gap < best.gap:
			best = {"gap": gap, "control": other}
	return best


static func _finding(rule: String, control: Control, root_node: Node, message: String) -> Dictionary:
	var rect := control.get_global_rect()
	return {"rule": rule, "control": String(root_node.get_path_to(control)), "class": control.get_class(),
		"text": _text(control), "tooltip": control.tooltip_text,
		"rect": [int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)],
		"message": message}
