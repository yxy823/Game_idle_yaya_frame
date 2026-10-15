extends "res://dev/debug/_shared/preset_store.gd"
## Writes a real combo, then simulates a UID-restoration failure and optional rollback failure.

var fail_restore: bool = false
var saves: int = 0
var saved_entries: Dictionary = {}
var result: Dictionary = {}

func _save(resource: Resource, path: String) -> Error:
	saves += 1
	if saves > 1 and fail_restore:
		return ERR_FILE_CANT_WRITE
	var error := super._save(resource, path)
	if error != OK or saves > 1:
		return error
	saved_entries = (ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Combo).entries
	return ERR_FILE_CANT_WRITE

func delete_slot(slot_id: String, preset_name: String) -> Dictionary:
	result = super.delete_slot(slot_id, preset_name)
	return result
