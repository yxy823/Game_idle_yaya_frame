extends VBoxContainer
## Edits a Curve in place: drag points and tangent handles, add with a double click,
## remove with a right click, change ranges and tangent modes, apply preset shapes, undo.
## Compact by default (graph only); set_expanded(true) shows the full tool rows.

const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const GRAPH_HEIGHT := 168.0
const COMPACT_HEIGHT := 72.0
const GRAPH_PADDING := 10.0
const POINT_RADIUS := 5.0
const COMPACT_POINT_RADIUS := 3.0
const HANDLE_LENGTH := 36.0
const HIT_RADIUS := 9.0
const UNDO_LIMIT := 50
const SAMPLES := 96
const PRESETS: Array[String] = ["线性", "缓入", "缓出", "缓入缓出"]

enum Drag { NONE, POINT, LEFT_HANDLE, RIGHT_HANDLE }

var expanded: bool = false
var _curve: Curve
var _changed: Callable
var _locked: bool = false
var _selected: int = -1
var _drag: Drag = Drag.NONE
var _undo: Array = []

var _graph: Control
var _tools: VBoxContainer
var _left_mode: OptionButton
var _right_mode: OptionButton
var _min_value: SpinBox
var _max_value: SpinBox
var _undo_button: Button
var _preset: OptionButton


func _init() -> void:
	add_theme_constant_override("separation", 8)
	_graph = Control.new()
	_graph.custom_minimum_size = Vector2(0, COMPACT_HEIGHT)
	_graph.mouse_default_cursor_shape = Control.CURSOR_CROSS
	_graph.draw.connect(_draw_graph)
	_graph.gui_input.connect(_on_graph_input)
	add_child(_graph)
	_tools = Kit.column(8)
	_tools.visible = false
	add_child(_tools)
	_build_tangent_row()
	_build_range_row()
	_build_action_row()
	var hint := Kit.label("双击空白处加点 · 右键删点 · 选中点后拖动两侧手柄调切线", &"HintText")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tools.add_child(hint)


func _build_tangent_row() -> void:
	var tangents := Kit.row(8)
	_left_mode = _mode_option()
	_right_mode = _mode_option()
	_left_mode.item_selected.connect(_on_mode_selected.bind(true))
	_right_mode.item_selected.connect(_on_mode_selected.bind(false))
	tangents.add_child(_caption("左切线"))
	tangents.add_child(_left_mode)
	tangents.add_child(_caption("右切线"))
	tangents.add_child(_right_mode)
	_tools.add_child(tangents)


func _build_range_row() -> void:
	var ranges := Kit.row(8)
	_min_value = _range_box()
	_max_value = _range_box()
	_min_value.value_changed.connect(_on_range_changed)
	_max_value.value_changed.connect(_on_range_changed)
	ranges.add_child(_caption("最小值"))
	ranges.add_child(_min_value)
	ranges.add_child(_caption("最大值"))
	ranges.add_child(_max_value)
	_tools.add_child(ranges)


func _build_action_row() -> void:
	var actions := Kit.row(8)
	_preset = OptionButton.new()
	_preset.custom_minimum_size.y = Kit.CONTROL
	_preset.add_item("预设形状…")
	for preset_name in PRESETS:
		_preset.add_item(preset_name)
	_preset.item_selected.connect(_on_preset_selected)
	_undo_button = Kit.icon_button("arrow-back-up", "撤销上一次曲线编辑")
	_undo_button.pressed.connect(undo)
	actions.add_child(_preset)
	actions.add_child(_undo_button)
	_tools.add_child(actions)


## The full editor adds a taller graph, tangent modes, value range, shapes and undo.
func set_expanded(value: bool) -> void:
	expanded = value
	_tools.visible = value
	_graph.custom_minimum_size.y = GRAPH_HEIGHT if value else COMPACT_HEIGHT
	_graph.queue_redraw()


## Edits `value` directly; `changed` runs after every completed edit.
func bind(value: Variant, changed: Callable) -> void:
	_changed = changed
	set_value(value)


func set_value(value: Variant) -> void:
	_curve = value as Curve
	_selected = -1
	_drag = Drag.NONE
	_undo.clear()
	_refresh_controls()


func set_locked(locked: bool) -> void:
	_locked = locked
	_drag = Drag.NONE
	modulate.a = 0.5 if locked else 1.0
	_refresh_controls()


func undo() -> void:
	if _undo.is_empty() or _curve == null or _locked:
		return
	_restore(_undo.pop_back())
	_selected = mini(_selected, _curve.point_count - 1)
	_finish_edit()


func _caption(text: String) -> Label:
	return Kit.label(text, &"FieldLabel")


