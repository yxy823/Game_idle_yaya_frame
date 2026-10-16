class_name UiPalette
extends Resource
## Primitive color tokens: a gray ramp and one accent ramp. Semantic tokens pick one by Swatch.

enum Swatch {
	GRAY_50, GRAY_100, GRAY_200, GRAY_300, GRAY_400, GRAY_500, GRAY_600, GRAY_700, GRAY_800,
	GRAY_900, ACCENT_400, ACCENT_500, ACCENT_600, SHADOW,
}

## Field of each Swatch, in enum order.
const FIELDS: Array[StringName] = [
	&"gray_50", &"gray_100", &"gray_200", &"gray_300", &"gray_400", &"gray_500", &"gray_600",
	&"gray_700", &"gray_800", &"gray_900", &"accent_400", &"accent_500", &"accent_600", &"shadow",
]

@export var gray_50 := Color("f7f7f8"):
	set(value):
		gray_50 = value
		emit_changed()
@export var gray_100 := Color("ececef"):
	set(value):
		gray_100 = value
		emit_changed()
@export var gray_200 := Color("d9d9de"):
	set(value):
		gray_200 = value
		emit_changed()
@export var gray_300 := Color("bdbdc5"):
	set(value):
		gray_300 = value
		emit_changed()
@export var gray_400 := Color("9b9ba6"):
	set(value):
		gray_400 = value
		emit_changed()
@export var gray_500 := Color("7a7a86"):
	set(value):
		gray_500 = value
		emit_changed()
@export var gray_600 := Color("5d5d68"):
	set(value):
		gray_600 = value
		emit_changed()
@export var gray_700 := Color("43434c"):
	set(value):
		gray_700 = value
		emit_changed()
@export var gray_800 := Color("2c2c33"):
	set(value):
		gray_800 = value
		emit_changed()
@export var gray_900 := Color("18181c"):
	set(value):
		gray_900 = value
		emit_changed()
@export var accent_400 := Color("5b8def"):
	set(value):
		accent_400 = value
		emit_changed()
@export var accent_500 := Color("3a6fd8"):
	set(value):
		accent_500 = value
		emit_changed()
@export var accent_600 := Color("2b56ad"):
	set(value):
		accent_600 = value
		emit_changed()
@export var shadow := Color(0.0, 0.0, 0.0, 0.35):
	set(value):
		shadow = value
		emit_changed()


func color(swatch: Swatch) -> Color:
	return get(FIELDS[swatch])
