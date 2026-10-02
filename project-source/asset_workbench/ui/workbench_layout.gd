extends VBoxContainer

## Responsive containers and action placement only; the workbench owns every operation.

signal action_requested(action: StringName)
signal appearance_changed(dark: bool, checker: bool)

const Widgets = preload("res://asset_workbench/ui/workbench_widgets.gd")

var assets: VBoxContainer
var preview: VBoxContainer
var properties: ScrollContainer
var state: Label
var target: Label
var status: Label
var _workspace: HSplitContainer = HSplitContainer.new()
var _inner: HSplitContainer = HSplitContainer.new()
var _asset_panel: PanelContainer
var _preview_panel: PanelContainer
var _inspector_panel: PanelContainer
var _tabs: HBoxContainer = HBoxContainer.new()
var _compact_actions: VBoxContainer = VBoxContainer.new()
var _compact_context: Label
var _playback: HFlowContainer = HFlowContainer.new()
var _object_name: Label
var _playback_name: Label
var _trials: Array[Button] = []
var _appearance: MenuButton = MenuButton.new()
var _region: int = 1
var _target_path: String = ""
var _save_footer: VBoxContainer = VBoxContainer.new()


func build(title: String) -> void:
	_build_header(title)
	_build_tabs()
	_workspace.name = "WorkbenchBody"
	_workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_workspace)
	assets = _panel(_workspace, "AssetColumn", 260)
	_asset_panel = assets.get_parent() as PanelContainer
	_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace.add_child(_inner)
	preview = _panel(_inner, "EventColumn", 180)
	_preview_panel = preview.get_parent() as PanelContainer
	_preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inspector := _panel(_inner, "InspectorColumn", 340)
	_inspector_panel = inspector.get_parent() as PanelContainer
	_build_inspector(inspector)
	_build_compact_actions()
	_build_status()
	resized.connect(_adapt)
	_adapt()
	_appearance.grab_focus.call_deferred()


func finish_preview() -> void:
	_playback_name = Widgets.label(preview, "当前对象")
	preview.add_child(_playback)
	_play_controls(_playback)


func display_context(object_name: String, index: int, dirty: bool, path: String) -> void:
	_target_path = path
	_object_name.text = "当前对象：" + object_name
	_object_name.tooltip_text = object_name
	state.text = "未保存更改" if dirty else "与已保存 Cue 一致"
	state.theme_type_variation = "DirtyState" if dirty else "Label"
	for trial: int in _trials.size():
		_trials[trial].set_pressed_no_signal(trial == index)
	var context := "%s · 对象 %s · %s" % [object_name, "A" if index == 0 else "B", state.text]
	_playback_name.text = "当前对象：" + context
	target.text = "保存目标：%s\n仅写当前 Cue；影响引用它的消费场景。" % path.get_file()
	target.tooltip_text = path
	_compact_context.text = context + "\n保存：" + path.get_file() + "（影响引用此 Cue 的场景）"


func _build_header(title: String) -> void:
	var header := HBoxContainer.new()
	add_child(header)
	var caption := Widgets.label(header, title, false)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.add_theme_font_size_override("font_size", 21)
	_appearance.text = "外观设置"
	_appearance.focus_mode = Control.FOCUS_ALL
	header.add_child(_appearance)
	var popup := _appearance.get_popup()
	popup.add_check_item("深色界面", 0)
	popup.add_check_item("图像透明棋盘格", 1)
	popup.hide_on_checkable_item_selection = false
	popup.id_pressed.connect(func(id: int) -> void:
		popup.set_item_checked(id, not popup.is_item_checked(id))
		appearance_changed.emit(popup.is_item_checked(0), popup.is_item_checked(1)))


func _build_tabs() -> void:
	add_child(_tabs)
	var group := ButtonGroup.new()
	for index: int in 3:
		var button := Widgets.button(_tabs, ["资源候选", "组合预览", "对象属性"][index],
			_show_region.bind(index))
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_pressed_no_signal(index == _region)


