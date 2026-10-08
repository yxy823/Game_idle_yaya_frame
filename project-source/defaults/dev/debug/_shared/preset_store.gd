extends RefCounted

const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Preset := preload("res://dev/debug/_shared/slot_preset.gd")
const Combo := preload("res://dev/debug/_shared/target_combo.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")

var root: String = "res://dev/debug"


static func valid_name(value: String) -> bool:
	return not value.is_empty() and value.is_valid_filename() and not "#" in value \
		and value == value.strip_edges()


func preset_path(slot_id: String, preset_name: String) -> String:
	var target := slot_id.get_slice("/", 0)
	var relative := slot_id.trim_prefix(target + "/")
	return root.path_join(target + "/slots/" + relative + "/presets/" + preset_name + ".tres")


func combo_path(target: String, combo_name: String) -> String:
	return root.path_join(target + "/combos/" + combo_name + ".tres")


func list_names(directory: String) -> PackedStringArray:
	var result: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() == "tres":
			result.append(file.trim_suffix(".tres"))
	result.sort()
	return result


func save_slot(slot: Slot, preset_name: String) -> Dictionary:
	if not valid_name(preset_name):
		return {"error": ERR_INVALID_PARAMETER, "message": "Invalid preset name"}
	var encoded := Codec.pack_fields(slot.live)
	if encoded.error != OK:
		return encoded
	var preset := Preset.new()
	preset.slot_id = slot.id
	preset.fields = encoded.value
	var error := _save(preset, preset_path(slot.id, preset_name))
	if error == OK:
		slot.preset_name = preset_name
		slot.mark_saved()
	return {"error": error}


func check_slot(slot: Slot, preset_name: String) -> Dictionary:
	var defaults := slot.disk_defaults()
	if defaults == null:
		return {"error": ERR_CANT_OPEN, "message": slot.game_path}
	var baseline := Codec.pack_fields(defaults)
	if baseline.error != OK:
		return baseline
	if preset_name.is_empty():
		return Codec.check_fields(slot.live, baseline.value, defaults)
	var path := preset_path(slot.id, preset_name)
	if not FileAccess.file_exists(path):
		return _fallback(slot, baseline.value, defaults, "Missing preset: " + path)
	var preset := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Preset
	if preset == null or preset.slot_id != slot.id:
		return _fallback(slot, baseline.value, defaults, "Invalid slot preset: " + path)
	var checked := Codec.check_fields(slot.live, preset.fields, defaults)
	slot.check_candidate_pair(checked, defaults)
	return checked


func _fallback(slot: Slot, fields: Dictionary, defaults: Resource, issue: String) -> Dictionary:
	var checked := Codec.check_fields(slot.live, fields, defaults)
	checked.issues.append(issue)
	checked.fallback = true
	return checked


func load_slot(slot: Slot, preset_name: String) -> Dictionary:
	var checked := check_slot(slot, preset_name)
	if checked.error != OK:
		return checked
	Codec.apply_fields(slot.live, checked.values)
	_mark_loaded(slot, "" if checked.get("fallback", false) else preset_name,
		not checked.issues.is_empty())
	return checked


## A preset that loaded with some items in game values keeps its name and reads as modified.
static func _mark_loaded(slot: Slot, preset_name: String, partial: bool) -> void:
	slot.preset_name = preset_name
	slot.mark_saved()
	slot.differs_from_preset = partial and not preset_name.is_empty()


func save_combo(target: String, combo_name: String, slots: Array[Slot]) -> Dictionary:
	if not valid_name(combo_name):
		return {"error": ERR_INVALID_PARAMETER, "message": "Invalid combo name"}
	var combo := Combo.new()
	combo.target_id = target
	for slot in slots:
		if slot.is_dirty():
			return {"error": ERR_INVALID_DATA, "message": "Save slot first: " + slot.id,
				"text": "没能保存组合：“%s”有未保存的改动。先在它的“参数”区保存预设，再保存组合" % slot.display_name()}
		combo.entries[slot.id] = "" if slot.preset_name.is_empty() else slot.id + "#" + slot.preset_name
	return {"error": _save(combo, combo_path(target, combo_name)), "combo": combo}