func _mode_option() -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size.y = Kit.CONTROL
	option.add_item("自由", Curve.TANGENT_FREE)
	option.add_item("线性", Curve.TANGENT_LINEAR)
	return option


func _range_box() -> SpinBox:
	var box := SpinBox.new()
	box.allow_greater = true
	box.allow_lesser = true
	box.step = 0.01
	box.custom_minimum_size = Vector2(72, 24)
	box.get_line_edit().theme_type_variation = &"ValueEdit"
	return box


func _refresh_controls() -> void:
	var editable := _curve != null and not _locked
	var has_point := editable and _selected >= 0
	_left_mode.disabled = not has_point
	_right_mode.disabled = not has_point
	if has_point:
		_left_mode.select(_left_mode.get_item_index(_curve.get_point_left_mode(_selected)))
		_right_mode.select(_right_mode.get_item_index(_curve.get_point_right_mode(_selected)))
	_min_value.editable = editable
	_max_value.editable = editable
	if _curve != null:
		_min_value.set_value_no_signal(_curve.min_value)
		_max_value.set_value_no_signal(_curve.max_value)
	_preset.disabled = not editable
	_undo_button.disabled = not editable or _undo.is_empty()
	_graph.queue_redraw()


# --- Coordinates -------------------------------------------------------------

func _plot_rect() -> Rect2:
	return Rect2(Vector2.ONE * GRAPH_PADDING, _graph.size - Vector2.ONE * GRAPH_PADDING * 2.0)


func _to_screen(point: Vector2) -> Vector2:
	var rect := _plot_rect()
	var x := inverse_lerp(_curve.min_domain, _curve.max_domain, point.x)
	var y := inverse_lerp(_curve.min_value, _curve.max_value, point.y)
	return rect.position + Vector2(x * rect.size.x, (1.0 - y) * rect.size.y)


