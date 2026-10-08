# gdlint:ignore-file:file-length=422
# 保留原因：调试窗口的组装入口，把会话、播放、工具栏、面板和对话框连起来；可移出的只有约 30 行屏幕尺寸代码，移出后窗口里还要留转发函数。用户同意于 2026-10-08。
extends Window

const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Playback := preload("res://dev/debug/_shared/playback_controller.gd")
const Bridge := preload("res://dev/debug/_shared/input_bridge.gd")
const Toolbar := preload("res://dev/debug/_shared/debug_toolbar.gd")
const CompareBar := preload("res://dev/debug/_shared/compare_bar.gd")
const SlotList := preload("res://dev/debug/_shared/slot_list.gd")
const SlotPanel := preload("res://dev/debug/_shared/slot_panel.gd")
const StatusBar := preload("res://dev/debug/_shared/debug_status_bar.gd")
const Dialogs := preload("res://dev/debug/_shared/debug_dialogs.gd")
const Writer := preload("res://dev/debug/_shared/default_writer.gd")
const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const PresetCommands := preload("res://dev/debug/_shared/preset_commands.gd")
const CurveEditor := preload("res://dev/debug/_shared/editors/curve_editor.gd")
const GradientEditor := preload("res://dev/debug/_shared/editors/gradient_editor.gd")
const Analyzer := preload("res://dev/debug/_shared/analyzer_service.gd")
const AudioAnalysis := preload("res://dev/debug/_shared/audio_analysis.gd")
const ScreenshotAnalysis := preload("res://dev/debug/_shared/screenshot_analysis.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
## Logical size of the v4 layout; the native window multiplies it by content_scale_factor.
const DESIGN_SIZE := Vector2(1000, 760)
const MINIMUM_SIZE := Vector2(800, 560)
const TAB_HEIGHT := 36.0
const WINDOW_GAP := 8
const TAB_WIDTH := 72.0
const TABS: Array[String] = ["调参", "分析"]
const LOCKED_PLAYING := "播放中参数已锁定：点播放条的“回到开头”结束播放后可修改"
const LOCKED_COMPARING := "正在显示对比对象：按 ` 回到当前改动后可修改"
const NO_TARGETS := "还没有调试对象：在 dev/debug/<对象>/ 下添加"
const NO_SAVE_HOOK := "调试会话可能写入真实存档：在 dev/debug/debug_project.gd 设置调试存档位置"

var session := Session.new()
var playback: Playback
var toolbar: Toolbar
var compare: CompareBar
var slot_list: SlotList
var panel: SlotPanel
var screenshots: ScreenshotAnalysis
var status: StatusBar
var dialogs: Dialogs
var presets: PresetCommands
var tabs: Array[Button] = []
var pages: Array[Control] = []
## Closes the game once the close question is answered; tests replace it.
var quit_game: Callable
var _screen: int = -1
var _sized: bool = false
var _bridges: Array[Node] = []


func _ready() -> void:
	_build_ui()
	close_requested.connect(hide)
	visibility_changed.connect(_visibility_changed)
	playback = Playback.new()
	add_child(playback)
	playback.changed.connect(_refresh)
	playback.failed.connect(func(result: Dictionary) -> void:
		report(Messages.outcome(result, "", "播放停止了", "检查固定局面后再点播放")))
	# A deferred switch loads other values; the inspector shows them at once, still locked.
	playback.next_pass.connect(func() -> void:
		session.apply_pending_compare()
		_rebind_panel())
	dialogs = Dialogs.new()
	dialogs.host = self
	add_child(dialogs)
	presets = PresetCommands.new(session, dialogs, report, _rebind_panel)
	session.changed.connect(_refresh)
	session.reported.connect(report)
	session.discover()
	toolbar.configure(session)
	compare.configure(session)
	slot_list.configure(session)
	quit_game = get_tree().quit
	get_tree().set_auto_accept_quit(false)
	# Closing the game window asks first when slots hold unsaved edits.
	get_tree().root.close_requested.connect(func() -> void:
		show()
		presets.ask_before_closing(quit_game))
	_install_bridge(get_tree().root)
	_install_bridge(self)
	get_tree().node_added.connect(_node_added)
	get_tree().scene_changed.connect(_scene_changed)
	# global joins every target's list, so start on another target when there is one.
	for target: RefCounted in session.targets:
		if target.id != "global" or target == session.targets.back():
			_select_target(target.id)
			break
	if session.active == null:
		panel.bind(null, session.store.list_names)


## `save_path` is the debug save that debug_project.gd chose, "" when it chose none.
func configure(save_path: String) -> void:
	playback.configure(save_path)
	var notes: PackedStringArray = []
	if session.targets.is_empty():
		notes.append(NO_TARGETS)
	if save_path.is_empty():
		notes.append(NO_SAVE_HOOK)
	if not notes.is_empty():
		report({"error": OK, "text": "；".join(notes), "keep": true})


func _build_ui() -> void:
	var background := Kit.panel(&"")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := Kit.column(0)
	background.add_child(column)
	column.add_child(_build_tabs())
	pages.append(_build_tuning_page())
	var analyzer := Analyzer.new()
	add_child(analyzer)
	AudioAnalysis.new(analyzer).attach(panel, func(result: Dictionary) -> void:
		report(result)
		_rebind_panel())
	pages.append(_build_analysis_page(analyzer))
	for page in pages:
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(page)
	status = StatusBar.new()
	column.add_child(status)
	show_tab(0)


## "调参 / 分析": switching only shows another page, the game and playback keep running.
func _build_tabs() -> MarginContainer:
	var line := Kit.row(0)
	var group := ButtonGroup.new()
	for index in range(TABS.size()):
		var tab := Kit.text_button(TABS[index], "", "", &"FilterSegment")
		tab.name = "Tab%d" % index
		tab.toggle_mode = true
		tab.button_group = group
		tab.custom_minimum_size = Vector2(TAB_WIDTH, Kit.INLINE)
		tab.pressed.connect(show_tab.bind(index))
		line.add_child(tab)
		tabs.append(tab)
	tabs[0].tooltip_text = "调参：插槽、候选、参数、对比与采纳"
	tabs[1].tooltip_text = "分析：截图色觉模拟等画面分析；音效分析在音效插槽的检查器里"
	var frame := Kit.panel(&"FilterFrame", line)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var margins := MarginContainer.new()
	margins.custom_minimum_size.y = TAB_HEIGHT
	margins.add_theme_constant_override("margin_left", 12)
	margins.add_theme_constant_override("margin_top", 6)
	margins.add_theme_constant_override("margin_bottom", 6)
	margins.add_child(frame)
	return margins


func _build_tuning_page() -> VBoxContainer:
	var page := Kit.column(0)
	page.name = "TuningPage"
	compare = CompareBar.new()
	compare.requested.connect(_command)
	compare.combo_chosen.connect(func(value: String) -> void:
		if not playback.locked() and not session.comparing:
			presets.load_combo(value))
	compare.compare_chosen.connect(func(value: String) -> void:
		report(session.choose_compare(value, playback.locked()))
		_after_values_changed())
	page.add_child(compare)
	toolbar = Toolbar.new()
	toolbar.requested.connect(_command)
	toolbar.target_selected.connect(_select_target)
	toolbar.speed_selected.connect(func(value: float) -> void: playback.set_speed(value))
	toolbar.loops_selected.connect(func(value: int) -> void:
		playback.loop_count = value
		_refresh())
	page.add_child(toolbar)
	var body := Kit.row(0)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	slot_list = SlotList.new()
	slot_list.slot_chosen.connect(_slot_selected)
	body.add_child(slot_list)
	panel = SlotPanel.new()
	panel.requested.connect(_slot_command)
	panel.reported.connect(report)
	panel.edited.connect(func() -> void: status.clear_result())
	panel.register_editor("Curve", CurveEditor.new)
	panel.register_editor("Gradient", GradientEditor.new)
	body.add_child(panel)
	return page


func _build_analysis_page(analyzer: Analyzer) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "AnalysisPage"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 24)
	margins.add_theme_constant_override("margin_top", 4)
	scroll.add_child(margins)
	screenshots = ScreenshotAnalysis.new(analyzer)
	margins.add_child(screenshots)
	return scroll


