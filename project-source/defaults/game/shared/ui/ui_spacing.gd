class_name UiSpacing
extends Resource
## Primitive spacing scale for padding and gaps. Semantic tokens pick a step.

enum Step { NONE, XS, SM, MD, LG, XL }

## Field of each Step, in enum order.
const FIELDS: Array[StringName] = [&"none", &"xs", &"sm", &"md", &"lg", &"xl"]

@export_range(0, 128, 1, "suffix:px") var none := 0:
	set(value):
		none = value
		emit_changed()
@export_range(0, 128, 1, "suffix:px") var xs := 4:
	set(value):
		xs = value
		emit_changed()
@export_range(0, 128, 1, "suffix:px") var sm := 8:
	set(value):
		sm = value
		emit_changed()
@export_range(0, 128, 1, "suffix:px") var md := 12:
	set(value):
		md = value
		emit_changed()
@export_range(0, 128, 1, "suffix:px") var lg := 16:
	set(value):
		lg = value
		emit_changed()
@export_range(0, 128, 1, "suffix:px") var xl := 24:
	set(value):
		xl = value
		emit_changed()


func size(step: Step) -> int:
	return get(FIELDS[step])
