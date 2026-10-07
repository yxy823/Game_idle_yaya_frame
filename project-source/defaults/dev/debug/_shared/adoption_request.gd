extends Resource
## One queued candidate adoption: files that move into game/ at the next debug start, then
## the slot fields written to the game tuning resource. Deleted once it has run.

@export var slot_id: String = ""
@export var target_id: String = ""
@export var slot_path: String = ""
@export var game_path: String = ""
@export var candidate_name: String = ""
@export var source: String = ""
@export var destination: String = ""
@export var files: PackedStringArray = []
## Codec.pack_fields of the slot at adoption time; UIDs resolve to the moved files.
@export var fields: Dictionary = {}
