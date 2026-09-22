extends Control

## Backend-neutral numeric series. Wheel zooms X around pointer; right click resets.

var first: Dictionary = {}
var second: Dictionary = {}
var comparison_notice: String = ""
var _zoom: float = 1.0
var _center: float = 0.5
var _bounds: Rect2 = Rect2(0, 0, 1, 1)


func display(a: Dictionary, b: Dictionary, incompatibility: String = "") -> void:
	first = a
	second = b
	comparison_notice = incompatibility
	if not a.is_empty() and not b.is_empty():
		if a.x_unit != b.x_unit or a.y_unit != b.y_unit or a.kind != b.kind:
			comparison_notice = "A/B series units or kinds differ."
	if not comparison_notice.is_empty() and not b.is_empty():
		second = {}
		comparison_notice += " B overlay hidden."
	_zoom = 1.0
	_center = 0.5
	_bounds = _data_bounds()
	queue_redraw()


func _data_bounds() -> Rect2:
	var xs: Array = []
	var ys: Array = []
	for data: Dictionary in [first, second]:
		xs.append_array(data.get("x", []))
		ys.append_array(data.get("y", []))
	if xs.is_empty():
		return Rect2(0, 0, 1, 1)
	var low_y: float = minf(0.0, float(ys.min()))
	return Rect2(float(xs.min()), low_y, maxf(float(xs.max()) - float(xs.min()), 0.001),
		maxf(float(ys.max()) - low_y, 0.001))


func _draw() -> void:
	var area := Rect2(65, 25, maxf(size.x - 80, 1), maxf(size.y - 65, 1))
	var ink := get_theme_color("font_color", "Label")
	draw_rect(area, ink, false)
	var font := get_theme_default_font()
	var data: Dictionary = first if not first.is_empty() else second
	if data.is_empty():
		draw_string(font, Vector2(75, 60), "无可用图表数据（未分析或不支持）", HORIZONTAL_ALIGNMENT_LEFT,
			maxf(size.x - 80, 1), 14, ink)
		return
	var view := _view_bounds()
	var heading := "分析 A（蓝）/ B（橙）· " + str(data.y_unit)
	if not comparison_notice.is_empty():
		heading = "B 叠加已隐藏；请查看上方比较说明 · " + str(data.y_unit)
	draw_string(font, Vector2(65, 18), heading,
		HORIZONTAL_ALIGNMENT_LEFT, maxf(size.x - 80, 1), 14, ink)
	draw_string(font, Vector2(0, 38), "%.3f" % _bounds.end.y,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(0, area.end.y), "%.3f" % view.position.y,
		HORIZONTAL_ALIGNMENT_LEFT, 62, 13, ink)
	draw_string(font, Vector2(65, size.y - 12), "横轴 %.3f … %.3f %s" % [
		view.position.x, view.end.x, data.x_unit],
		HORIZONTAL_ALIGNMENT_LEFT, maxf(size.x - 80, 1), 13, ink)
	_plot(first, area, view, Color(0.15, 0.45, 0.9))
	_plot(second, area, view, Color(0.85, 0.38, 0.08))


func _plot(data: Dictionary, area: Rect2, view: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in data.get("x", []).size():
		var x: float = float(data.x[index])
		if x < view.position.x or x > view.end.x:
			continue
		var px := area.position.x + (x - view.position.x) / view.size.x * area.size.x
		var py := area.end.y - (float(data.y[index]) - view.position.y) / view.size.y * area.size.y
		points.append(Vector2(px, py))
	if data.get("kind") == "histogram":
		_plot_histogram(data, area, view, color)
		return
	if points.size() > 1:
		draw_polyline(points, color, 2.0, true)
	elif points.size() == 1:
		draw_circle(points[0], 3.0, color)


func _plot_histogram(data: Dictionary, area: Rect2, view: Rect2, color: Color) -> void:
	var step: float = absf(float(data.x[1]) - float(data.x[0])) if data.x.size() > 1 else view.size.x
	var width := step / view.size.x * area.size.x
	for index: int in data.x.size():
		var px := area.position.x + (float(data.x[index]) - view.position.x) / view.size.x * area.size.x
		var height := float(data.y[index]) / view.size.y * area.size.y
		var bar := Rect2(px - width * 0.5, area.end.y - height, width, height).intersection(area)
		if bar.has_area():
			draw_rect(bar, Color(color, 0.3))
			draw_rect(bar, color, false, 1.0)


func _view_bounds() -> Rect2:
	var width := _bounds.size.x / _zoom
	var start := _bounds.position.x + (_center - 0.5 / _zoom) * _bounds.size.x
	start = clampf(start, _bounds.position.x, _bounds.end.x - width)
	return Rect2(start, _bounds.position.y, width, _bounds.size.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var fraction := clampf((event.position.x - 65.0) / maxf(size.x - 80, 1), 0, 1)
		var view := _view_bounds()
		tooltip_text = comparison_notice + "\nx = %.5f" % (view.position.x + fraction * view.size.x)
	if not event is InputEventMouseButton or not event.pressed:
		return
	var button := event as InputEventMouseButton
	if button.button_index == MOUSE_BUTTON_RIGHT:
		_zoom = 1.0
		_center = 0.5
	elif button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var view := _view_bounds()
		var fraction := clampf((button.position.x - 65.0) / maxf(size.x - 80, 1), 0, 1)
		var pointer_x := view.position.x + fraction * view.size.x
		_zoom = clampf(_zoom * (1.5 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 0.667), 1, 32)
		_center = (pointer_x - _bounds.position.x
			+ (0.5 - fraction) * _bounds.size.x / _zoom) / _bounds.size.x
	queue_redraw()
	accept_event()
