extends RefCounted
## Formats the parameter changes shown before adopting a candidate.

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Controls := preload("res://dev/debug/_shared/property_controls.gd")


## The parameters adoption changes in the game file, one line each: "　　尺寸：1 → 1.5".
## A changed implementation is named by the slot's own line, not repeated here.
static func changes(slot: Slot) -> PackedStringArray:
	var defaults := slot.disk_defaults()
	if defaults == null:
		return []
	var saved := Codec.pack_fields(defaults)
	var now := Codec.pack_fields(slot.live)
	if saved.error != OK or now.error != OK:
		return []
	var lines: PackedStringArray = []
	var changed := Slot.differences(Codec.content(now.value), Codec.content(saved.value))
	for path in changed:
		if path == "candidate" or path == "candidate_params":
			continue
		var old_target := _field_resource(defaults, path)
		var new_target := _field_resource(slot.live, path)
		for field in Codec.fields(new_target):
			if field.name == path.get_file():
				lines.append(_change_line(slot, field, old_target.get(field.name),
					new_target.get(field.name)))
	if "candidate" in changed:
		lines.append_array(_switched_parameters(slot, defaults))
	return lines


static func _switched_parameters(slot: Slot, defaults: Resource) -> PackedStringArray:
	var old_params := defaults.get("candidate_params") as Resource
	var new_params := slot.live.get("candidate_params") as Resource
	if new_params == null:
		return [] # Audio and other candidates without parameters.
	var comparable: bool = old_params != null and old_params.get_script() == new_params.get_script()
	var old_fields: Dictionary = Codec.content(Codec.pack_fields(old_params).value) \
		if comparable else {}
	var new_fields: Dictionary = Codec.content(Codec.pack_fields(new_params).value)
	var lines: PackedStringArray = []
	for field in Codec.fields(new_params):
		var value: Variant = new_params.get(field.name)
		if not comparable:
			lines.append("　　待采纳参数：%s %s" % [slot.field_caption(field.name,
				String(field.name).capitalize()), _shown_value(slot, field, value)])
		elif new_fields[field.name] != old_fields[field.name]:
			lines.append(_change_line(slot, field, old_params.get(field.name), value))
	return lines


static func _field_resource(resource: Resource, path: String) -> Resource:
	return resource.get("candidate_params") as Resource if "/" in path else resource


static func _change_line(slot: Slot, field: Dictionary, before: Variant, after: Variant) -> String:
	var caption := slot.field_caption(field.name, String(field.name).capitalize())
	if after is Curve or after is Gradient:
		return "　　%s：已修改，前后对比请在调试台查看" % caption
	var old_text := _shown_value(slot, field, before)
	var new_text := _shown_value(slot, field, after)
	return "　　%s：%s → %s" % [caption, old_text, new_text] if not old_text.is_empty() \
		and not new_text.is_empty() else "　　%s 已修改" % caption


static func _shown_value(slot: Slot, field: Dictionary, value: Variant) -> String:
	var shown := slot.value_text(field.name, value)
	if not shown.is_empty():
		return shown
	if value is float or value is int:
		return Controls.numeric_text(field, value)
	if value is Vector2:
		return "X %s，Y %s" % [Controls.component_text(value.x), Controls.component_text(value.y)]
	if value is Curve or value is Gradient:
		return "前后对比请在调试台查看"
	return Slot.plain_text(value)