func show_tab(index: int) -> void:
	tabs[index].set_pressed_no_signal(true)
	for page_index in range(pages.size()):
		pages[page_index].visible = page_index == index


func _refresh() -> void:
	if not is_node_ready() or session.active == null:
		return
	var locked := playback.locked()
	toolbar.refresh(playback)
	compare.refresh(locked)
	panel.comparing = session.comparing
	panel.lock_reason = LOCKED_COMPARING if session.comparing else LOCKED_PLAYING
	panel.set_locked(locked or session.comparing)
	panel.refresh_state()
	slot_list.refresh()
	status.set_counts(session.dirty_count(), not session.combo_name.is_empty() and session.combo_dirty())


func _slot_selected(slot: Slot) -> void:
	report(session.select_slot(slot))
	panel.bind(slot, session.store.list_names)
	_refresh()


func _select_target(identity: String) -> void:
	if playback.locked():
		return
	var shown := identity
	for target: RefCounted in session.targets:
		if target.id == identity:
			shown = target.title()
	var result := session.select_target(identity)
	report(Messages.outcome(result, "", "没能打开调试对象 " + shown,
		"它的调参文件读不出来，请让 Agent 检查"))
	if result.error != OK:
		return
	toolbar.target_changed()
	panel.bind(null, session.store.list_names)
	slot_list.refresh(true)
	_refresh()


