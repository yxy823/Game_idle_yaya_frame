extends RefCounted

## Only this normalized contract crosses the process/UI boundary.

const STATES: Array[String] = ["available", "not_applicable", "unsupported", "failed"]


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
	if not value is Dictionary or value.get("schema_version") != 1:
		return false
	if value.get("status") not in ["success", "partial", "failed", "cancelled"]:
		return false
	for key: String in ["asset", "analyzer", "metrics", "series", "cache"]:
		if not value.get(key) is Dictionary:
			return false
	if not _metadata_valid(value):
		return false
	for key: String in ["warnings", "errors"]:
		if not _issues_valid(value.get(key)):
			return false
	return value.metrics.values().all(_metric_valid) and value.series.values().all(_series_valid)


static func _metadata_valid(value: Dictionary) -> bool:
	if not value.asset.get("path") is String or not value.asset.get("type") is String:
		return false
	if not value.analyzer.get("backend") is Dictionary or not value.cache.get("hit") is bool:
		return false
	if not value.analyzer.get("id") is String:
		return false
	if not value.cache.get("key") is String:
		return false
	return _analyzer_valid(value.analyzer)


static func _analyzer_valid(analyzer: Dictionary) -> bool:
	var version: Variant = analyzer.get("version")
	if not (version is float or version is int):
		return false
	if not is_finite(float(version)) or float(version) != floorf(float(version)):
		return false
	return analyzer.get("supported_types") is Array and analyzer.get("supported_metrics") is Array


static func _issues_valid(entries: Variant) -> bool:
	if not entries is Array:
		return false
	for entry: Variant in entries:
		if not entry is Dictionary or not entry.get("message") is String:
			return false
	return true


static func _metric_valid(entry: Variant) -> bool:
	if not entry is Dictionary or entry.get("status") not in STATES:
		return false
	if not entry.get("unit") is String or not entry.get("reason") is String:
		return false
	if entry.status != "available":
		return entry.get("value") == null
	if entry.get("value") is float:
		return is_finite(entry.value)
	return entry.get("value") != null


static func _series_valid(entry: Variant) -> bool:
	if not entry is Dictionary or entry.get("kind") not in ["line", "histogram"]:
		return false
	if entry.get("status") != "available":
		return false
	if not entry.get("x") is Array or not entry.get("y") is Array:
		return false
	if entry.x.size() != entry.y.size() or entry.x.size() > 2048:
		return false
	if not entry.get("x_unit") is String or not entry.get("y_unit") is String:
		return false
	return _numbers_valid(entry.x + entry.y)


static func _numbers_valid(numbers: Array) -> bool:
	for number: Variant in numbers:
		if not (number is float or number is int) or not is_finite(float(number)):
			return false
	return true


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
