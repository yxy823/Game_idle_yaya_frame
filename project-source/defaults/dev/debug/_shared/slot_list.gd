extends PanelContainer
## The 240 px slot column: search, the all / modified / pinned filter and the grouped list.

signal slot_chosen(slot: RefCounted)

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const WIDTH := 240.0
const GROUP_HEIGHT := 28.0
const ITEM_HEIGHT := 26.0
const FILTER_HEIGHT := 22.0
const FILTERS: Array[String] = ["全部", "已修改", "钉选"]
const BAR_INSET := 5.0
## Group key of the pinned slots; no category path starts with "*".
const PINNED_GROUP := "*pinned"

enum Filter { ALL, MODIFIED, PINNED }

var search: LineEdit
var filter: Filter = Filter.ALL
var items: Dictionary[String, Button] = {}
var _list: VBoxContainer
var _filters: Array[Button] = []
var _counts: Array[Label] = []
var _captions: Array[Label] = []
var _collapsed: Dictionary[String, bool] = {}
var _shown: PackedStringArray = []
var _session: Session


func _init() -> void:
	name = "SlotList"
	theme_type_variation = &"SidePanel"
	custom_minimum_size.x = WIDTH
	var column := Kit.column(0)
	add_child(column)
	var top := MarginContainer.new()
	for edge: String in ["left", "top", "right"]:
		top.add_theme_constant_override("margin_" + edge, 12)
	top.add_theme_constant_override("margin_bottom", 8)
	column.add_child(top)
	var tools := Kit.column(8)
	top.add_child(tools)
	search = LineEdit.new()
	search.theme_type_variation = &"SearchEdit"
	search.placeholder_text = "搜索插槽名称、编号或参数"
	search.custom_minimum_size.y = Kit.CONTROL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_text: String) -> void: refresh(true))
	var glass := Kit.glyph("search", 15.0, Kit.color(&"tx3"))
	search.add_child(glass)
	glass.position = Vector2(8, 6.5)
	glass.size = Vector2(15, 15)
	tools.add_child(search)
	tools.add_child(_build_filters())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 8)
	scroll.add_child(margins)
	_list = Kit.column(0)
	_list.name = "List"
	margins.add_child(_list)


func _build_filters() -> PanelContainer:
	var line := Kit.row(0)
	var group := ButtonGroup.new()
	for index in range(FILTERS.size()):
		var button := Button.new()
		button.name = "Filter%d" % index
		button.theme_type_variation = &"FilterSegment"
		button.toggle_mode = true
		button.button_group = group
		button.set_pressed_no_signal(index == filter)
		button.custom_minimum_size.y = FILTER_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(set_filter.bind(index))
		var content := Kit.row(4)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var caption := Kit.label(FILTERS[index], &"StatusText")
		var count := Kit.label("0", &"HintText")
		content.add_child(caption)
		content.add_child(count)
		line.add_child(button)
		_filters.append(button)
		_captions.append(caption)
		_counts.append(count)
	return Kit.panel(&"FilterFrame", line)


func configure(session: Session) -> void:
	_session = session


func set_filter(value: int) -> void:
	filter = value as Filter
	_filters[value].set_pressed_no_signal(true)
	refresh(true)


## Rebuilds rows when the visible set or the pins change; otherwise only updates marks and
## selection. Pinned slots are listed first in their own "钉选" group.
func refresh(force: bool = false) -> void:
	if _session == null:
		return
	var visible_ids: PackedStringArray = []
	var dirty: Dictionary[String, bool] = {}
	for slot in _session.slots:
		dirty[slot.id] = _session.slot_dirty(slot)
		if matches(slot):
			visible_ids.append(("*" if slot.pinned else "") + slot.id)
	_paint_filters(dirty)
	if force or visible_ids != _shown:
		_rebuild(visible_ids)
	for slot in _session.slots:
		if items.has(slot.id):
			_update_item(items[slot.id], slot, dirty[slot.id])


