## 按界面任务试用的驱动基类。驱动脚本 extends 本文件的路径，只在 _run() 里写步骤；
## 由 run-ui-trial.py 在改过名的项目副本中启动。退出码：0 完成，1 步骤失败或引擎报错，
## 2 看门狗到时，3 项目名不以 " trial" 结尾而拒绝运行。
extends SceneTree

const TRIAL_SUFFIX := " trial"
const EXIT_FAILED := 1
const EXIT_WATCHDOG := 2
const EXIT_REFUSED := 3
const ErrorLogger := preload("res://yaya/tools/ui-trial/ui_trial_error_logger.gd")

## 看门狗秒数；命令行 --ui-trial-watchdog=N 覆盖。脚本卡住或报错后不退出时，由它结束进程。
var watchdog_seconds: float = 120.0
## 输出目录（steps.log、截图、扫描结果）；命令行 --ui-trial-out=DIR 覆盖。
var output_directory: String = "user://ui-trial"
## 本次运行是否为无头模式；无头时不能截图。
var headless: bool = DisplayServer.get_name() == "headless"

var _finished: bool = false
var _writing_log: bool = false
var _step_count: int = 0
var _started_msec: int = 0
var _steps_file: FileAccess
var _logger: ErrorLogger


## 子类覆盖：写试用步骤，可以 await。正常返回即视为完成。
func _run() -> void:
	pass


func _initialize() -> void:
	_started_msec = Time.get_ticks_msec()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ui-trial-out="):
			output_directory = argument.trim_prefix("--ui-trial-out=")
		elif argument.begins_with("--ui-trial-watchdog="):
			watchdog_seconds = argument.trim_prefix("--ui-trial-watchdog=").to_float()
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		_stop_for_log_error(directory_error)
		return
	_steps_file = FileAccess.open(output_directory.path_join("steps.log"), FileAccess.WRITE)
	if _steps_file == null:
		_stop_for_log_error(FileAccess.get_open_error())
		return
	var name := String(ProjectSettings.get_setting("application/config/name", ""))
	if not name.ends_with(TRIAL_SUFFIX):
		_log("REFUSED: project name '%s' does not end with '%s'; run prepare-trial-copy.py" % [name, TRIAL_SUFFIX])
		_finish(EXIT_REFUSED)
		return
	_logger = ErrorLogger.new()
	_logger.on_error = _engine_reported
	OS.add_logger(_logger)
	create_timer(watchdog_seconds, true, false, true).timeout.connect(_watchdog_expired)
	if headless:
		# 无头模式的根窗口只有 64×64 且改不了尺寸；按项目视口尺寸缩放画布，控件才按真实尺寸布局。
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		root.content_scale_size = Vector2i(
			int(ProjectSettings.get_setting("display/window/size/viewport_width", 1152)),
			int(ProjectSettings.get_setting("display/window/size/viewport_height", 648)))
	_log("start: %s, watchdog %ss, %s" % [name, watchdog_seconds, "headless" if headless else "window"])
	if not _finished:
		_start.call_deferred()


func _finalize() -> void:
	if _logger != null:
		OS.remove_logger(_logger)
	if _steps_file != null:
		_steps_file.close()


func _start() -> void:
	await process_frame
	if _finished:
		return
	await _run()
	if not _finished:
		step("all steps done")
		_finish(OK)


# ---------- 记录与结束 ----------

## 记录一个步骤：写入 steps.log 并打印。
func step(text: String) -> void:
	if _finished:
		return
	_step_count += 1
	_log("step %d: %s" % [_step_count, text])


## 让试用失败并退出。之后的步骤不再记录。
func fail(text: String) -> void:
	if _finished:
		return
	_log("FAIL: " + text)
	_finish(EXIT_FAILED)


## 条件不成立时失败；返回条件，便于驱动脚本 `if not expect(...): return`。
func expect(condition: bool, text: String) -> bool:
	if not condition:
		fail(text)
	elif not _finished:
		_log("ok: " + text)
	return condition


func is_finished() -> bool:
	return _finished


func _log(text: String) -> void:
	if _finished:
		return
	var line := "[ui-trial %7.2fs] %s" % [(Time.get_ticks_msec() - _started_msec) / 1000.0, text]
	# 保留原因：步骤与引擎报错按时间交错写进 engine.log，看报错前执行到哪一步。用户同意于 2026-10-08。
	print(line)  # gdlint:ignore-line:print-statement
	_writing_log = true
	_steps_file.store_line(line)
	if not _finished:
		_steps_file.flush()
	_writing_log = false
	if not _finished and _steps_file.get_error() != OK:
		_stop_for_log_error(_steps_file.get_error())


func _stop_for_log_error(error: Error) -> void:
	_finish(EXIT_FAILED)
	push_error("UI TRIAL LOG ERROR: %s: %s" % [output_directory.path_join("steps.log"), error_string(error)])


func _finish(code: int) -> void:
	if _finished:
		return
	_finished = true
	quit(code)


func _engine_reported(is_warning: bool, text: String) -> void:
	if _finished:
		return
	if _writing_log:
		_stop_for_log_error(_steps_file.get_error())
		return
	if is_warning:
		_log("engine warning: " + text)
	else:
		_log("FAIL: engine error: " + text)
		_finish(EXIT_FAILED)


