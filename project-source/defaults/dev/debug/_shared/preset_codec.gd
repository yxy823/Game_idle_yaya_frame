extends RefCounted
## Only this reflection boundary uses Variant. External resources stay UID strings.


static func fields(resource: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for field: Dictionary in resource.get_property_list():
		if field.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and field.usage & PROPERTY_USAGE_STORAGE:
			result.append(field)
	return result


static func pack_fields(resource: Resource) -> Dictionary:
	var values: Dictionary = {}
	for field in fields(resource):
		var encoded := encode(resource.get(field.name), field.name == "candidate_params")
		if encoded.error != OK:
			return encoded
		values[String(field.name)] = encoded.value
	return {"error": OK, "value": values}


static func encode(value: Variant, inline_params: bool = false) -> Dictionary:
	if value is Curve or value is Gradient:
		return {"error": OK, "value": value.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)}
	if value is Resource:
		return _encode_resource(value, inline_params)
	if value is Array or value is Dictionary:
		return _encode_container(value)
	return {"error": OK, "value": value}


static func _encode_resource(value: Resource, inline_params: bool) -> Dictionary:
	var path := value.resource_path
	if not inline_params and path.begins_with("res://game/") and "/tuning/" in path:
		return {"error": OK, "value": {"slot_id": slot_id_for(path)}}
	if not inline_params and not path.is_empty() and not "::" in path:
		return _uid_value(path)
	var script := value.get_script() as Script
	if script == null:
		return {"error": ERR_INVALID_DATA, "message": "Unsupported inline resource: " + path}
	var identity := _uid_value(script.resource_path)
	if identity.error != OK:
		return identity
	var packed := pack_fields(value)
	if packed.error != OK:
		return packed
	return {"error": OK, "value": {"script_uid": identity.value, "fields": packed.value}}


static func _uid_value(path: String) -> Dictionary:
	var identity := ResourceLoader.get_resource_uid(path)
	if identity == ResourceUID.INVALID_ID:
		return {"error": ERR_INVALID_DATA, "message": "Missing UID: " + path}
	return {"error": OK, "value": ResourceUID.id_to_text(identity)}


static func _encode_container(value: Variant) -> Dictionary:
	var output: Variant = []
	if value is Dictionary:
		output = {}
	for key: Variant in value:
		var item: Variant = value[key] if value is Dictionary else key
		var encoded := encode(item)
		if encoded.error != OK:
			return encoded
		if output is Dictionary:
			var encoded_key := encode(key)
			if encoded_key.error != OK:
				return encoded_key
			output[encoded_key.value] = encoded.value
		else:
			output.append(encoded.value)
	return {"error": OK, "value": output}


static func resolve_uid(identity: String) -> String:
	if not identity.begins_with("uid://"):
		return ""
	var number := ResourceUID.text_to_id(identity)
	if not ResourceUID.has_id(number):
		return ""
	var path := ResourceUID.get_id_path(number)
	return path if ResourceLoader.exists(path) else ""


static func decode(value: Variant) -> Dictionary:
	if value is String and value.begins_with("uid://"):
		var path := resolve_uid(value)
		if path.is_empty():
			return {"error": ERR_FILE_NOT_FOUND, "message": "Missing UID: " + value}
		return {"error": OK, "value": ResourceLoader.load(path)}
	if value is Curve or value is Gradient:
		return {"error": OK, "value": value.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)}
	if value is Dictionary:
		return _decode_dictionary(value)
	if value is Array:
		return _decode_container(value)
	return {"error": OK, "value": value}


static func _decode_dictionary(value: Dictionary) -> Dictionary:
	if value.has("script_uid"):
		return _decode_params(value)
	if value.has("slot_id"):
		return _decode_slot(value.slot_id)
	return _decode_container(value)


static func _decode_slot(identity: String) -> Dictionary:
	var path := path_for_slot(identity)
	if not ResourceLoader.exists(path):
		return {"error": ERR_FILE_NOT_FOUND, "message": "Missing slot: " + identity}
	return {"error": OK, "value": ResourceLoader.load(path)}


