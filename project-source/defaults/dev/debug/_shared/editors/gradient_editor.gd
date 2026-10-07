extends VBoxContainer
## Edits a Gradient in place: drag color stops, add with a double click on the bar,
## remove with a right click, pick colors, change interpolation and color space, undo.
## Compact by default (bar and stops); set_expanded(true) shows the stop and mode rows.

const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const BAR_HEIGHT := 20.0
const STOP_HEIGHT := 8.0
const STOP_HALF_WIDTH := 5.0
const STOP_GAP := 1.0
const SIDE_PADDING := 5.0
const CHECKER_CELL := 6.0
const UNDO_LIMIT := 50

var expanded: bool = false
var _gradient: Gradient
var _changed: Callable
var _locked: bool = false
var _selected: int = -1
var _dragging: bool = false
## True while the color picker is open, so one pick is one undo step.
var _color_editing: bool = false
var _undo: Array = []

var _bar: Control
var _tools: VBoxContainer
var _color: ColorPickerButton
var _offset: SpinBox
var _interpolation: OptionButton
var _color_space: OptionButton
var _undo_button: Button


func _init() -> void:
	add_theme_constant_override("separation", 8)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT + STOP_GAP + STOP_HEIGHT)
	_bar.draw.connect(_draw_bar)
	_bar.gui_input.connect(_on_bar_input)
	add_child(_bar)
	_tools = Kit.column(8)
	_tools.visible = false
	add_child(_tools)
	_build_stop_row()
	_build_mode_row()
	var hint := Kit.label("双击色条加色标 · 右键删色标 · 拖动三角改位置", &"HintText")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tools.add_child(hint)


func _build_stop_row() -> void:
	var stop_row := Kit.row(8)
	_color = ColorPickerButton.new()
	_color.custom_minimum_size = Vector2(56, 24)
	_color.color_changed.connect(_on_color_changed)
	_color.popup_closed.connect(_on_color_committed)
	_offset = SpinBox.new()
	_offset.min_value = 0.0
	_offset.max_value = 1.0
	_offset.step = 0.01
	_offset.custom_minimum_size = Vector2(72, 24)
	_offset.get_line_edit().theme_type_variation = &"ValueEdit"
	_offset.value_changed.connect(_on_offset_changed)
	stop_row.add_child(_caption("色标颜色"))
	stop_row.add_child(_color)
	stop_row.add_child(_caption("位置"))
	stop_row.add_child(_offset)
	_tools.add_child(stop_row)


func _build_mode_row() -> void:
	var mode_row := Kit.row(8)
	_interpolation = _option({"线性": Gradient.GRADIENT_INTERPOLATE_LINEAR,
		"常量": Gradient.GRADIENT_INTERPOLATE_CONSTANT, "三次": Gradient.GRADIENT_INTERPOLATE_CUBIC})
	_interpolation.item_selected.connect(_on_interpolation_selected)
	_color_space = _option({"sRGB": Gradient.GRADIENT_COLOR_SPACE_SRGB,
		"线性 sRGB": Gradient.GRADIENT_COLOR_SPACE_LINEAR_SRGB,
		"Oklab": Gradient.GRADIENT_COLOR_SPACE_OKLAB})
	_color_space.item_selected.connect(_on_color_space_selected)
	_undo_button = Kit.icon_button("arrow-back-up", "撤销上一次渐变编辑")
	_undo_button.pressed.connect(undo)
	mode_row.add_child(_caption("插值"))
	mode_row.add_child(_interpolation)
	mode_row.add_child(_caption("颜色空间"))
	mode_row.add_child(_color_space)
	mode_row.add_child(_undo_button)
	_tools.add_child(mode_row)


func _option(items: Dictionary) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size.y = Kit.CONTROL
	for caption: String in items:
		option.add_item(caption, items[caption])
	return option


## The full editor adds stop color and position, interpolation, color space and undo.
func set_expanded(value: bool) -> void:
	expanded = value
	_tools.visible = value


## Edits `value` directly; `changed` runs after every completed edit.
func bind(value: Variant, changed: Callable) -> void:
	_changed = changed
	set_value(value)


func set_value(value: Variant) -> void:
	_gradient = value as Gradient
	_selected = 0 if _gradient != null and _gradient.get_point_count() > 0 else -1
	_dragging = false
	_undo.clear()
	_refresh_controls()


func set_locked(locked: bool) -> void:
	_locked = locked
	_dragging = false
	modulate.a = 0.5 if locked else 1.0
	_refresh_controls()


func undo() -> void:
	if _undo.is_empty() or _gradient == null or _locked:
		return
	var snapshot: Dictionary = _undo.pop_back()
	_gradient.offsets = snapshot.offsets
	_gradient.colors = snapshot.colors
	_gradient.interpolation_mode = snapshot.mode
	_gradient.interpolation_color_space = snapshot.space
	_selected = mini(_selected, _gradient.get_point_count() - 1)
	_finish_edit()


func _caption(text: String) -> Label:
	return Kit.label(text, &"FieldLabel")


func _refresh_controls() -> void:
	var editable := _gradient != null and not _locked
	var has_stop := editable and _selected >= 0
	_color.disabled = not has_stop
	_offset.editable = has_stop
	_interpolation.disabled = not editable
	_color_space.disabled = not editable
	_undo_button.disabled = not editable or _undo.is_empty()
	if _gradient != null:
		_interpolation.select(_interpolation.get_item_index(_gradient.interpolation_mode))
		_color_space.select(_color_space.get_item_index(_gradient.interpolation_color_space))
	if has_stop:
		_color.color = _gradient.get_color(_selected)
		_offset.set_value_no_signal(_gradient.get_offset(_selected))
	_bar.queue_redraw()


