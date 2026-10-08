extends VBoxContainer
## The inspector for one slot: header, candidate list, analysis, parameters and the adopt footer.

signal requested(action: String)
signal reported(result: Dictionary)
signal analysis_changed(slot_id: String, candidate: Resource)
## A parameter control changed a value.
signal edited()

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Controls := preload("res://dev/debug/_shared/property_controls.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Select := preload("res://dev/debug/_shared/debug_select.gd")
const ParamRow := preload("res://dev/debug/_shared/param_row.gd")
const CandidateSection := preload("res://dev/debug/_shared/candidate_section.gd")
const HEADER_HEIGHT := 52.0
const FOOTER_HEIGHT := 48.0
const SAVE_AS_ID := 1000
const DELETE_ID := 1001
## Widest the preset dropdown gets, so saving and reverting stay inside the inspector.
const PRESET_WIDTH := 200.0
const EXCLUDED: Array[String] = ["candidate", "candidate_params"]

var slot: Slot
var editors: Dictionary[String, Callable] = {}
var locked: bool = false
## The comparison is shown: values are read-only and change marks are hidden.
var comparing: bool = false
## Why the panel is locked, shown on its disabled buttons.
var lock_reason: String = ""
var analysis_host: VBoxContainer
var rows: Array[ParamRow] = []
var adopt: Button
var preset_select: Select
var title: Label
var _identity: Label
var _changes: PanelContainer
var _pin: Button
var _copy: Button
var _content: VBoxContainer
var _candidates: CandidateSection
var _tools: Array[Control] = []
var _adopt_menu: MenuButton
var _preset_names: PackedStringArray = []
var _preset_provider: Callable
var _chosen_preset: String = ""


func _init() -> void:
	name = "SlotPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 0)
	_build_header()
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right"]:
		margins.add_theme_constant_override("margin_" + edge, 24)
	margins.add_theme_constant_override("margin_top", 4)
	margins.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margins)
	_content = Kit.column(0)
	_content.name = "Content"
	margins.add_child(_content)
	analysis_host = Kit.column(0)
	analysis_host.name = "AnalysisHost"
	_build_footer()


func _build_header() -> void:
	var line := Kit.row(8)
	var header := Kit.panel(&"InspectorHeader", line)
	header.custom_minimum_size.y = HEADER_HEIGHT
	add_child(header)
	title = Kit.label("选择一个插槽", &"TitleLabel")
	line.add_child(title)
	var identity := Kit.row(2)
	_identity = Kit.label("", &"MonoId")
	identity.add_child(_identity)
	_copy = Kit.inline_button("copy", "复制编号")
	_copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(slot.id)
		reported.emit({"error": OK, "message": "已复制编号 " + slot.id}))
	identity.add_child(_copy)
	line.add_child(identity)
	line.add_child(Kit.spacer())
	_changes = Kit.chip("", "dot", &"warn")
	line.add_child(_changes)
	_pin = Kit.icon_button("pin", "钉选：在“钉选”筛选里显示这个插槽", &"IconToggle")
	_pin.toggle_mode = true
	_pin.toggled.connect(_pin_changed)
	line.add_child(_pin)


func _build_footer() -> void:
	var line := Kit.row(0)
	var footer := Kit.panel(&"InspectorFooter", line)
	footer.custom_minimum_size.y = FOOTER_HEIGHT
	add_child(footer)
	line.add_child(Kit.label("采纳会改写游戏文件", &"HintText"))
	line.add_child(Kit.spacer())
	adopt = Kit.text_button("采纳到游戏", "file-export",
		"把这个插槽的当前设定写入游戏文件（会要求确认）", &"DangerButton")
	adopt.pressed.connect(func() -> void: requested.emit("写入默认值"))
	line.add_child(adopt)
	var gap := Control.new()
	gap.custom_minimum_size.x = 4.0
	line.add_child(gap)
	_adopt_menu = MenuButton.new()
	_adopt_menu.flat = false
	_adopt_menu.icon = Kit.icon("chevron-up")
	_adopt_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_adopt_menu.theme_type_variation = &"DangerButton"
	_adopt_menu.tooltip_text = "更多采纳方式"
	_adopt_menu.custom_minimum_size = Vector2(Kit.CONTROL, Kit.CONTROL)
	_adopt_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_adopt_menu.add_theme_constant_override("icon_max_width", 14)
	_adopt_menu.get_popup().add_item("采纳全部插槽（当前组合）到游戏…", 0)
	_adopt_menu.get_popup().id_pressed.connect(func(_id: int) -> void:
		requested.emit("写入组合默认值"))
	line.add_child(_adopt_menu)