func _panel(parent: Node, panel_name: String, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size.x = width
	parent.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	return content


func _build_inspector(parent: VBoxContainer) -> void:
	_object_name = Widgets.label(parent, "当前对象")
	_object_name.add_theme_font_size_override("font_size", 18)
	var selector := HBoxContainer.new()
	parent.add_child(selector)
	Widgets.label(selector, "对象方案", false)
	var group := ButtonGroup.new()
	for index: int in 2:
		var button := _action(selector, "A" if index == 0 else "B",
			&"object_a" if index == 0 else &"object_b")
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_trials.append(button)
	state = Widgets.label(parent, "")
	properties = ScrollContainer.new()
	properties.name = "ParameterColumn"
	properties.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	properties.size_flags_vertical = Control.SIZE_EXPAND_FILL
	properties.follow_focus = true
	parent.add_child(properties)
	parent.add_child(_save_footer)
	_action(_save_footer, "保存当前方案", &"save")
	target = Widgets.label(_save_footer, "")
	var footer := HFlowContainer.new()
	_save_footer.add_child(footer)
	Widgets.button(footer, "保存路径…", _show_target)
	_object_menu(footer)


func _object_menu(parent: Node) -> void:
	var menu := MenuButton.new()
	menu.text = "对象更多…"
	menu.focus_mode = Control.FOCUS_ALL
	parent.add_child(menu)
	var ids: Array[StringName] = [&"analyze_object", &"copy", &"reset", &"reload", &"open"]
	var captions := ["分析当前对象源资源", "复制当前方案到另一方案", "恢复当前方案到已保存值",
		"从磁盘重载（丢弃 A/B 两份草稿）", "打开消费场景（使用已保存 Cue）"]
	for caption: String in captions:
		menu.get_popup().add_item(caption)
	menu.get_popup().id_pressed.connect(func(id: int) -> void: action_requested.emit(ids[id]))


func _play_controls(parent: Container) -> void:
	_action(parent, "触发", &"trigger")
	_action(parent, "循环 0.6 s", &"repeat")
	_action(parent, "快速 0.1 s", &"rapid")
	_action(parent, "停止全部", &"stop")


func _build_compact_actions() -> void:
	add_child(_compact_actions)
	_compact_context = Widgets.label(_compact_actions, "")
	var actions := HFlowContainer.new()
	_compact_actions.add_child(actions)
	_play_controls(actions)
	_action(actions, "保存当前方案", &"save")
	Widgets.button(actions, "保存路径…", _show_target)
	_object_menu(actions)


func _build_status() -> void:
	var bar := HBoxContainer.new()
	add_child(bar)
	status = Widgets.label(bar, "", false)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Widgets.button(bar, "操作详情…", func() -> void:
		Widgets.show_text(self, "最近操作结果", status.text))


func _action(parent: Node, caption: String, id: StringName) -> Button:
	var button := Widgets.button(parent, caption, func() -> void: action_requested.emit(id))
	button.name = String(id).to_pascal_case()
	return button


func _show_target() -> void:
	Widgets.show_text(self, "保存目标（可选择复制）", _target_path
		+ "\n\n仅保存当前对象的当前方案。共享此 Cue 的消费场景会受影响。"
		+ "\n不写入源图像、音频或共享材质预设。")


func _show_region(index: int) -> void:
	_region = index
	for child: int in _tabs.get_child_count():
		(_tabs.get_child(child) as Button).set_pressed_no_signal(child == index)
	_adapt()
	(_tabs.get_child(index) as Button).grab_focus()


func _adapt() -> void:
	if _inspector_panel == null:
		return
	var compact := size.x < 1180
	_tabs.visible = compact
	_compact_actions.visible = compact
	_save_footer.visible = not compact
	_playback.visible = not compact
	if _playback_name != null:
		_playback_name.visible = not compact
	_asset_panel.visible = not compact or _region == 0
	_preview_panel.visible = not compact or _region == 1
	_inspector_panel.visible = not compact or _region == 2
	_inner.visible = not compact or _region != 0
	_asset_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	_inspector_panel.size_flags_horizontal = _asset_panel.size_flags_horizontal
	if get_viewport().gui_get_focus_owner() == null:
		_appearance.grab_focus.call_deferred()
