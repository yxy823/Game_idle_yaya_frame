extends Resource

@export_group("Numbers", "ranged_")
@export_range(0, 20, 2) var ranged_int: int = 4
@export_range(0, 5, 0.25, "or_greater", "suffix:s") var ranged_float: float = 1.0
@export_group("")
@export var count: int = 3
@export var weight: float = -2.5
@export var tint: Color = Color(0.2, 0.4, 0.6, 0.8)
@export var enabled: bool = true
@export_enum("First:2", "Second:7", "Third") var mode: int = 7
@export_enum("soft", "hard") var style: String = "soft"
@export var offset: Vector2 = Vector2(2, -3)
@export var curve: Curve = Curve.new()
@export var gradient: Gradient = Gradient.new()
@export var texture: Texture2D
@export_storage var stored_only: int = 9
@export_storage var huge: int = 9223372036854775800
@export_storage var sequence: Array = []
@export_storage var mapping: Dictionary = {}
@export_storage var typed_sequence: Array[Resource] = []
@export_storage var typed_mapping: Dictionary[String, Resource] = {}
var ordinary_member: int = 10
