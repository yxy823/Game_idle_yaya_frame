# gdlint:ignore-file:god-class-functions=21
# 保留原因：公开函数是插槽对外的完整接口，拆开后面板与命令要跨文件读。用户同意于 2026-10-08。
extends RefCounted

signal changed()

const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Definition := preload("res://dev/debug/_shared/candidate_definition.gd")
const DESCRIPTOR := "candidate.tres"
const ADOPTED := "adopted.tres"

var id: String = ""
var target_id: String = ""
var slot_path: String = ""
var game_path: String = ""
var directory: String = ""
var debug_root: String = ""
## The loaded preset had items that fell back to game values, so the values differ from it.
var differs_from_preset: bool = false
var live: Resource
var candidates: Array[Dictionary] = []
var preset_name: String = ""
var pinned: bool = false
var actions: RefCounted
var _baseline: Variant
## Packed fields of the last saved or loaded state; per-field revert decodes from here.
var _saved_fields: Dictionary = {}


func configure(target: String, relative_path: String, resource_path: String,
		root: String = "res://dev/debug") -> Error:
	target_id = target
	slot_path = relative_path
	id = target + "/" + relative_path
	game_path = resource_path
	debug_root = root
	directory = root.path_join(target + "/slots/" + relative_path)
	live = ResourceLoader.load(game_path)
	if live == null:
		return ERR_CANT_OPEN
	live.changed.connect(_on_changed)
	mark_saved()
	return OK