func _scene_changed() -> void:
	var scene := get_tree().current_scene
	if session.active != null and session.active.adapter != null and session.active.adapter.matches(scene):
		return
	if playback.locked():
		playback.cancel()
	for target: RefCounted in session.targets:
		if target.adapter != null and target.adapter.matches(scene):
			_select_target(target.id)
			return
	for target: RefCounted in session.targets:
		if target.id == "global":
			_select_target("global")
			return


func _node_added(node: Node) -> void:
	if node is Window:
		_install_bridge.call_deferred(node)
	playback.observe_node(node)


func _install_bridge(viewport: Window) -> void:
	if not is_instance_valid(viewport) or viewport.has_node("DebugInputBridge"):
		return
	var bridge := Bridge.new()
	bridge.name = "DebugInputBridge"
	bridge.receive = receive_key
	viewport.add_child(bridge)
	_bridges.append(bridge)


func receive_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return false
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code != KEY_F1 and code != KEY_QUOTELEFT:
		return false
	if key.echo:
		return true
	if code == KEY_F1:
		visible = not visible
		if visible:
			grab_focus()
			slot_list.search.grab_focus()
	else:
		_toggle_compare()
	return true


func _toggle_compare() -> void:
	report(session.toggle_compare(playback.locked()))
	_after_values_changed()


## Values loaded without the panel's own controls: rebuild it unless playback holds them.
func _after_values_changed() -> void:
	if not playback.locked():
		_rebind_panel()
	_refresh()


func _command(action: String) -> void:
	match action:
		"播放":
			report(Messages.outcome({"error": playback.start(toolbar.chosen_fixture(),
				session.active.adapter)}, "", "没能开始播放", "固定局面文件可能被占用，稍后再点播放"))
		"暂停": playback.toggle_pause()
		"开头":
			report(Messages.outcome({"error": playback.reset_to_start()},
				"已回到开头：播放结束。" + LOCKED_COMPARING if session.comparing
				else "已回到开头：播放结束，参数可以修改", "没能回到开头", "先点播放开始一遍"))
		"对比": _toggle_compare()
		"保存组合", "另存组合": presets.save_combo(action)
		"删除组合": presets.confirm_delete_combo()
		"写入组合默认值": _confirm_write(session.slots)


