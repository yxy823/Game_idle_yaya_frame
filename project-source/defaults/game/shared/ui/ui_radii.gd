class_name UiRadii
extends Resource
## Primitive corner radius scale. Semantic tokens pick a step.

enum Step { NONE, SM, MD, LG }

## Field of each Step, in enum order.
const FIELDS: Array[StringName] = [&"none", &"sm", &"md", &"lg"]

@export_range(0, 64, 1, "suffix:px") var none := 0:
	set(value):
		none = value
		emit_changed()
@export_range(0, 64, 1, "suffix:px") var sm := 4:
	set(value):
		sm = value
		emit_changed()
@export_range(0, 64, 1, "suffix:px") var md := 8:
	set(value):
		md = value
		emit_changed()
@export_range(0, 64, 1, "suffix:px") var lg := 16:
	set(value):
		lg = value
		emit_changed()


func size(step: Step) -> int:
	return get(FIELDS[step])
