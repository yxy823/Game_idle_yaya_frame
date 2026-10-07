extends Resource

@export var target_id: String = ""
## Empty string means disk defaults; other strings are full slot IDs plus #preset.
@export var entries: Dictionary[String, String] = {}