func _slot_command(action: String) -> void:
	var slot := session.selected
	if slot == null or playback.locked() or session.comparing:
		return
	match action:
		"加载预设": presets.load_preset(slot, panel.chosen_preset())
		"撤销改动": presets.revert(slot)
		"保存", "另存": presets.save_preset(slot, action)
		"删除": presets.confirm_delete_preset(slot)
		"写入默认值": _confirm_write([slot])
	if action.begins_with("试播:"):
		report(slot.actions.run(action.trim_prefix("试播:"), slot.live, get_tree().current_scene))
	_rebind_panel()


## One confirmation covers moving dev candidates into game/ and writing the slots.
func _confirm_write(slots: Array[Slot]) -> void:
	var plans := Adoption.plans_for(slots)
	var checked := Writer.preflight(slots, PackedStringArray(plans.keys()))
	if checked.error != OK:
		report({"error": checked.error, "detail": Messages.detail(checked), "text":
			"没能采纳：有 %d 项设定引用了不能放进游戏的文件。请让 Agent 查看详情"
				% checked.issues.size()})
		return
	dialogs.confirm(Adoption.confirm_text(slots, plans), func() -> void:
		report(Adoption.adopt_all(slots, plans))
		session.invalidate_compare()
		_rebind_panel(), "采纳到游戏", "采纳到游戏", Dialogs.DANGER)


func _rebind_panel() -> void:
	if session.selected != null:
		var result := session.selected.refresh_candidates()
		if result.error != OK or result.has("issues"):
			report(result)
	panel.bind(session.selected, session.store.list_names)
	_refresh()


func report(result: Dictionary) -> void:
	status.show_result(result)


func _visibility_changed() -> void:
	if visible:
		_update_dpi()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_POSITION_CHANGED and visible and current_screen != _screen:
		_update_dpi()


## Sizes follow the screen's DPI: 1000 x 760 logical pixels at first, kept inside the screen.
func _update_dpi() -> void:
	_screen = current_screen
	if DisplayServer.get_name() == "headless":
		return
	var previous := content_scale_factor
	var factor := maxf(1.0, DisplayServer.screen_get_dpi(_screen) / 96.0)
	content_scale_factor = factor
	var usable := DisplayServer.screen_get_usable_rect(_screen)
	var wanted := DESIGN_SIZE * factor if not _sized else Vector2(size) * factor / previous
	_sized = true
	min_size = Vector2i((MINIMUM_SIZE * factor).min(Vector2(usable.size)))
	size = Vector2i(wanted.min(Vector2(usable.size)))
	position = position.clamp(usable.position, usable.end - size)


## Puts the game window and this window side by side inside the usable screen area. When
## both do not fit, this window narrows to its minimum, then the game window shrinks with its
## aspect kept; the game stretches its canvas, so only the window size changes.
func place_beside(game: Window) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var usable := DisplayServer.screen_get_usable_rect(game.current_screen)
	size.x = clampi(usable.size.x - game.size.x - WINDOW_GAP, min_size.x, size.x)
	var room := usable.size.x - size.x - WINDOW_GAP
	if game.size.x > room:
		game.size = Vector2i(room, roundi(game.size.y * float(room) / game.size.x))
	var left := usable.position.x + maxi(0, floori((room - game.size.x) / 2.0))
	var middle := usable.get_center().y
	game.position = Vector2i(left, maxi(usable.position.y, middle - (game.size.y >> 1)))
	position = Vector2i(left + game.size.x + WINDOW_GAP, maxi(usable.position.y, middle - (size.y >> 1)))


func _exit_tree() -> void:
	get_tree().set_auto_accept_quit(true)
	for bridge in _bridges:
		if is_instance_valid(bridge) and not is_ancestor_of(bridge):
			bridge.queue_free()
