extends RefCounted

const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Guard := preload("res://dev/debug/_shared/reference_guard.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const CANDIDATE_FIELDS: Array[String] = ["candidate", "candidate_params"]


## Does not mutate disk. The UI must confirm this concrete list before write_all. Slots in
## `skip_candidates` adopt a dev candidate that moves first, so only their other fields are checked.
static func preflight(slots: Array[Slot], skip_candidates: PackedStringArray = []) -> Dictionary:
	var issues: PackedStringArray = []
	var paths: PackedStringArray = []
	for slot in slots:
		var path := slot.game_path.simplify_path()
		var expected := "/%s/tuning/%s.tres" % [slot.target_id, slot.slot_path]
		if path.begins_with("res://dev/") or not path.ends_with(expected):
			issues.append("Not a game tuning resource: " + path)
		var checked := Guard.check(_checked_values(slot, slot.id in skip_candidates))
		issues.append_array(checked.issues)
		paths.append(path)
	return {"error": OK if issues.is_empty() else ERR_INVALID_DATA, "issues": issues, "paths": paths}


static func _checked_values(slot: Slot, skip_candidate: bool) -> Variant:
	if not skip_candidate:
		return slot.live
	var values: Dictionary = {}
	for field in Codec.fields(slot.live):
		if not String(field.name) in CANDIDATE_FIELDS:
			values[String(field.name)] = slot.live.get(field.name)
	return values


## Slots in `keep_candidates` keep the game's candidate on disk; their queued adoption writes it.
static func write_all(slots: Array[Slot], keep_candidates: PackedStringArray = []) -> Dictionary:
	var checked := preflight(slots, keep_candidates)
	if checked.error != OK:
		return checked
	var written: PackedStringArray = []
	for slot in slots:
		var keep: Array[String] = []
		if slot.id in keep_candidates:
			keep = CANDIDATE_FIELDS
		var result := _write_resource_result(slot.live, slot.game_path, keep)
		if result.saved:
			written.append(slot.game_path)
		if result.error != OK:
			return {"error": result.error, "message": slot.game_path, "written": written}
	return {"error": OK, "written": written}


## Also accepts user:// test files; production UI is restricted by preflight.
static func write_resource(live: Resource, path: String, keep: Array[String] = []) -> Error:
	return _write_resource_result(live, path, keep).error


static func _write_resource_result(live: Resource, path: String, keep: Array[String]) -> Dictionary:
	var disk := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if disk == null:
		return {"error": ERR_CANT_OPEN, "saved": false}
	var identity := ResourceLoader.get_resource_uid(path)
	var values: Dictionary = {}
	for field in Codec.fields(live):
		if String(field.name) in keep:
			continue
		var value: Variant = live.get(field.name)
		if field.name == "candidate_params" and value is Resource:
			value = Codec.copy_params(value)
		values[String(field.name)] = value
	Codec.apply_fields(disk, values)
	var error := ResourceSaver.save(disk, path)
	var saved := error == OK
	if error == OK and identity != ResourceUID.INVALID_ID:
		error = ResourceSaver.set_uid(ProjectSettings.globalize_path(path), identity)
	return {"error": error, "saved": saved}