func _watchdog_expired() -> void:
	if not _finished:
		_log("FAIL: watchdog expired after %ss" % watchdog_seconds)
		_finish(EXIT_WATCHDOG)


# ---------- 等待 ----------

func wait_frames(count: int = 1) -> void:
	for _i in range(count):
		await process_frame


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


## 每帧检查 condition，成立返回 true；超时则失败并返回 false。
func wait_until(condition: Callable, timeout_seconds: float, text: String) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while not condition.call():
		if _finished:
			return false
		if Time.get_ticks_msec() > deadline:
			fail("timed out after %ss waiting for: %s" % [timeout_seconds, text])
			return false
		await process_frame
	_log("ok: " + text)
	return true


# ---------- 场景与节点 ----------

## 实例化场景并设为当前场景，返回根节点；加载失败时让试用失败并返回 null。
func open_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		fail("cannot load scene " + path)
		return null
	var node := packed.instantiate()
	root.add_child(node)
	current_scene = node
	step("opened scene " + path)
	return node


## 按节点路径（含 "/"）或节点名查找节点；名称在 from 之下递归查找（含代码创建的节点和子窗口）。
func find(target: String, from: Node = null) -> Node:
	var base := from if from != null else root
	if target.contains("/"):
		return base.get_node_or_null(NodePath(target))
	return base.find_child(target, true, false)


## 和 find 相同，找不到时让试用失败。target 是 null（例如上一步 find 没找到）时同样按找不到处理。
func require(target: Variant, from: Node = null) -> Node:
	if target is Node:
		return target
	if not (target is String or target is StringName or target is NodePath):
		fail("node not found: got %s instead of a node, node name or path"
			% ("null" if target == null else type_string(typeof(target))))
		return null
	var node := find(String(target), from)
	if node == null:
		fail("node not found: %s" % target)
	return node


## 返回控件上显示的文字：Label、Button、RichTextLabel、LineEdit、TextEdit。
func text_of(target: Variant, from: Node = null) -> String:
	var node := require(target, from)
	if node is Label or node is Button or node is LineEdit:
		return node.text
	if node is RichTextLabel:
		return node.get_parsed_text()
	if node is TextEdit:
		return node.text
	fail("%s (%s) shows no text" % [node.name if node != null else target, node.get_class() if node != null else ""])
	return ""


## 返回 from 之下全部可见文字控件的 [路径, 文字]，用于查找状态栏、提示等显示内容。
func visible_texts(from: Node = null) -> Array:
	var base := from if from != null else root
	var found: Array = []
	for node in base.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		var text := ""
		if control is Label or control is Button or control is LineEdit:
			text = control.text
		elif control is RichTextLabel:
			text = control.get_parsed_text()
		if not text.strip_edges().is_empty():
			found.append([String(base.get_path_to(control)), text])
	return found


# ---------- 操作 ----------

## 像用户点击一样按下按钮：按钮必须可见且未禁用；切换按钮先改按下状态。
func click(target: Variant, from: Node = null) -> bool:
	var button := require(target, from) as BaseButton
	if button == null:
		return expect(false, "%s is a button" % target)
	if not button.is_visible_in_tree() or button.disabled:
		var reason := "hidden" if not button.is_visible_in_tree() else "disabled (%s)" % button.tooltip_text
		return expect(false, "button %s can be clicked; it is %s" % [button.name, reason])
	step("click %s '%s'" % [button.name, button.text if button is Button else ""])
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	button.pressed.emit()
	return true


## 在下拉框中选择一项：item 为序号或显示文字。
func select_option(target: Variant, item: Variant, from: Node = null) -> bool:
	var options := require(target, from) as OptionButton
	if options == null:
		return expect(false, "%s is an OptionButton" % target)
	var index: int = item if item is int else -1
	if item is String:
		for i in range(options.item_count):
			if options.get_item_text(i) == item:
				index = i
	if index < 0 or index >= options.item_count:
		return expect(false, "%s has item %s" % [options.name, item])
	step("select '%s' in %s" % [options.get_item_text(index), options.name])
	options.select(index)
	options.item_selected.emit(index)
	return true


## 向窗口注入一次按键（按下后松开），默认注入根窗口。
func press_key(keycode: Key, window: Window = null, shift: bool = false, ctrl: bool = false,
		alt: bool = false) -> void:
	var target := window if window != null else root
	step("press %s on %s" % [OS.get_keycode_string(keycode), target.name])
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		event.shift_pressed = shift
		event.ctrl_pressed = ctrl
		event.alt_pressed = alt
		target.push_input(event)
		await process_frame


## 把窗口画面存成 PNG（输出目录下的 file_name）。无头模式不渲染，记录跳过并返回 false。
func save_screenshot(file_name: String, window: Window = null) -> bool:
	if headless:
		step("skip screenshot %s (headless)" % file_name)
		return false
	var target := window if window != null else root
	await RenderingServer.frame_post_draw
	var image := target.get_texture().get_image()
	var path := output_directory.path_join(file_name)
	if image == null or image.save_png(path) != OK:
		return expect(false, "screenshot saved to " + path)
	step("screenshot " + path)
	return true