## Curve and Gradient editors expose bind(value, changed), set_value(value), set_locked(bool)
## and set_expanded(bool).
func register_editor(resource_type: String, factory: Callable) -> void:
	editors[resource_type] = factory
	if slot != null:
		build_form()


func bind(value: Slot, preset_provider: Callable) -> void:
	slot = value
	_preset_provider = preset_provider
	title.text = "选择一个插槽" if slot == null else slot.display_name()
	_identity.text = "" if slot == null else slot.id
	_copy.visible = slot != null
	_pin.visible = slot != null
	if slot != null:
		_pin.set_pressed_no_signal(slot.pinned)
		_pin.icon = Kit.icon("pinned" if slot.pinned else "pin")
	build_form()


func chosen_preset() -> String:
	return _chosen_preset


func build_form() -> void:
	if analysis_host.get_parent() != null:
		analysis_host.get_parent().remove_child(analysis_host)
	Kit.clear(_content)
	rows.clear()
	_tools.clear()
	_candidates = null
	if slot == null:
		var empty := Kit.label("从左侧列表选择一个插槽", &"HintText")
		empty.custom_minimum_size.y = 48.0
		_content.add_child(empty)
		_content.add_child(analysis_host)
		refresh_state()
		set_locked(locked)
		analysis_changed.emit("", null)
		return
	if not slot.candidates.is_empty():
		_content.add_child(Kit.section_frame(_candidate_section(), true))
	_content.add_child(analysis_host)
	_content.add_child(Kit.section_frame(_parameter_section(), slot.candidates.is_empty()))
	refresh_state()
	set_locked(locked)
	_emit_analysis()


func _candidate_section() -> VBoxContainer:
	_candidates = CandidateSection.new(slot)
	_candidates.chosen.connect(_candidate_selected)
	_candidates.requested.connect(requested.emit)
	_candidates.reported.connect(reported.emit)
	return _candidates


func _parameter_section() -> VBoxContainer:
	var block := Kit.section("参数")
	var header := block.get_child(0) as HBoxContainer
	preset_select = Select.new("", "预设", true)
	preset_select.max_width = PRESET_WIDTH
	preset_select.chosen.connect(_preset_chosen)
	header.add_child(preset_select)
	_refresh_presets()
	var save := Kit.icon_button("device-floppy", "另存为新预设（游戏文件不变）"
		if slot.preset_name.is_empty() else "保存预设：把当前参数存进预设 %s（游戏文件不变）" % slot.preset_name)
	save.pressed.connect(func() -> void: requested.emit("保存"))
	header.add_child(save)
	var revert := Kit.icon_button("arrow-back-up", "撤销改动：回到%s的参数" % _preset_label())
	revert.pressed.connect(func() -> void: requested.emit("撤销改动"))
	header.add_child(revert)
	_tools.append_array([preset_select, save, revert])
	var list := Kit.column(0)
	list.name = "Rows"
	block.add_child(list)
	_add_resource(list, slot.live, "")
	var params := slot.live.get("candidate_params") as Resource \
		if not slot.candidates.is_empty() else null
	if params != null and not Controls.fields(params).is_empty():
		if list.get_child_count() > 0:
			var caption := Kit.label("候选参数", &"SectionLabel")
			caption.custom_minimum_size.y = Kit.CONTROL
			list.add_child(caption)
		_add_resource(list, params, "candidate_params/")
	return block


func _preset_label() -> String:
	return "预设 " + slot.preset_name if not slot.preset_name.is_empty() else "游戏原值"


func _refresh_presets() -> void:
	_preset_names = _preset_provider.call(slot.directory.path_join("presets"))
	var captions: PackedStringArray = ["游戏原值"]
	captions.append_array(_preset_names)
	preset_select.set_items(captions, _preset_names.find(slot.preset_name) + 1)
	# A long name is cut in the dropdown; the tooltip keeps it whole.
	Messages.usable_tooltip(preset_select, "插槽预设：选择后载入它的全部参数（当前：%s）"
		% preset_select.selected_text())
	var menu := preset_select.get_popup()
	menu.add_separator()
	menu.add_item("另存为新预设…", SAVE_AS_ID)
	if not slot.preset_name.is_empty():
		menu.add_item("删除预设 %s…" % slot.preset_name, DELETE_ID)


func _preset_chosen(id: int) -> void:
	if id == SAVE_AS_ID:
		requested.emit("另存")
	elif id == DELETE_ID:
		requested.emit("删除")
	else:
		_chosen_preset = "" if id == 0 else _preset_names[id - 1]
		requested.emit("加载预设")