static func _decode_params(data: Dictionary, baseline: Resource = null) -> Dictionary:
	var path := resolve_uid(str(data.script_uid))
	if path.is_empty() or not data.get("fields") is Dictionary:
		return {"error": ERR_INVALID_DATA, "message": "Missing parameter script or fields"}
	var script := ResourceLoader.load(path) as Script
	if script == null or not script.can_instantiate():
		return {"error": ERR_INVALID_DATA, "message": "Invalid parameter script"}
	if not ClassDB.is_parent_class(script.get_instance_base_type(), "Resource"):
		return {"error": ERR_INVALID_DATA, "message": "Parameter script must extend Resource"}
	var resource: Resource = script.new()
	var defaults := baseline if baseline != null and baseline.get_script() == script else resource
	var checked := check_fields(resource, data.fields, defaults)
	apply_fields(resource, checked.values)
	return {"error": OK, "value": resource, "issues": checked.issues}


static func _decode_container(value: Variant) -> Dictionary:
	var output: Variant = []
	if value is Dictionary:
		output = {}
	for key: Variant in value:
		var decoded := decode(value[key] if value is Dictionary else key)
		if decoded.error != OK:
			return decoded
		if output is Dictionary:
			var decoded_key := decode(key)
			if decoded_key.error != OK:
				return decoded_key
			output[decoded_key.value] = decoded.value
		else:
			output.append(decoded.value)
	return {"error": OK, "value": output}


static func check_fields(schema: Resource, stored: Dictionary, defaults: Resource) -> Dictionary:
	var values: Dictionary = {}
	var issues: PackedStringArray = []
	var known: Array[String] = []
	for field in fields(schema):
		var key := String(field.name)
		known.append(key)
		var decoded := _check_field(schema, field, stored, defaults)
		if decoded.error != OK:
			issues.append(key)
			values[key] = copy_value(defaults.get(key))
		else:
			values[key] = decoded.value
			for issue: String in decoded.get("issues", []):
				issues.append(key + "." + issue)
	for key: Variant in stored:
		if not str(key) in known:
			issues.append(str(key))
	_check_pair(values, defaults, issues)
	return {"error": OK, "values": values, "issues": issues}


static func _check_field(schema: Resource, field: Dictionary, stored: Dictionary,
		defaults: Resource) -> Dictionary:
	var key := String(field.name)
	if not stored.has(key):
		return {"error": ERR_INVALID_DATA}
	var decoded := decode(stored[key])
	if key == "candidate_params" and stored[key] is Dictionary:
		decoded = _decode_params(stored[key], defaults.get(key))
	if decoded.error != OK:
		return decoded
	if not fits(field, decoded.value):
		return {"error": ERR_INVALID_DATA}
	if key == "candidate" and not _candidate_valid(decoded.value, defaults.get(key)):
		return {"error": ERR_INVALID_DATA}
	var container := _restore_container_type(decoded.value, schema.get(key))
	if container.error != OK:
		return container
	decoded.value = container.value
	return decoded


static func _restore_container_type(value: Variant, template: Variant) -> Dictionary:
	if value is Array and template.is_typed():
		for item: Variant in value:
			if not _element_fits(template.get_typed_builtin(), template.get_typed_class_name(),
					template.get_typed_script(), item):
				return {"error": ERR_INVALID_DATA}
		var result: Array = template.duplicate()
		result.clear()
		result.assign(value)
		return {"error": OK, "value": result}
	if value is Dictionary and template.is_typed():
		return _restore_dictionary_type(value, template)
	return {"error": OK, "value": value}


static func _restore_dictionary_type(value: Dictionary, template: Dictionary) -> Dictionary:
	for key: Variant in value:
		if not _element_fits(template.get_typed_key_builtin(), template.get_typed_key_class_name(),
				template.get_typed_key_script(), key):
			return {"error": ERR_INVALID_DATA}
		if not _element_fits(template.get_typed_value_builtin(), template.get_typed_value_class_name(),
				template.get_typed_value_script(), value[key]):
			return {"error": ERR_INVALID_DATA}
	var result := template.duplicate()
	result.clear()
	result.assign(value)
	return {"error": OK, "value": result}


static func _element_fits(kind: int, class_type: StringName, script: Script, value: Variant) -> bool:
	if kind == TYPE_NIL:
		return true
	if kind != TYPE_OBJECT:
		return typeof(value) == kind
	if value == null:
		return true
	if not value is Object:
		return false
	if script == null:
		return class_type.is_empty() or value.is_class(class_type)
	var actual := value.get_script() as Script
	while actual != null:
		if actual == script:
			return true
		actual = actual.get_base_script()
	return false


