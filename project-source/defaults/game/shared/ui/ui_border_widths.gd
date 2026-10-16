class_name UiBorderWidths
extends Resource
## Primitive border width scale. Border colors are color tokens.

enum Step { NONE, THIN, THICK }

## Field of each Step, in enum order.
const FIELDS: Array[StringName] = [&"none", &"thin", &"thick"]

@export_range(0, 16, 1, "suffix:px") var none := 0:
	set(value):
		none = value
		emit_changed()
@export_range(0, 16, 1, "suffix:px") var thin := 1:
	set(value):
		thin = value
		emit_changed()
@export_range(0, 16, 1, "suffix:px") var thick := 2:
	set(value):
		thick = value
		emit_changed()


func size(step: Step) -> int:
	return get(FIELDS[step])
