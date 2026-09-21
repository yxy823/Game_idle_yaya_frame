extends RefCounted

## Only this normalized contract crosses the process/UI boundary.

const STATES: Array[String] = ["available", "not_applicable", "unsupported", "failed"]
const Schema = preload("res://tools/asset_workbench/analysis_schema.gd")


static func failure(path: String, kind: String, code: String, message: String) -> Dictionary:
	return {
		"schema_version": 1, "status": "cancelled" if code == "cancelled" else "failed",
		"asset": {"path": path, "type": kind},
		"analyzer": {"id": kind + "_basic", "version": 1, "backend": {},
			"supported_types": [kind], "supported_metrics": []},
		"metrics": {}, "series": {}, "warnings": [],
		"errors": [{"code": code, "message": message}], "cache": {"hit": false, "key": ""},
	}


static func is_valid(value: Variant) -> bool:
	return Schema.is_valid(value)


static func comparison_identity(data: Dictionary) -> Array:
	var analyzer: Dictionary = data.get("analyzer", {})
	return [data.get("schema_version"), data.get("asset", {}).get("type"),
		analyzer.get("id"), analyzer.get("version"), analyzer.get("backend"),
		data.get("parameters", {})]


static func comparison_reason(first: Dictionary, second: Dictionary) -> String:
	if first.is_empty() or second.is_empty():
		return ""
	var labels := ["schema", "asset type", "analyzer", "analyzer version", "backend versions", "parameters"]
	var left := comparison_identity(first)
	var right := comparison_identity(second)
	var differences: Array[String] = []
	for index: int in labels.size():
		if left[index] != right[index]:
			differences.append(labels[index])
	return "" if differences.is_empty() else "A/B incompatible: " + ", ".join(differences)


static func metric_text(entry: Dictionary) -> String:
	if entry.is_empty():
		return "missing (not returned)"
	if entry.status != "available":
		return "%s: %s" % [entry.status, entry.reason]
	var value: Variant = entry.value
	var text := "%.5f" % float(value) if value is float or value is int else JSON.stringify(value)
	return text + " " + str(entry.unit)


static func compare_rows(first: Dictionary, second: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var a: Dictionary = first.get("metrics", {})
	var b: Dictionary = second.get("metrics", {})
	var keys: Array = a.keys()
	for key: String in b:
		if key not in keys:
			keys.append(key)
	for key: String in keys:
		rows.append({"metric": key, "a": metric_text(a.get(key, {})),
			"b": metric_text(b.get(key, {}))})
	return rows


static func rule_messages(data: Dictionary, max_edge_silence: float) -> Array[String]:
	var messages: Array[String] = []
	for key: String in ["leading_silence", "trailing_silence"]:
		var entry: Dictionary = data.get("metrics", {}).get(key, {})
		if entry.get("status") == "available" and float(entry.value) > max_edge_silence:
			messages.append("Rule: %s %.3f s > allowed %.3f s" % [
				key, float(entry.value), max_edge_silence])
	return messages