## A candidate is the same kind as the game's own: none only when the game uses none, and a
## script or scene shares the named base class (class_name) of the game's implementation.
static func _candidate_valid(candidate: Variant, current: Variant) -> bool:
	if candidate == null:
		return current == null
	if current == null or not (candidate is Script or candidate is PackedScene):
		return true
	if not candidate.can_instantiate():
		return false
	return _implementation_base(candidate) == _implementation_base(current)


## The topmost class_name above a script or a scene's root script; the engine class without one.
static func _implementation_base(implementation: Resource) -> String:
	var script := implementation as Script
	var node: Node = null
	if implementation is PackedScene:
		node = (implementation as PackedScene).instantiate()
		script = node.get_script() as Script
	var base := node.get_class() if node != null else ""
	if script != null:
		base = script.get_instance_base_type()
	while script != null:
		if not script.get_global_name().is_empty():
			base = script.get_global_name()
		script = script.get_base_script()
	if node != null:
		node.free()
	return base


static func fits(field: Dictionary, value: Variant) -> bool:
	if field.type == TYPE_OBJECT:
		if value == null:
			return true
		var expected := String(field.hint_string)
		return value is Resource and (expected.is_empty() or value.is_class(expected)
			or (value.get_script() != null and value.get_script().get_global_name() == expected))
	if field.type != typeof(value):
		return false
	if field.hint == PROPERTY_HINT_ENUM:
		return _enum_values(field).has(value)
	return true


static func _enum_values(field: Dictionary) -> Array:
	var result: Array = []
	var next := 0
	for entry: String in String(field.hint_string).split(","):
		if field.type == TYPE_STRING:
			result.append(entry)
		else:
			if ":" in entry:
				next = entry.get_slice(":", 1).to_int()
			result.append(next)
			next += 1
	return result


static func _check_pair(values: Dictionary, defaults: Resource, issues: PackedStringArray) -> void:
	if not values.has("candidate"):
		return
	var broken := "candidate" in issues
	var params_broken := false
	for issue in issues:
		params_broken = params_broken or issue.begins_with("candidate_params")
	broken = broken or (params_broken and values.candidate != defaults.get("candidate"))
	if broken:
		values.candidate = defaults.get("candidate")
		if values.has("candidate_params"):
			values.candidate_params = copy_value(defaults.get("candidate_params"))


static func copy_value(value: Variant) -> Variant:
	if value is Curve or value is Gradient:
		return value.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
	if value is Resource:
		if "::" in value.resource_path or value.resource_path.is_empty():
			return copy_params(value)
		return value
	if value is Array:
		var copied: Array = value.duplicate()
		for index in range(copied.size()):
			copied[index] = copy_value(value[index])
		return copied
	if value is Dictionary:
		var copied: Dictionary = value.duplicate()
		for key: Variant in value:
			copied[key] = copy_value(value[key])
		return copied
	return value


static func copy_params(value: Resource) -> Resource:
	var copied := value.duplicate()
	for field in fields(value):
		copied.set(field.name, copy_value(value.get(field.name)))
	return copied


static func apply_fields(resource: Resource, values: Dictionary) -> void:
	var blocked := resource.is_blocking_signals()
	resource.set_block_signals(true)
	for key: Variant in values:
		resource.set(key, copy_value(values[key]))
	resource.set_block_signals(blocked)
	resource.emit_changed()


static func content(value: Variant) -> Variant:
	if value is Resource:
		return _resource_content(value)
	if value is Array or value is Dictionary:
		var output: Variant = []
		if value is Dictionary:
			output = {}
		for key: Variant in value:
			if output is Dictionary:
				output[key] = content(value[key])
			else:
				output.append(content(key))
		return output
	return value


static func _resource_content(value: Resource) -> Dictionary:
	var output: Dictionary = {"type": value.get_class()}
	var script := value.get_script() as Script
	if script != null:
		output.script = script.resource_path
	for field: Dictionary in value.get_property_list():
		if field.usage & PROPERTY_USAGE_STORAGE and field.name != "script":
			output[String(field.name)] = content(value.get(field.name))
	return output


static func slot_id_for(path: String) -> String:
	var parts := path.trim_prefix("res://game/").split("/tuning/")
	return parts[0] + "/" + parts[1].trim_suffix(".tres")


static func path_for_slot(identity: String) -> String:
	var target := identity.get_slice("/", 0)
	return "res://game/" + target + "/tuning/" + identity.trim_prefix(target + "/") + ".tres"