func check_combo(target: String, combo_name: String, slots: Array[Slot]) -> Dictionary:
	var loaded := _read_combo(target, combo_name)
	var combo := loaded.combo as Combo
	var issues: PackedStringArray = []
	var values: Dictionary = {}
	var names: Dictionary[String, String] = {}
	var partial: Dictionary[String, bool] = {}
	for slot in slots:
		var checked := _check_combo_slot(slot, combo, loaded.invalid)
		if checked.error != OK:
			return checked
		values[slot.id] = checked.values
		names[slot.id] = checked.preset_name
		partial[slot.id] = not checked.issues.is_empty()
		for issue: String in checked.issues:
			issues.append(slot.id + ": " + issue)
	if combo != null:
		for identity: String in combo.entries:
			if not values.has(identity):
				issues.append(identity + ": Unknown slot")
	return {"error": OK, "values": values, "names": names, "partial": partial, "issues": issues}


func _read_combo(target: String, combo_name: String) -> Dictionary:
	if combo_name.is_empty():
		return {"combo": null, "invalid": false}
	var path := combo_path(target, combo_name)
	if not FileAccess.file_exists(path):
		return {"combo": null, "invalid": true}
	var combo := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Combo
	return {"combo": combo, "invalid": combo == null or combo.target_id != target}


func _check_combo_slot(slot: Slot, combo: Resource, invalid: bool) -> Dictionary:
	var name_part := _combo_reference(slot.id, combo, invalid)
	var unreadable := name_part == "!invalid"
	var checked := check_slot(slot, "" if unreadable else name_part)
	if checked.error != OK:
		return checked
	if unreadable:
		checked.issues.append("Invalid combo item")
	checked.preset_name = "" if unreadable or checked.get("fallback", false) else name_part
	return checked


## The preset name a combo gives a slot: "" for game values, "!invalid" when unreadable.
func _combo_reference(slot_id: String, combo: Resource, invalid: bool) -> String:
	if invalid or (combo != null and not combo.entries.has(slot_id)):
		return "!invalid"
	return _reference_name(slot_id, "" if combo == null else String(combo.entries[slot_id]))


func _reference_name(slot_id: String, preset_reference: String) -> String:
	if preset_reference.is_empty():
		return ""
	var parts := preset_reference.split("#")
	return parts[1] if parts.size() == 2 and parts[0] == slot_id and valid_name(parts[1]) else "!invalid"


func apply_combo(checked: Dictionary, slots: Array[Slot]) -> void:
	for slot in slots:
		Codec.apply_fields(slot.live, checked.values[slot.id])
		_mark_loaded(slot, checked.names[slot.id], checked.partial.get(slot.id, false))


func references(slot_id: String, preset_name: String) -> Dictionary:
	var result: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(root):
		return {"error": OK, "paths": result}
	for target in DirAccess.get_directories_at(root):
		if target.begins_with("_"):
			continue
		for combo_name in list_names(root.path_join(target + "/combos")):
			var path := combo_path(target, combo_name)
			var combo := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Combo
			if combo == null:
				return {"error": ERR_INVALID_DATA, "message": path}
			if combo.entries.get(slot_id) == slot_id + "#" + preset_name:
				result.append(path)
	return {"error": OK, "paths": result}


## Call only after the UI has shown references and received confirmation. All or nothing: a
## failure puts back the combos already changed; "unrestored" lists those it could not.
func delete_slot(slot_id: String, preset_name: String) -> Dictionary:
	var referenced := references(slot_id, preset_name)
	if referenced.error != OK:
		return referenced
	var updated: Dictionary[String, Combo] = {}
	var result := {"error": OK}
	for path: String in referenced.paths:
		var combo := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Combo
		combo.entries[slot_id] = ""
		result = {"error": _save(combo, path), "message": path}
		if result.error != OK:
			break
		updated[path] = combo
	if result.error == OK:
		var preset := preset_path(slot_id, preset_name)
		result = {"error": DirAccess.remove_absolute(preset), "message": preset}
	if result.error == OK:
		return result
	var unrestored: PackedStringArray = []
	for path: String in updated:
		updated[path].entries[slot_id] = slot_id + "#" + preset_name
		if _save(updated[path], path) != OK:
			unrestored.append(path)
	if not unrestored.is_empty():
		result.unrestored = unrestored
	return result


func delete_combo(target: String, combo_name: String) -> Error:
	return DirAccess.remove_absolute(combo_path(target, combo_name))


func _save(resource: Resource, path: String) -> Error:
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return error
	var old_uid := ResourceLoader.get_resource_uid(path) if FileAccess.file_exists(path) else -1
	error = ResourceSaver.save(resource, path)
	if error == OK and old_uid != ResourceUID.INVALID_ID:
		error = ResourceSaver.set_uid(ProjectSettings.globalize_path(path), old_uid)
	return error
