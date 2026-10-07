extends RefCounted
## Preflight the complete resource graph, including UID and external dependencies.

const Codec := preload("res://dev/debug/_shared/preset_codec.gd")


static func check(value: Variant) -> Dictionary:
	var issues: PackedStringArray = []
	var visited: Array[int] = []
	var paths: PackedStringArray = []
	_walk(value, visited, paths, issues)
	return {"error": OK if issues.is_empty() else ERR_INVALID_DATA, "issues": issues}


static func _walk(value: Variant, visited: Array[int], paths: PackedStringArray,
		issues: PackedStringArray) -> void:
	if value is String:
		_check_path(value, paths, issues)
	elif value is Resource:
		_walk_resource(value, visited, paths, issues)
	elif value is Array or value is Dictionary:
		for key: Variant in value:
			_walk(key, visited, paths, issues)
			if value is Dictionary:
				_walk(value[key], visited, paths, issues)


static func _walk_resource(value: Resource, visited: Array[int], paths: PackedStringArray,
		issues: PackedStringArray) -> void:
	if value.get_instance_id() in visited:
		return
	visited.append(value.get_instance_id())
	_check_path(value.resource_path, paths, issues)
	var script := value.get_script() as Script
	if script != null:
		_check_path(script.resource_path, paths, issues)
	for field: Dictionary in value.get_property_list():
		if field.usage & PROPERTY_USAGE_STORAGE and field.name != "script":
			_walk(value.get(field.name), visited, paths, issues)


static func _check_path(identity: String, visited: PackedStringArray,
		issues: PackedStringArray) -> void:
	var path := Codec.resolve_uid(identity) if identity.begins_with("uid://") else identity
	if identity.begins_with("uid://") and path.is_empty():
		issues.append("Missing UID: " + identity)
		return
	if not path.begins_with("res://"):
		return
	path = path.get_slice("::", 0).simplify_path()
	if path in visited:
		return
	visited.append(path)
	if path.begins_with("res://dev/"):
		issues.append(path + " (file in dev/)")
		return
	if not ResourceLoader.exists(path):
		issues.append("Missing resource: " + path)
		return
	for dependency in ResourceLoader.get_dependencies(path):
		var parts := dependency.split("::")
		_check_path(parts[0], visited, issues)
		if parts.size() > 2:
			_check_path(parts[2], visited, issues)