func _to_curve(screen: Vector2) -> Vector2:
	var rect := _plot_rect()
	var x := clampf((screen.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	var y := clampf(1.0 - (screen.y - rect.position.y) / rect.size.y, 0.0, 1.0)
	return Vector2(lerpf(_curve.min_domain, _curve.max_domain, x),
		lerpf(_curve.min_value, _curve.max_value, y))


## Screen-space slope scale: tangents are stored in curve units.
func _slope_scale() -> float:
	var rect := _plot_rect()
	return (rect.size.y / _curve.get_value_range()) / (rect.size.x / _curve.get_domain_range())


func _handle_position(index: int, left: bool) -> Vector2:
	var tangent := _curve.get_point_left_tangent(index) if left else _curve.get_point_right_tangent(index)
	var direction := Vector2(-1.0 if left else 1.0, 0.0)
	direction.y = -direction.x * tangent * _slope_scale()
	return _to_screen(_curve.get_point_position(index)) + direction.normalized() * HANDLE_LENGTH


# --- Drawing -----------------------------------------------------------------

func _draw_graph() -> void:
	var frame := Rect2(Vector2.ZERO, _graph.size)
	var rect := _plot_rect()
	_graph.draw_rect(frame, Kit.color(&"bg1"))
	for step in range(1, 4):
		var x := rect.position.x + rect.size.x * step / 4.0
		_graph.draw_line(Vector2(x, 0.0), Vector2(x, frame.end.y), Kit.color(&"line"))
	var middle := rect.position.y + rect.size.y * 0.5
	_graph.draw_line(Vector2(0.0, middle), Vector2(frame.end.x, middle), Kit.color(&"line"))
	_graph.draw_rect(frame.grow(-0.5), Kit.color(&"line2"), false, 1.0)
	if _curve == null:
		return
	var line := PackedVector2Array()
	for sample_index in range(SAMPLES + 1):
		var offset := lerpf(_curve.min_domain, _curve.max_domain, float(sample_index) / SAMPLES)
		line.append(_to_screen(Vector2(offset, _curve.sample(offset))))
	_graph.draw_polyline(line, Kit.color(&"knob"), 1.5, true)
	var radius := POINT_RADIUS if expanded else COMPACT_POINT_RADIUS
	for index in range(_curve.point_count):
		var center := _to_screen(_curve.get_point_position(index))
		if index == _selected:
			for left: bool in [true, false]:
				var handle := _handle_position(index, left)
				_graph.draw_line(center, handle, Kit.color(&"tx3"), 1.0, true)
				_graph.draw_circle(handle, radius - 1.0, Kit.color(&"tx2"))
		var fill := Kit.color(&"accent") if index == _selected else Kit.color(&"tx2")
		_graph.draw_circle(center, radius, fill)


# --- Input -------------------------------------------------------------------

func _on_graph_input(event: InputEvent) -> void:
	if _curve == null or _locked:
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		_on_press(button)
	elif button != null and button.button_index == MOUSE_BUTTON_LEFT and _drag != Drag.NONE:
		_drag = Drag.NONE
		_finish_edit()
	elif event is InputEventMouseMotion and _drag != Drag.NONE:
		_on_drag((event as InputEventMouseMotion).position)


func _on_press(button: InputEventMouseButton) -> void:
	var hit := _point_at(button.position)
	if button.button_index == MOUSE_BUTTON_RIGHT:
		_remove_point(hit)
	elif button.button_index == MOUSE_BUTTON_LEFT and button.double_click and hit < 0:
		_push_undo()
		_selected = _curve.add_point(_to_curve(button.position))
		_finish_edit()
	elif button.button_index == MOUSE_BUTTON_LEFT and not _grab_handle(button.position):
		_selected = hit
		if hit >= 0:
			_push_undo()
			_drag = Drag.POINT
		_refresh_controls()


func _remove_point(hit: int) -> void:
	if hit >= 0 and _curve.point_count > 1:
		_push_undo()
		_curve.remove_point(hit)
		_selected = -1
		_finish_edit()


func _grab_handle(position_on_graph: Vector2) -> bool:
	if _selected < 0:
		return false
	for left: bool in [true, false]:
		if position_on_graph.distance_to(_handle_position(_selected, left)) <= HIT_RADIUS:
			_push_undo()
			_drag = Drag.LEFT_HANDLE if left else Drag.RIGHT_HANDLE
			return true
	return false


func _on_drag(screen: Vector2) -> void:
	if _drag == Drag.POINT:
		var target := _to_curve(screen)
		_curve.set_point_value(_selected, target.y)
		_selected = _curve.set_point_offset(_selected, target.x)
	else:
		var center := _to_screen(_curve.get_point_position(_selected))
		var delta := screen - center
		var left := _drag == Drag.LEFT_HANDLE
		# A handle must stay on its own side of the point.
		delta.x = minf(delta.x, -0.001) if left else maxf(delta.x, 0.001)
		var tangent := (-delta.y / delta.x) / _slope_scale()
		if left:
			_curve.set_point_left_mode(_selected, Curve.TANGENT_FREE)
			_curve.set_point_left_tangent(_selected, tangent)
		else:
			_curve.set_point_right_mode(_selected, Curve.TANGENT_FREE)
			_curve.set_point_right_tangent(_selected, tangent)
	_graph.queue_redraw()


func _point_at(screen: Vector2) -> int:
	for index in range(_curve.point_count):
		if screen.distance_to(_to_screen(_curve.get_point_position(index))) <= HIT_RADIUS:
			return index
	return -1


# --- Controls ----------------------------------------------------------------

func _on_mode_selected(item: int, left: bool) -> void:
	if _selected < 0:
		return
	_push_undo()
	var mode := (_left_mode if left else _right_mode).get_item_id(item)
	if left:
		_curve.set_point_left_mode(_selected, mode)
	else:
		_curve.set_point_right_mode(_selected, mode)
	_finish_edit()


func _on_range_changed(_value: float) -> void:
	if _max_value.value <= _min_value.value:
		_refresh_controls()
		return
	_push_undo()
	_curve.min_value = _min_value.value
	_curve.max_value = _max_value.value
	_finish_edit()


func _on_preset_selected(item: int) -> void:
	_preset.select(0)
	if item == 0:
		return
	_push_undo()
	var low := _curve.min_value
	var high := _curve.max_value
	_curve.clear_points()
	var start := Vector2(_curve.min_domain, low)
	var end := Vector2(_curve.max_domain, high)
	var slope := (high - low) / _curve.get_domain_range()
	match PRESETS[item - 1]:
		"线性":
			_curve.add_point(start, 0.0, slope, Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
			_curve.add_point(end, slope, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_FREE)
		"缓入":
			_curve.add_point(start, 0.0, 0.0)
			_curve.add_point(end, slope * 2.0, 0.0)
		"缓出":
			_curve.add_point(start, 0.0, slope * 2.0)
			_curve.add_point(end, 0.0, 0.0)
		"缓入缓出":
			_curve.add_point(start, 0.0, 0.0)
			_curve.add_point(end, 0.0, 0.0)
	_selected = -1
	_finish_edit()


# --- Undo --------------------------------------------------------------------

func _push_undo() -> void:
	_undo.append({
		"data": _curve.get("_data").duplicate(),
		"min": _curve.min_value,
		"max": _curve.max_value,
	})
	if _undo.size() > UNDO_LIMIT:
		_undo.pop_front()


func _restore(snapshot: Dictionary) -> void:
	_curve.min_value = snapshot.min
	_curve.max_value = snapshot.max
	_curve.set("_data", snapshot.data)


func _finish_edit() -> void:
	_refresh_controls()
	if _changed.is_valid():
		_changed.call(_curve)
