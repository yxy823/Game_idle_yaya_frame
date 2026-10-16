class_name UiFontSizes
extends Resource
## Primitive font size scale. Semantic tokens pick a step.

enum Step { XS, SM, MD, LG, XL, XXL }

## Field of each Step, in enum order.
const FIELDS: Array[StringName] = [&"xs", &"sm", &"md", &"lg", &"xl", &"xxl"]

@export_range(6, 128, 1, "suffix:px") var xs := 14:
	set(value):
		xs = value
		emit_changed()
@export_range(6, 128, 1, "suffix:px") var sm := 16:
	set(value):
		sm = value
		emit_changed()
@export_range(6, 128, 1, "suffix:px") var md := 20:
	set(value):
		md = value
		emit_changed()
@export_range(6, 128, 1, "suffix:px") var lg := 24:
	set(value):
		lg = value
		emit_changed()
@export_range(6, 128, 1, "suffix:px") var xl := 32:
	set(value):
		xl = value
		emit_changed()
@export_range(6, 128, 1, "suffix:px") var xxl := 40:
	set(value):
		xxl = value
		emit_changed()


func size(step: Step) -> int:
	return get(FIELDS[step])
