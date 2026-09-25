extends RefCounted

## Comparable cohorts retain type, units, analysis parameters and backend identity.
## Differences are measurements or explicit rules, never an aesthetic score.

const Result = preload("res://tools/asset_workbench/analysis_result.gd")


static func columns(results: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for path: String in results:
		var data: Dictionary = results[path]
		for metric: String in data.metrics:
			var entry: Dictionary = data.metrics[metric]
			if not _numeric(entry):
				continue
			var key := _key(data, metric, entry.unit)
			if not output.has(key):
				output[key] = {"type": data.asset.type, "metric": metric,
					"unit": entry.unit, "values": {}, "analyzer": data.analyzer,
					"parameters": data.get("parameters", {})}
			output[key]["values"][path] = float(entry.value)
	for column: Dictionary in output.values():
		var values: Array = column["values"].values()
		values.sort()
		column.count = values.size()
		column.minimum = values.front()
		column.maximum = values.back()
		var middle := floori(values.size() * 0.5)
		column.median = values[middle]
		if values.size() % 2 == 0:
			column.median = (values[middle - 1] + values[middle]) * 0.5
	return output


static func checks(group: Dictionary, results: Dictionary, stats: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for asset: Dictionary in group.assets:
		var rows: Array[Dictionary] = []
		for rule: Dictionary in group.rules:
			if rule.type == asset.type:
				rows.append(_check(rule, results.get(asset.path, {}), stats))
		output[asset.path] = rows
	return output


static func _check(rule: Dictionary, data: Dictionary, stats: Dictionary) -> Dictionary:
	var row := {"rule": rule, "status": "unmeasured", "message": "No result"}
	if data.is_empty():
		return row
	var entry: Dictionary = data.metrics.get(rule.metric, {})
	if not _numeric(entry):
		row.message = "%s: %s (%s)" % [rule.metric, entry.get("status", "missing"),
			entry.get("reason", data.status)]
		return row
	if entry.unit != rule.unit:
		row.message = "Unit mismatch: %s / expected %s" % [entry.unit, rule.unit]
		return row
	var actual := float(entry.value)
	var passed: bool = actual >= rule.value if rule.operator == "min" else actual <= rule.value
	row.message = "%s = %.5f %s; %s %.5f" % [rule.metric, actual,
		rule.unit, rule.operator, rule.value]
	if rule.operator == "delta":
		var column: Dictionary = stats.get(_key(data, rule.metric, entry.unit), {})
		if int(column.get("count", 0)) < 3:
			row.message += "; need at least 3 comparable measurements"
			return row
		passed = absf(actual - column.median) <= rule.value
		row.message += "; median %.5f, absolute distance %.5f, n=%d" % [
			column.median, absf(actual - column.median), column.count]
	row.status = "pass" if passed else "deviation"
	return row


static func summary(rows: Array) -> String:
	if rows.is_empty():
		return "No applicable rules"
	var deviations := rows.filter(func(row: Dictionary) -> bool: return row.status == "deviation")
	var missing := rows.filter(func(row: Dictionary) -> bool: return row.status == "unmeasured")
	return "%d deviations / %d unmeasured" % [deviations.size(), missing.size()]


static func _numeric(entry: Dictionary) -> bool:
	var value: Variant = entry.get("value")
	return entry.get("status") == "available" and (value is int or value is float)


static func _key(data: Dictionary, metric: String, unit: String) -> String:
	return JSON.stringify([Result.comparison_identity(data), metric, unit])
