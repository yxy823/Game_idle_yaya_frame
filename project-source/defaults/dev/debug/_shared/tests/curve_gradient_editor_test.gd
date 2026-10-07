extends GdUnitTestSuite

const CurveEditor := preload("res://dev/debug/_shared/editors/curve_editor.gd")
const GradientEditor := preload("res://dev/debug/_shared/editors/gradient_editor.gd")

var _changes: int


func before_test() -> void:
	_changes = 0


func _count(_value: Variant) -> void:
	_changes += 1


func _curve_editor(curve: Curve) -> CurveEditor:
	var editor: CurveEditor = auto_free(CurveEditor.new())
	add_child(editor)
	editor.size = Vector2(300, 260)
	editor._graph.size = Vector2(300, CurveEditor.GRAPH_HEIGHT)
	editor.bind(curve, _count)
	return editor


func _gradient_editor(gradient: Gradient) -> GradientEditor:
	var editor: GradientEditor = auto_free(GradientEditor.new())
	add_child(editor)
	editor.size = Vector2(300, 120)
	editor._bar.size = Vector2(300, GradientEditor.BAR_HEIGHT + GradientEditor.STOP_HEIGHT + 4.0)
	editor.bind(gradient, _count)
	return editor


func _click(position: Vector2, button := MOUSE_BUTTON_LEFT, pressed := true, double := false) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = button
	event.pressed = pressed
	event.double_click = double
	return event


func _move(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	return event


func _linear_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(1, 1))
	return curve


func test_curve_double_click_adds_point_and_right_click_removes_it() -> void:
	var curve := _linear_curve()
	var editor := _curve_editor(curve)
	var target := editor._to_screen(Vector2(0.5, 0.2))
	editor._on_graph_input(_click(target, MOUSE_BUTTON_LEFT, true, true))
	assert_int(curve.point_count).is_equal(3)
	assert_float(curve.get_point_position(1).y).is_equal_approx(0.2, 0.02)
	editor._on_graph_input(_click(target, MOUSE_BUTTON_RIGHT))
	assert_int(curve.point_count).is_equal(2)
	assert_int(_changes).is_equal(2)


func test_curve_dragging_a_point_moves_it_and_undo_restores() -> void:
	var curve := _linear_curve()
	var editor := _curve_editor(curve)
	var start := editor._to_screen(Vector2(1, 1))
	editor._on_graph_input(_click(start))
	editor._on_graph_input(_move(editor._to_screen(Vector2(1, 0.4))))
	editor._on_graph_input(_click(start, MOUSE_BUTTON_LEFT, false))
	assert_float(curve.get_point_position(1).y).is_equal_approx(0.4, 0.02)
	editor.undo()
	assert_float(curve.get_point_position(1).y).is_equal_approx(1.0, 0.001)


func test_curve_handle_drag_sets_free_tangent() -> void:
	var curve := _linear_curve()
	var editor := _curve_editor(curve)
	var point := editor._to_screen(Vector2(0, 0))
	editor._on_graph_input(_click(point))
	editor._on_graph_input(_click(point, MOUSE_BUTTON_LEFT, false))
	var handle := editor._handle_position(0, false)
	editor._on_graph_input(_click(handle))
	editor._on_graph_input(_move(point + Vector2(30, -30)))
	editor._on_graph_input(_click(handle, MOUSE_BUTTON_LEFT, false))
	assert_int(curve.get_point_right_mode(0)).is_equal(Curve.TANGENT_FREE)
	assert_float(curve.get_point_right_tangent(0) * editor._slope_scale()).is_equal_approx(1.0, 0.01)


func test_curve_preset_replaces_points() -> void:
	var curve := _linear_curve()
	var editor := _curve_editor(curve)
	editor._on_preset_selected(CurveEditor.PRESETS.find("缓入缓出") + 1)
	assert_int(curve.point_count).is_equal(2)
	assert_float(curve.get_point_right_tangent(0)).is_equal(0.0)
	assert_float(curve.get_point_left_tangent(1)).is_equal(0.0)
	assert_float(curve.sample(0.5)).is_equal_approx(0.5, 0.01)


func test_curve_lock_ignores_input() -> void:
	var curve := _linear_curve()
	var editor := _curve_editor(curve)
	editor.set_locked(true)
	editor._on_graph_input(_click(editor._to_screen(Vector2(0.5, 0.5)), MOUSE_BUTTON_LEFT, true, true))
	assert_int(curve.point_count).is_equal(2)
	assert_int(_changes).is_equal(0)


func test_gradient_add_drag_remove_and_undo() -> void:
	var gradient := Gradient.new()
	var editor := _gradient_editor(gradient)
	var rect := editor._bar_rect()
	var middle := Vector2(rect.position.x + rect.size.x * 0.5, rect.size.y * 0.5)
	editor._on_bar_input(_click(middle, MOUSE_BUTTON_LEFT, true, true))
	assert_int(gradient.get_point_count()).is_equal(3)
	var added := editor._selected
	assert_float(gradient.get_offset(added)).is_equal_approx(0.5, 0.01)

	var stop := Vector2(editor._stop_x(added), GradientEditor.BAR_HEIGHT + 6.0)
	editor._on_bar_input(_click(stop))
	editor._on_bar_input(_move(Vector2(rect.position.x + rect.size.x * 0.8, stop.y)))
	editor._on_bar_input(_click(stop, MOUSE_BUTTON_LEFT, false))
	assert_float(gradient.get_offset(editor._selected)).is_equal_approx(0.8, 0.01)

	editor.undo()
	assert_float(gradient.get_offset(editor._index_of(0.5))).is_equal_approx(0.5, 0.01)
	var restored := Vector2(editor._stop_x(editor._index_of(0.5)), stop.y)
	editor._on_bar_input(_click(restored, MOUSE_BUTTON_RIGHT))
	assert_int(gradient.get_point_count()).is_equal(2)


func test_gradient_modes_change_resource() -> void:
	var gradient := Gradient.new()
	var editor := _gradient_editor(gradient)
	editor._on_interpolation_selected(editor._interpolation.get_item_index(Gradient.GRADIENT_INTERPOLATE_CONSTANT))
	editor._on_color_space_selected(editor._color_space.get_item_index(Gradient.GRADIENT_COLOR_SPACE_OKLAB))
	assert_int(gradient.interpolation_mode).is_equal(Gradient.GRADIENT_INTERPOLATE_CONSTANT)
	assert_int(gradient.interpolation_color_space).is_equal(Gradient.GRADIENT_COLOR_SPACE_OKLAB)
	assert_int(_changes).is_equal(2)