func disk_defaults() -> Resource:
	var defaults := ResourceLoader.load(game_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if defaults == null:
		return null
	# Editable sub-resources saved as their own files would come back as the live instances.
	for field in Codec.fields(defaults):
		var child: Variant = defaults.get(field.name)
		if not (child is Curve or child is Gradient or field.name == "candidate_params" and child is Resource):
			continue
		if not child.resource_path.is_empty() and not "::" in child.resource_path:
			defaults.set(field.name, ResourceLoader.load(child.resource_path, "",
				ResourceLoader.CACHE_MODE_IGNORE))
	return defaults


func is_dirty() -> bool:
	return current_content() != _baseline


func current_content() -> Variant:
	var packed := Codec.pack_fields(live)
	return Codec.content(packed.get("value")) if packed.error == OK else null


func mark_saved() -> void:
	differs_from_preset = false
	var packed := Codec.pack_fields(live)
	_saved_fields = packed.value if packed.error == OK else {}
	_baseline = Codec.content(packed.get("value")) if packed.error == OK else null
	changed.emit()


## Paths of fields that differ from the saved state: "volume_db", "candidate_params/size",
## or "candidate" once when the candidate itself changed.
func modified_fields() -> PackedStringArray:
	var current: Variant = current_content()
	if not current is Dictionary or not _baseline is Dictionary:
		return []
	return differences(current, _baseline)


## Compares two content dictionaries of the same slot field by field.
static func differences(current: Dictionary, saved: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = []
	for key: String in current:
		if current[key] == saved.get(key):
			continue
		if key != "candidate_params":
			result.append(key)
		elif current.get("candidate") == saved.get("candidate"):
			result.append_array(_parameter_differences(current[key], saved.get(key)))
	return result


static func _parameter_differences(current: Variant, saved: Variant) -> PackedStringArray:
	if not current is Dictionary or not saved is Dictionary \
			or current.get("script_uid") != saved.get("script_uid"):
		return ["candidate_params"]
	var result: PackedStringArray = []
	var fields: Dictionary = current.get("fields", {})
	var saved_fields: Dictionary = saved.get("fields", {})
	for key: String in fields:
		if fields[key] != saved_fields.get(key):
			result.append("candidate_params/" + key)
	return result


## The saved value of one modified_fields() path, decoded; null when it cannot be decoded.
func saved_value(path: String) -> Variant:
	var decoded := _decode_saved(path)
	return decoded.value if decoded.error == OK else null


## Puts one field back to its saved value; the candidate itself is switched through candidates.
func revert_field(path: String) -> Dictionary:
	var parts := path.split("/")
	var target := live if parts.size() == 1 else live.get("candidate_params") as Resource
	var key := parts[parts.size() - 1]
	if target == null or not key in target or path == "candidate":
		return {"error": ERR_INVALID_PARAMETER, "message": "Cannot revert " + path,
			"text": "这一项不能单独还原，请在“实现”里重新选择候选"}
	var decoded := _decode_saved(path)
	if decoded.error == OK:
		target.set(key, decoded.value)
	return decoded


func _decode_saved(path: String) -> Dictionary:
	var parts := path.split("/")
	var stored: Variant = _saved_fields.get(parts[0])
	if parts.size() == 2:
		stored = stored.get("fields", {}).get(parts[1]) if stored is Dictionary else null
	return Codec.decode(stored)


func refresh_candidates() -> Dictionary:
	candidates.clear()
	var defaults := disk_defaults()
	if defaults == null:
		return {"error": ERR_CANT_OPEN, "message": game_path}
	if not _has_candidate(defaults):
		return {"error": OK}
	# An unregistered UID must not hide the list: the game entry is still selectable.
	var packed := Codec.pack_fields(defaults)
	candidates.append({"id": "", "name": "游戏原值", "fields": packed.get("value", {}),
		"license": "已采纳的游戏资源", "source": ""})
	_add_game_candidates(defaults.get("candidate") as Resource)
	var errors: PackedStringArray = []
	for child: String in _descriptors():
		var path := directory.path_join(child + "/candidate.tres")
		var definition := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Definition
		if definition == null:
			errors.append(path)
			continue
		candidates.append({"id": child, "name": definition.display_name, "path": path,
			"definition": definition, "license": definition.license_note,
			"source": definition.source_url})
	if packed.error != OK:
		return {"error": OK, "issues": PackedStringArray([packed.message]), "text":
			"%s用到的文件还没登记好：可以照常试用和采纳；如果切换出错，重启调试台一次，或请 Agent 按说明第 6 节收尾" % display_name()}
	if errors.is_empty():
		return {"error": OK}
	return {"error": OK, "issues": errors,
		"text": "有 %d 个候选的说明文件读不出来，已从列表中略过" % errors.size()}


## Implementations a later adoption replaced stay in game/ and remain selectable.
func _add_game_candidates(adopted: Resource) -> void:
	for definition in _game_definitions():
		var path := Codec.resolve_uid(definition.candidate_uid)
		if not path.is_empty() and (adopted == null or path != adopted.resource_path):
			candidates.append({"id": "game:" + definition.candidate_uid, "definition": definition,
				"name": definition.display_name, "source": "",
				"license": "游戏目录中的实现：" + path.get_base_dir().trim_prefix("res://")})


## Candidate directory names that hold `file`; presets/ is never a candidate. A candidate
## moved into game/ keeps its descriptor as adopted.tres until the Agent names it in slot.gd.
func _descriptors(file: String = DESCRIPTOR) -> PackedStringArray:
	var result: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for child in DirAccess.get_directories_at(directory):
		if child != "presets" and FileAccess.file_exists(directory.path_join(child).path_join(file)):
			result.append(child)
	return result


func select_candidate(index: int) -> Dictionary:
	if index < 0 or index >= candidates.size():
		return {"error": ERR_INVALID_PARAMETER, "message": "Invalid candidate index",
			"text": "没能切换候选：这个候选已不在列表中。重新选择插槽后再试"}
	var entry := candidates[index]
	var defaults := disk_defaults()
	if entry.id == "" and entry.fields.is_empty():
		Codec.apply_fields(live, {"candidate": defaults.get("candidate"),
			"candidate_params": Codec.copy_value(defaults.get("candidate_params"))})
		return {"error": OK}
	var packed := Codec.pack_fields(live)
	if packed.error != OK:
		return packed
	var stored: Dictionary = packed.value
	if entry.id == "":
		stored.candidate = entry.fields.candidate
		stored.candidate_params = entry.fields.get("candidate_params")
	else:
		var definition: Definition = entry.definition
		stored.candidate = definition.candidate_uid
		stored.candidate_params = null
		if not definition.default_params.is_empty():
			stored.candidate_params = definition.default_params
	var checked := Codec.check_fields(live, stored, defaults)
	check_candidate_pair(checked, defaults)
	if not checked.issues.is_empty():
		return {"error": ERR_INVALID_DATA, "issues": checked.issues,
			"message": "Candidate or parameters are invalid",
			"text": "没能切换到“%s”：它的文件或参数和这个插槽对不上。请让 Agent 检查这个候选" % entry.name}
	Codec.apply_fields(live, checked.values)
	return {"error": OK}


## The descriptor defines the parameter class; presets cannot substitute another class.
func check_candidate_pair(checked: Dictionary, defaults: Resource) -> void:
	if not checked.values.has("candidate"):
		return
	var values: Dictionary = checked.values
	var candidate := values.candidate as Resource
	var expected := _candidate_parameter_type(candidate, defaults)
	var params := values.get("candidate_params") as Resource
	var actual := "" if params == null else _parameter_type(params)
	if expected != "!missing" and actual == expected:
		return
	checked.issues.append("candidate" if expected == "!missing" else "candidate_params")
	values.candidate = defaults.get("candidate")
	values.candidate_params = Codec.copy_value(defaults.get("candidate_params"))


func _candidate_parameter_type(candidate: Resource, defaults: Resource) -> String:
	if candidate == defaults.get("candidate"):
		var params := defaults.get("candidate_params") as Resource
		return "" if params == null else _parameter_type(params)
	if candidate == null:
		return "!missing"
	var definition := _definition_for(candidate)
	return "!missing" if definition == null else String(definition.default_params.get("script_uid", ""))


## The descriptor whose candidate_uid resolves to this resource: a dev candidate, one just
## moved into game/ (adopted.tres) or one slot.gd names in CANDIDATES.
func _definition_for(candidate: Resource) -> Definition:
	var known: Array[Definition] = []
	for child: String in _descriptors():
		known.append(ResourceLoader.load(directory.path_join(child).path_join(DESCRIPTOR), "",
			ResourceLoader.CACHE_MODE_IGNORE) as Definition)
	known.append_array(_game_definitions())
	for definition in known:
		if definition != null and Codec.resolve_uid(definition.candidate_uid) == candidate.resource_path:
			return definition
	return null


## Implementations in game/: slot.gd CANDIDATES entries {"uid://…": {"name": "中文名",
## "params": "uid://参数脚本"}} and candidates just moved in, which keep adopted.tres.
func _game_definitions() -> Array[Definition]:
	var result: Array[Definition] = []
	for child: String in _descriptors(ADOPTED):
		var adopted := ResourceLoader.load(directory.path_join(child).path_join(ADOPTED), "",
			ResourceLoader.CACHE_MODE_IGNORE) as Definition
		if adopted != null:
			result.append(adopted)
	var named: Dictionary = constant("CANDIDATES", {})
	for identity: String in named:
		var entry: Variant = named[identity]
		var definition := Definition.new()
		definition.candidate_uid = identity
		definition.display_name = String(entry.get("name", "")) if entry is Dictionary else String(entry)
		var script_path := Codec.resolve_uid(String(entry.get("params", ""))) if entry is Dictionary else ""
		if not script_path.is_empty():
			var packed := Codec.pack_fields((load(script_path) as Script).new())
			definition.default_params = {"script_uid": entry.params, "fields": packed.get("value", {})}
		result.append(definition)
	return result


func _parameter_type(params: Resource) -> String:
	var script := params.get_script() as Script
	if script == null:
		return params.get_class()
	return ResourceUID.id_to_text(ResourceLoader.get_resource_uid(script.resource_path))


func search_text() -> String:
	var names: PackedStringArray = [id, display_name()]
	for field in Codec.fields(live):
		names.append(String(field.name))
		names.append(field_caption(String(field.name), ""))
	var params := live.get("candidate_params") as Resource if _has_candidate(live) else null
	if params != null:
		for field in Codec.fields(params):
			names.append(String(field.name))
			names.append(field_caption(String(field.name), ""))
	return " ".join(names).to_lower()


## slot.gd may declare TITLE; otherwise the resource name or the file name is shown.
func display_name() -> String:
	var title := String(constant("TITLE", ""))
	if not title.is_empty():
		return title
	return live.resource_name if not live.resource_name.is_empty() else slot_path.get_file().capitalize()


## slot.gd may declare FIELDS {"field_name": "中文名"} for its own and its candidates' fields.
func field_caption(field_name: String, fallback: String) -> String:
	var captions: Dictionary = constant("FIELDS", {})
	return String(captions.get(field_name, fallback))


## A value in the slot's own words: VALUES {"field_name": {stored value: "中文"}} first, then
## slot.gd's optional value_text(field_name, value); "" when neither names it.
func value_text(field_name: String, value: Variant) -> String:
	var captions: Dictionary = constant("VALUES", {}).get(field_name, {})
	if captions.has(value):
		return String(captions[value])
	if actions != null and actions.has_method("value_text"):
		return String(actions.value_text(field_name, value))
	return ""


## slot.gd may declare CANDIDATES {"uid://…": "中文名"} for candidates the game adopted; a
## candidate just moved into game/ keeps its descriptor's name; otherwise the file name is shown.
func candidate_title(candidate: Resource) -> String:
	var definition := _definition_for(candidate)
	return definition.display_name if definition != null \
		else candidate.resource_path.get_file().get_basename()


## Applies packed fields to the live resource without touching the saved state, the way a
## comparison shows another set of values; candidate and parameters fall back together.
func apply_values(stored: Dictionary) -> Dictionary:
	var defaults := disk_defaults()
	if defaults == null:
		return {"error": ERR_CANT_OPEN, "message": game_path}
	var checked := Codec.check_fields(live, stored, defaults)
	check_candidate_pair(checked, defaults)
	Codec.apply_fields(live, checked.values)
	return checked


## Everything needed to come back to the current values after showing a comparison.
func snapshot() -> Dictionary:
	var packed := Codec.pack_fields(live)
	return {"fields": packed.get("value", {}), "saved": _saved_fields.duplicate(),
		"baseline": _baseline, "preset": preset_name, "dirty": is_dirty()}


func restore(state: Dictionary) -> Dictionary:
	var checked := apply_values(state.fields)
	_saved_fields = state.saved
	_baseline = state.baseline
	preset_name = state.preset
	changed.emit()
	return checked


## A constant of the slot's slot.gd: TITLE, FIELDS, CANDIDATES, VALUES ({"field_name":
## {stored value: "中文"}} for enum options and special numbers), ADOPT_DIRECTORY or LOGIC.
func constant(constant_name: String, fallback: Variant) -> Variant:
	var script := actions.get_script() as Script if actions != null else null
	return script.get_script_constant_map().get(constant_name, fallback) if script != null else fallback


func _has_candidate(resource: Resource) -> bool:
	for field in Codec.fields(resource):
		if field.name == "candidate":
			return true
	return false


func _on_changed() -> void:
	changed.emit()
