extends RefCounted

## Serializable membership and project rules, separate from source measurements.

const Result = preload("res://yaya/asset_workbench/ui/analysis_result.gd")
const MAX_ASSETS: int = 512
const MAX_RULES: int = 64
const MAX_JSON_BYTES: int = 33554432


static func empty() -> Dictionary:
	return {"group_version": 1, "name": "Resource group", "assets": [],
		"parameters": {}, "rules": []}


static func project_path(path: String) -> String:
	var normalized := ProjectSettings.localize_path(path.simplify_path())
	return normalized if normalized.begins_with("res://") else ""


static func validation_error(value: Variant) -> String:
	var issue := _header_error(value)
	if not issue.is_empty():
		return issue
	if value.assets.size() > MAX_ASSETS or value.rules.size() > MAX_RULES:
		return "Group exceeds 512 assets or 64 rules. Split it into smaller groups."
	if not _members_valid(value.assets):
		return "Group contains an invalid or duplicate project asset."
	if not value.rules.all(_rule_valid):
		return "Invalid rule: choose a numeric metric, unit, operator and finite value."
	return ""


static func _header_error(value: Variant) -> String:
	if not value is Dictionary or value.get("group_version") != 1:
		return "Unsupported resource group version."
	if not value.get("name") is String or not value.get("parameters") is Dictionary:
		return "Group name or analysis parameters are invalid."
	if not value.get("assets") is Array or not value.get("rules") is Array:
		return "Group assets and rules must be arrays."
	return ""


static func _members_valid(assets: Array) -> bool:
	var paths: Array[String] = []
	for asset: Variant in assets:
		if not _asset_valid(asset) or asset.path in paths:
			return false
		paths.append(asset.path)
	return true


static func _asset_valid(asset: Variant) -> bool:
	if not asset is Dictionary or not asset.get("path") is String:
		return false
	if project_path(asset.path) != asset.path or asset.path.contains("::"):
		return false
	return asset.get("type") in ["audio", "image"]


static func _rule_valid(rule: Variant) -> bool:
	if not rule is Dictionary or rule.get("type") not in ["audio", "image"]:
		return false
	if not rule.get("metric") is String or not rule.get("unit") is String:
		return false
	if rule.get("operator") not in ["min", "max", "delta"]:
		return false
	var value: Variant = rule.get("value")
	if not (value is float or value is int) or not is_finite(float(value)):
		return false
	return rule.operator != "delta" or value >= 0


static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot open " + path}
	if file.get_length() > MAX_JSON_BYTES:
		return {"error": "JSON exceeds 32 MiB. Split the group."}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": "Invalid JSON: " + parser.get_error_message()}
	return {"data": parser.data}


static func write_json(path: String, data: Dictionary) -> String:
	if project_path(path).is_empty() or path.get_extension() != "json":
		return "Choose a .json file inside this project."
	var encoded := (JSON.stringify(data, "  ") + "\n").to_utf8_buffer()
	if encoded.size() > MAX_JSON_BYTES:
		return "JSON exceeds 32 MiB. Split the group; no file was written."
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "Cannot write " + path
	file.store_buffer(encoded)
	file.flush()
	return "" if file.get_error() == OK else "Writing JSON failed."


static func snapshot_error(value: Variant) -> String:
	if not value is Dictionary or value.get("snapshot_version") != 1:
		return "Unsupported analysis snapshot."
	var issue := validation_error(value.get("group"))
	if not issue.is_empty():
		return issue
	if not value.get("results") is Dictionary or not value.get("created_at") is String:
		return "Snapshot results or timestamp are missing."
	return _snapshot_results_error(value)


static func _snapshot_results_error(value: Dictionary) -> String:
	for path: Variant in value.results:
		if not path is String or not Result.is_valid(value.results[path]):
			return "Snapshot contains an invalid Analyzer result."
		var data: Dictionary = value.results[path]
		var asset := {"path": path, "type": data.asset.type}
		if asset not in value.group.assets or project_path(data.asset.path) != path:
			return "Snapshot result does not match its group member."
	return ""
