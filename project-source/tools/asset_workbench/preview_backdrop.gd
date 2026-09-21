extends Control

## Optional transparency inspection grid behind assets, never across the UI.

const CELL_SIZE: float = 16.0
var checker_enabled: bool = false:
	set(value):
		checker_enabled = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if not checker_enabled:
		return
	for row: int in ceili(size.y / CELL_SIZE):
		for column: int in ceili(size.x / CELL_SIZE):
			var level := 0.55 if (row + column) % 2 == 0 else 0.7
			var start := Vector2(column, row) * CELL_SIZE
			draw_rect(Rect2(start, Vector2.ONE * CELL_SIZE), Color(level, level, level))
