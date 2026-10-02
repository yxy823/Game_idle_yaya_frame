extends RefCounted

## Executes the vocabulary used by the shared schema, not a second field contract.

const SCHEMA_PATH: String = "res://asset_workbench/analyzer/result.schema.json"

static var _schema: Dictionary = {}


## Cache only a usable contract; callers can report the load failure before starting a job.
static func initialize() -> String:
	if not _schema.is_empty():
		return ""
	var file := FileAccess.open(SCHEMA_PATH, FileAccess.READ)
	if file == null:
		return "Cannot read %s: %s" % [SCHEMA_PATH, error_string(FileAccess.get_open_error())]
	var contents := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return "Cannot read %s: %s" % [SCHEMA_PATH, error_string(read_error)]
	var parser := JSON.new()
	if parser.parse(contents) != OK:
		return "Invalid JSON in %s: %s" % [SCHEMA_PATH, parser.get_error_message()]
	if not _valid_contract(parser.data):
		return "Invalid result schema structure in " + SCHEMA_PATH
	_schema = parser.data
	return ""


static func _valid_contract(value: Variant) -> bool:
	if not value is Dictionary or value.get("type") != "object":
		return false
	if not value.get("$defs") is Dictionary or not value.get("properties") is Dictionary:
		return false
	if not _string_list(value.get("required")) or value.required.is_empty():
		return false
	var definitions: Dictionary = value["$defs"]
	if not _valid_rule(value, definitions):
		return false
	return definitions.values().all(func(rule: Variant) -> bool:
		return _valid_rule(rule, definitions))


## Check the interpreter's input shapes, without duplicating result field requirements.
static func _valid_rule(value: Variant, definitions: Dictionary) -> bool:
	if not value is Dictionary or not _valid_constraints(value):
		return false
	if value.has("$ref") and not _valid_reference(value["$ref"], definitions):
		return false
	var properties: Variant = value.get("properties", {})
	if not properties is Dictionary:
		return false
	for key: String in ["items", "additionalProperties", "not", "if", "then", "else"]:
		if value.has(key) and not _valid_rule(value[key], definitions):
			return false
	return properties.values().all(func(child: Variant) -> bool:
		return _valid_rule(child, definitions))


static func _valid_reference(value: Variant, definitions: Dictionary) -> bool:
	return value is String and value.begins_with("#/$defs/") \
		and definitions.get(value.get_file()) is Dictionary


static func _valid_constraints(rule: Dictionary) -> bool:
	if rule.has("type") and rule.type not in [
		"object", "array", "string", "boolean", "null", "number", "integer"]:
		return false
	if rule.has("enum") and not rule["enum"] is Array:
		return false
	if not _string_list(rule.get("required", [])):
		return false
	return _valid_array_constraints(rule)


static func _valid_array_constraints(rule: Dictionary) -> bool:
	var maximum: Variant = rule.get("maxItems", 0)
	if not (maximum is int or maximum is float) or not is_finite(float(maximum)):
		return false
	if maximum < 0 or float(maximum) != floorf(float(maximum)):
		return false
	var lengths: Variant = rule.get("x-equal-lengths", [])
	if not _string_list(lengths):
		return false
	if not lengths.is_empty():
		return lengths.size() == 2 and lengths.all(func(key: String) -> bool:
			return key in rule.get("required", []))
	return true


static func _string_list(value: Variant) -> bool:
	return value is Array and value.all(func(item: Variant) -> bool: return item is String)


static func is_valid(value: Variant) -> bool:
	return initialize().is_empty() and _finite_json(value) and _matches(value, _schema)


static func _finite_json(value: Variant) -> bool:
	if value is Dictionary:
		for key: Variant in value:
			if not key is String or not _finite_json(value[key]):
				return false
		return true
	if value is Array:
		return value.all(_finite_json)
	if value is float:
		return is_finite(value)
	return value == null or value is String or value is bool or value is int


static func _matches(value: Variant, rule: Dictionary) -> bool:
	if rule.has("$ref"):
		rule = _schema["$defs"][str(rule["$ref"]).get_file()]
	if not _constraints_match(value, rule):
		return false
	if value is Dictionary:
		return _object_matches(value, rule)
	if value is Array:
		if value.size() > rule.get("maxItems", value.size()):
			return false
		return value.all(func(item: Variant) -> bool: return _matches(item, rule.get("items", {})))
	return true


static func _constraints_match(value: Variant, rule: Dictionary) -> bool:
	if rule.has("type") and not _type_matches(value, rule.type):
		return false
	if rule.has("const") and value != rule["const"]:
		return false
	if rule.has("enum") and value not in rule["enum"]:
		return false
	return _branch_matches(value, rule)


static func _branch_matches(value: Variant, rule: Dictionary) -> bool:
	if rule.has("not") and _matches(value, rule["not"]):
		return false
	if rule.has("if"):
		var branch := "then" if _matches(value, rule["if"]) else "else"
		if not _matches(value, rule.get(branch, {})):
			return false
	return true


static func _type_matches(value: Variant, kind: String) -> bool:
	match kind:
		"object": return value is Dictionary
		"array": return value is Array
		"string": return value is String
		"boolean": return value is bool
		"null": return value == null
		"number": return value is int or value is float
		"integer":
			return (value is int or value is float) and float(value) == floorf(float(value))
	return false


static func _object_matches(value: Dictionary, rule: Dictionary) -> bool:
	for key: String in rule.get("required", []):
		if not value.has(key):
			return false
	var properties: Dictionary = rule.get("properties", {})
	for key: String in value:
		var child_rule: Dictionary = properties.get(key, rule.get("additionalProperties", {}))
		if not _matches(value[key], child_rule):
			return false
	var lengths: Array = rule.get("x-equal-lengths", [])
	return lengths.is_empty() or value[lengths[0]].size() == value[lengths[1]].size()
