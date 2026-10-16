class_name UiShadows
extends Resource
## Primitive shadow levels: blur size and offset of each level. The shadow color is a color token.

enum Level { NONE, SM, MD, LG }

## Field prefix of each Level, in enum order; NONE has no fields.
const PREFIXES: Array[String] = ["", "sm_", "md_", "lg_"]

@export_group("Small", "sm_")
@export_range(0, 64, 1, "suffix:px") var sm_size := 2:
	set(value):
		sm_size = value
		emit_changed()
@export var sm_offset := Vector2(0, 1):
	set(value):
		sm_offset = value
		emit_changed()
@export_group("Medium", "md_")
@export_range(0, 64, 1, "suffix:px") var md_size := 6:
	set(value):
		md_size = value
		emit_changed()
@export var md_offset := Vector2(0, 2):
	set(value):
		md_offset = value
		emit_changed()
@export_group("Large", "lg_")
@export_range(0, 64, 1, "suffix:px") var lg_size := 12:
	set(value):
		lg_size = value
		emit_changed()
@export var lg_offset := Vector2(0, 4):
	set(value):
		lg_offset = value
		emit_changed()


## Writes the level's size, offset and color into the style box; NONE clears the shadow.
func apply(level: Level, color: Color, style: StyleBoxFlat) -> void:
	var prefix := PREFIXES[level]
	style.shadow_size = 0 if prefix.is_empty() else get(prefix + "size")
	style.shadow_offset = Vector2.ZERO if prefix.is_empty() else get(prefix + "offset")
	style.shadow_color = color