func _paint_filters(dirty: Dictionary[String, bool]) -> void:
	var counts := [_session.slots.size(), dirty.values().count(true), 0]
	for slot in _session.slots:
		counts[Filter.PINNED] += 1 if slot.pinned else 0
	for index in range(FILTERS.size()):
		_counts[index].text = str(counts[index])
		_captions[index].add_theme_color_override("font_color",
			Kit.color(&"tx1") if index == filter else Kit.color(&"tx2"))


func matches(slot: Slot) -> bool:
	var text := search.text.strip_edges().to_lower()
	return (filter != Filter.MODIFIED or _session.slot_dirty(slot)) \
		and (filter != Filter.PINNED or slot.pinned) \
		and (text.is_empty() or text in slot.search_text())


func _rebuild(visible_ids: PackedStringArray) -> void:
	_shown = visible_ids
	Kit.clear(_list)
	items.clear()
	var groups: Dictionary[String, Array] = {PINNED_GROUP: []}
	for slot in _session.slots:
		if ("*" + slot.id) in visible_ids:
			groups[PINNED_GROUP].append(slot)
		elif slot.id in visible_ids:
			var category := slot.id.get_base_dir()
			if not groups.has(category):
				groups[category] = []
			groups[category].append(slot)
	for category: String in groups:
		if groups[category].is_empty():
			continue
		_list.add_child(_group_header(category, groups[category].size()))
		if _collapsed.get(category, false):
			continue
		for slot: Slot in groups[category]:
			var item := _item(slot)
			items[slot.id] = item
			_list.add_child(item)
	if visible_ids.is_empty():
		var empty := Kit.label("没有符合条件的插槽", &"HintText")
		empty.custom_minimum_size.y = Kit.CONTROL
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)


func _group_header(category: String, count: int) -> Button:
	var title := "钉选" if category == PINNED_GROUP else _session.category_title(category)
	var header := Kit.text_button(title,
		"chevron-right" if _collapsed.get(category, false) else "chevron-down",
		"展开或折叠“%s”" % title, &"GroupHeader")
	header.custom_minimum_size.y = GROUP_HEIGHT
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.pressed.connect(func() -> void:
		_collapsed[category] = not _collapsed.get(category, false)
		refresh(true))
	var total := Kit.label(str(count), &"HintText")
	total.add_theme_font_size_override("font_size", 11)
	header.add_child(total)
	total.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	total.offset_left = -24.0
	total.offset_right = -4.0
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return header


func _item(slot: Slot) -> Button:
	var item := Button.new()
	item.name = slot.id.validate_node_name()
	item.text = slot.display_name()
	item.tooltip_text = slot.id
	item.theme_type_variation = &"ListRow"
	item.toggle_mode = true
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.custom_minimum_size.y = ITEM_HEIGHT
	item.focus_mode = Control.FOCUS_NONE
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.clip_text = true
	item.pressed.connect(func() -> void:
		item.set_pressed_no_signal(true)
		slot_chosen.emit(slot))
	var marks := Kit.row(6)
	marks.name = "Marks"
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.alignment = BoxContainer.ALIGNMENT_END
	item.add_child(marks)
	marks.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	marks.offset_left = -48.0
	marks.offset_right = -8.0
	var pin := Kit.glyph("pinned", 13.0, Kit.color(&"tx3"))
	pin.name = "Pin"
	marks.add_child(pin)
	var mark := Kit.dot()
	mark.name = "Dot"
	mark.tooltip_text = "有未保存的改动"
	marks.add_child(mark)
	var bar := ColorRect.new()
	bar.name = "Bar"
	bar.color = Kit.color(&"accent")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	bar.offset_right = 2.0
	bar.offset_top = BAR_INSET
	bar.offset_bottom = -BAR_INSET
	return item


func _update_item(item: Button, slot: Slot, dirty: bool) -> void:
	var selected := slot == _session.selected
	item.set_pressed_no_signal(selected)
	item.get_node("Bar").visible = selected
	item.get_node("Marks/Pin").visible = slot.pinned
	item.get_node("Marks/Dot").visible = dirty