func _add_resource(list: VBoxContainer, resource: Resource, prefix: String) -> void:
	for property in Controls.fields(resource):
		var field := String(property.name)
		if prefix.is_empty() and field in EXCLUDED:
			continue
		var callback := _value_changed.bind(resource, field)
		var control := Controls.create(property, resource.get(property.name), callback, editors,
			slot.constant("VALUES", {}).get(field, {}),
			func(value: Variant) -> String: return slot.value_text(field, value))
		var tall := control.has_method("set_expanded")
		var row := ParamRow.new(prefix + field, slot.field_caption(field, property.caption),
			Controls.layout(control), tall)
		row.revert_requested.connect(_revert)
		if tall:
			_add_expand_button(row, control)
		list.add_child(row)
		rows.append(row)


func _add_expand_button(row: ParamRow, editor: Control) -> void:
	var expand := Kit.inline_button("arrows-maximize", "展开完整编辑器")
	expand.pressed.connect(func() -> void:
		editor.set_expanded(not editor.expanded)
		expand.icon = Kit.icon("arrows-minimize" if editor.expanded else "arrows-maximize")
		Messages.usable_tooltip(expand, "收起完整编辑器" if editor.expanded else "展开完整编辑器"))
	row.tools.add_child(expand)
	row.tools.move_child(expand, 0)


func _value_changed(value: Variant, resource: Resource, field: String) -> void:
	if not locked:
		resource.set(field, value)
		refresh_state()
		_emit_analysis()
		edited.emit()


func _revert(path: String) -> void:
	if locked:
		return
	reported.emit(slot.revert_field(path))
	build_form()


## Marks modified rows and counts changes against the loaded preset or game value.
func refresh_state() -> void:
	_changes.visible = false
	if slot == null:
		return
	var modified := slot.modified_fields() if not comparing else PackedStringArray()
	_changes.visible = not modified.is_empty()
	Kit.chip_text(_changes, "%d 项改动" % modified.size())
	var captions: PackedStringArray = []
	for path in modified:
		captions.append("实现" if path == "candidate" else slot.field_caption(path.get_file(),
			path.get_file().capitalize()))
	_changes.tooltip_text = "与%s相比改动的参数：%s" % [_preset_label(), "、".join(captions)]
	_show_preset(not modified.is_empty() or slot.differs_from_preset)
	for row in rows:
		var on := row.path in modified
		row.set_modified(on, _revert_tooltip(row) if on else "")


## The preset dropdown names the loaded preset, marked when the values differ from it.
func _show_preset(modified: bool) -> void:
	if preset_select != null:
		var shown := "游戏原值" if slot.preset_name.is_empty() else slot.preset_name
		preset_select.set_value(shown + ("（已修改）" if modified else ""))


## Names the saved value the way the value box shows it; rows without one use the slot's
## words or the plain value.
func _revert_tooltip(row: ParamRow) -> String:
	var value: Variant = slot.saved_value(row.path)
	var boxes := row.find_children("*", "SpinBox", true, false)
	var shown := ""
	if (value is float or value is int) and boxes.size() == 1:
		shown = Controls.value_text(boxes[0], value)
	elif value != null:
		shown = slot.value_text(row.path.get_file(), value)
		if shown.is_empty():
			shown = _plain(value)
	if shown.is_empty():
		return "还原这一项（回到%s）" % _preset_label()
	return "还原这一项（%s：%s）" % [_preset_label(), shown]


static func _plain(value: Variant) -> String:
	if value is float:
		return String.num(value, 3)
	if value is int or value is bool or value is String:
		return str(value)
	if value is Color:
		return "#" + (value as Color).to_html()
	return ""


func set_locked(value: bool) -> void:
	var changed := locked != value
	locked = value
	for row in rows:
		Controls.set_locked(row, value, lock_reason)
	for tool in _tools:
		Controls.set_locked(tool, value, lock_reason)
	if _candidates != null:
		_candidates.set_locked(value, lock_reason)
	var reason := "先在左侧选择一个插槽" if slot == null else lock_reason
	Messages.explain(adopt, value or slot == null, reason)
	Messages.explain(_adopt_menu, value or slot == null, reason)
	if changed and slot != null:
		_emit_analysis()


func _candidate_selected(index: int) -> void:
	if locked:
		return
	reported.emit(slot.select_candidate(index))
	build_form()


func _pin_changed(value: bool) -> void:
	if slot != null:
		slot.pinned = value
		_pin.icon = Kit.icon("pinned" if value else "pin")
		slot.changed.emit()


func _emit_analysis() -> void:
	var candidate := slot.live.get("candidate") as Resource \
		if slot != null and not slot.candidates.is_empty() else null
	analysis_changed.emit("" if slot == null else slot.id, candidate)