# --- Coordinates and drawing -------------------------------------------------

func _bar_rect() -> Rect2:
	return Rect2(SIDE_PADDING, 0.0, _bar.size.x - SIDE_PADDING * 2.0, BAR_HEIGHT)


func _offset_at(x: float) -> float:
	var rect := _bar_rect()
	return clampf((x - rect.position.x) / rect.size.x, 0.0, 1.0)


func _stop_x(index: int) -> float:
	var rect := _bar_rect()
	return rect.position.x + _gradient.get_offset(index) * rect.size.x


func _draw_bar() -> void:
	var rect := _bar_rect()
	_draw_checker(rect)
	if _gradient == null:
		return
	var steps := maxi(int(rect.size.x / 2.0), 1)
	var width := rect.size.x / steps
	for step in range(steps):
		var color := _gradient.sample((step + 0.5) / steps)
		_bar.draw_rect(Rect2(rect.position.x + step * width, rect.position.y, width + 0.5,
			rect.size.y), color)
	_bar.draw_rect(rect.grow(-0.5), Kit.color(&"line2"), false, 1.0)
	for index in range(_gradient.get_point_count()):
		var tip := Vector2(_stop_x(index), BAR_HEIGHT + STOP_GAP)
		var triangle := PackedVector2Array([tip,
			tip + Vector2(STOP_HALF_WIDTH, STOP_HEIGHT), tip + Vector2(-STOP_HALF_WIDTH, STOP_HEIGHT)])
		var fill := Kit.color(&"accent") if index == _selected and expanded else Kit.color(&"tx1")
		_bar.draw_colored_polygon(triangle, fill)


func _draw_checker(rect: Rect2) -> void:
	for column in range(ceili(rect.size.x / CHECKER_CELL)):
		for row in range(ceili(rect.size.y / CHECKER_CELL)):
			var shade := Kit.color(&"bg3") if (column + row) % 2 == 0 else Kit.color(&"bg1")
			var square := Rect2(rect.position + Vector2(column, row) * CHECKER_CELL,
				Vector2.ONE * CHECKER_CELL).intersection(rect)
			_bar.draw_rect(square, shade)


# --- Input -------------------------------------------------------------------

func _on_bar_input(event: InputEvent) -> void:
	if _gradient == null or _locked:
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		_on_press(button)
	elif button != null and button.button_index == MOUSE_BUTTON_LEFT and _dragging:
		_dragging = false
		_finish_edit()
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		_move_selected(_offset_at(motion.position.x))


func _on_press(button: InputEventMouseButton) -> void:
	var hit := _stop_at(button.position)
	if button.button_index == MOUSE_BUTTON_RIGHT:
		_remove_stop(hit)
	elif button.button_index == MOUSE_BUTTON_LEFT and button.double_click and hit < 0:
		var offset := _offset_at(button.position.x)
		_push_undo()
		_gradient.add_point(offset, _gradient.sample(offset))
		_selected = _index_of(offset)
		_finish_edit()
	elif button.button_index == MOUSE_BUTTON_LEFT:
		if hit >= 0:
			_selected = hit
			_push_undo()
			_dragging = true
		_refresh_controls()


func _remove_stop(hit: int) -> void:
	if hit >= 0 and _gradient.get_point_count() > 1:
		_push_undo()
		_gradient.remove_point(hit)
		_selected = mini(_selected, _gradient.get_point_count() - 1)
		_finish_edit()


func _stop_at(pointer_position: Vector2) -> int:
	var best := -1
	var best_distance := STOP_HALF_WIDTH + 2.0
	for index in range(_gradient.get_point_count()):
		var distance := absf(pointer_position.x - _stop_x(index))
		if distance <= best_distance:
			best = index
			best_distance = distance
	return best


## Gradient keeps stops sorted, so a moved stop may change index.
func _move_selected(offset: float) -> void:
	var color := _gradient.get_color(_selected)
	_gradient.set_offset(_selected, offset)
	_selected = _index_of(offset, color)
	_offset.set_value_no_signal(offset)
	_bar.queue_redraw()


func _index_of(offset: float, color: Variant = null) -> int:
	for index in range(_gradient.get_point_count()):
		if is_equal_approx(_gradient.get_offset(index), offset) and (color == null or _gradient.get_color(index) == color):
			return index
	return -1


# --- Controls ----------------------------------------------------------------

func _on_color_changed(color: Color) -> void:
	if _selected < 0:
		return
	if not _color_editing:
		_push_undo()
		_color_editing = true
	_gradient.set_color(_selected, color)
	_bar.queue_redraw()


func _on_color_committed() -> void:
	if _color_editing:
		_color_editing = false
		_finish_edit()


func _on_offset_changed(value: float) -> void:
	if _selected < 0:
		return
	_push_undo()
	_move_selected(value)
	_finish_edit()


func _on_interpolation_selected(item: int) -> void:
	_push_undo()
	_gradient.interpolation_mode = _interpolation.get_item_id(item) as Gradient.InterpolationMode
	_finish_edit()


func _on_color_space_selected(item: int) -> void:
	_push_undo()
	_gradient.interpolation_color_space = _color_space.get_item_id(item) as Gradient.ColorSpace
	_finish_edit()


# --- Undo --------------------------------------------------------------------

func _push_undo() -> void:
	_undo.append({
		"offsets": _gradient.offsets.duplicate(),
		"colors": _gradient.colors.duplicate(),
		"mode": _gradient.interpolation_mode,
		"space": _gradient.interpolation_color_space,
	})
	if _undo.size() > UNDO_LIMIT:
		_undo.pop_front()


func _finish_edit() -> void:
	_refresh_controls()
	if _changed.is_valid():
		_changed.call(_gradient)
