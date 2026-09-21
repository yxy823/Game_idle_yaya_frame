extends RefCounted

## Executes the vocabulary used by the shared schema, not a second field contract.

static var _schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
	"res://tools/asset_analyzer/result.schema.json"))


static func is_valid(value: Variant) -> bool:
	return _finite_json(value) and _matches(value, _schema)


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
