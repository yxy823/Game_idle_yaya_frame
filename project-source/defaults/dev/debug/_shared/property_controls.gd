extends RefCounted

const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const COLUMN_GAP := 12
const VALUE_WIDTH := 72.0
const VALUE_HEIGHT := 24.0


static func fields(params: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var group := ""
	var prefix := ""
	for property: Dictionary in params.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_GROUP:
			group = property["name"]
			prefix = property["hint_string"]
			continue
		if usage & PROPERTY_USAGE_CATEGORY:
			group = ""
			prefix = ""
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_EDITOR:
			if not prefix.is_empty() and not String(property["name"]).begins_with(prefix):
				group = ""
				prefix = ""
			property["group"] = group
			property["caption"] = _caption(String(property["name"]).trim_prefix(prefix), group)
			result.append(property)
	return result


## Drops a leading word the group title already says, e.g. "Particle Count" under "Particles".
static func _caption(field_name: String, group: String) -> String:
	var words := field_name.capitalize().split(" ")
	if words.size() > 1 and group.to_lower().begins_with(words[0].to_lower()):
		words.remove_at(0)
	return " ".join(words)


## Value-only controls sit in the value column; everything else spans the control column.
static func layout(control: Control) -> Control:
	if not (control is LineEdit or control is SpinBox or control is ColorPickerButton):
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return control
	var cell := HBoxContainer.new()
	cell.add_theme_constant_override("separation", COLUMN_GAP)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_child(space)
	control.custom_minimum_size = Vector2(VALUE_WIDTH, VALUE_HEIGHT)
	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if control is LineEdit:
		control.theme_type_variation = &"ValueEdit"
		control.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cell.add_child(control)
	return cell


## `captions` names enum values and special numbers for people: {stored value: "中文"}.
## `describe(value) -> String` writes other values of a number box, "" for the default format.
static func create(property: Dictionary, value: Variant, changed: Callable,
		editors: Dictionary[String, Callable] = {}, captions: Dictionary = {},
		describe: Callable = Callable()) -> Control:
	var kind := String(property["hint_string"])
	if value is Resource:
		kind = value.get_class()
	if editors.has(kind):
		var editor: Control = editors[kind].call()
		editor.bind(value, changed)
		return editor
	if property["hint"] == PROPERTY_HINT_ENUM:
		return _enum_control(property, value, changed, captions)
	match property["type"]:
		TYPE_INT, TYPE_FLOAT:
			if property["hint"] == PROPERTY_HINT_RANGE:
				return _range_control(property, value, changed, captions, describe)
			if property["type"] == TYPE_INT:
				var integer := LineEdit.new()
				integer.text = str(value)
				integer.text_changed.connect(func(text: String) -> void:
					if text.is_valid_int():
						changed.call(text.to_int()))
				return integer
			var number := _number(float(value))
			_name_values(number, captions, describe, false)
			number.value_changed.connect(changed)
			return number
		TYPE_COLOR:
			var picker := ColorPickerButton.new()
			picker.color = value
			picker.color_changed.connect(changed)
			return picker
		TYPE_BOOL:
			var toggle := CheckBox.new()
			toggle.button_pressed = value
			toggle.toggled.connect(changed)
			return toggle
		TYPE_VECTOR2:
			return _vector_control(value, changed)
	return _readonly(property)


static func _number(value: float) -> SpinBox:
	var number := SpinBox.new()
	number.allow_greater = true
	number.allow_lesser = true
	number.step = 0.01
	number.set_value_no_signal(value)
	number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	number.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.get_line_edit().theme_type_variation = &"ValueEdit"
	number.custom_minimum_size = Vector2(VALUE_WIDTH, VALUE_HEIGHT)
	# Arrow buttons crowd a narrow value box; dragging the slider or typing is enough.
	number.add_theme_constant_override("buttons_width", 0)
	for icon: StringName in [&"updown", &"up", &"down", &"up_hover", &"down_hover",
			&"up_pressed", &"down_pressed", &"up_disabled", &"down_disabled"]:
		number.add_theme_icon_override(icon, ImageTexture.new())
	number.value_changed.connect(func(_next: float) -> void: tidy_later(number))
	number.get_line_edit().focus_exited.connect(tidy_later.bind(number))
	tidy_later(number)
	return number


## SpinBox writes whole floats as "30.0 fps"; after it updates, show "30 fps" instead.
## SpinBox keeps a replaced text until its value changes again. A value change queues SpinBox's
## own text update after this call, so the tidy waits one more deferred step to come after it.
static func tidy_later(number: SpinBox) -> void:
	(func() -> void: (func() -> void: _tidy(number)).call_deferred()).call_deferred()


static func _tidy(number: SpinBox) -> void:
	var edit := number.get_line_edit() if is_instance_valid(number) else null
	if edit != null and not edit.has_focus():
		edit.text = value_text(number, number.value)


## How `number` writes `value`, in the box and wherever else that value is named: named special
## values first, then the slot's own wording, then the number with the box's prefix and suffix.
static func value_text(number: SpinBox, value: float) -> String:
	var whole := is_equal_approx(value, roundf(value))
	var captions: Dictionary = number.get_meta(&"captions", {})
	if whole and captions.has(roundi(value)):
		return String(captions[roundi(value)])
	var describe: Callable = number.get_meta(&"describe", Callable())
	if describe.is_valid():
		var stored: Variant = value
		if number.get_meta(&"integer", false):
			stored = roundi(value)
		var described := String(describe.call(stored))
		if not described.is_empty():
			return described
	var parts: PackedStringArray = [str(roundi(value)) if whole
		else String.num(value, step_decimals(number.step))]
	if not number.prefix.is_empty():
		parts.insert(0, number.prefix)
	if not number.suffix.is_empty():
		parts.append(number.suffix)
	return " ".join(parts)


## `captions` replaces special whole values in the box, for example {-1: "未设置"}.
static func _range_control(property: Dictionary, value: Variant, changed: Callable,
		captions: Dictionary, describe: Callable) -> Control:
	var hints := String(property["hint_string"]).split(",")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", COLUMN_GAP)
	var slider := HSlider.new()
	var number := _number(float(value))
	slider.min_value = hints[0].to_float()
	slider.max_value = hints[1].to_float()
	slider.step = hints[2].to_float() if hints.size() > 2 else 1.0
	slider.exp_edit = "exp" in hints
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.x = 40.0
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	number.size_flags_horizontal = Control.SIZE_FILL
	number.min_value = slider.min_value
	number.max_value = slider.max_value
	# The slider snaps to the page's step; typed values may be finer for floats.
	number.step = slider.step if property["type"] == TYPE_INT else minf(slider.step, 0.01)
	number.allow_greater = "or_greater" in hints
	number.allow_lesser = "or_less" in hints
	for hint: String in hints:
		if hint.begins_with("suffix:"):
			number.suffix = hint.trim_prefix("suffix:")
	number.set_value_no_signal(float(value))
	slider.set_value_no_signal(float(value))
	var integer: bool = property["type"] == TYPE_INT
	_name_values(number, captions, describe, integer)
	row.add_child(slider)
	row.add_child(number)
	slider.value_changed.connect(func(next: float) -> void:
		number.set_value_no_signal(next)
		tidy_later(number)
		_emit_number(next, integer, changed))
	number.value_changed.connect(func(next: float) -> void:
		slider.set_value_no_signal(next)
		_emit_number(next, integer, changed))
	return row


## Whole values named in `captions` show their name in the box, e.g. -1 as "未设置"; other
## values show what `describe` returns, e.g. MIDI 72 as "C5".
static func _name_values(number: SpinBox, captions: Dictionary, describe: Callable,
		integer: bool) -> void:
	number.set_meta(&"captions", captions)
	number.set_meta(&"describe", describe)
	number.set_meta(&"integer", integer)
	if not captions.is_empty() or describe.is_valid():
		tidy_later(number)


static func _emit_number(value: float, integer: bool, changed: Callable) -> void:
	var stored: Variant = value
	if integer:
		stored = int(value)
	changed.call(stored)


static func _enum_control(property: Dictionary, value: Variant, changed: Callable,
		captions: Dictionary) -> Control:
	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size.y = 28.0
	dropdown.focus_mode = Control.FOCUS_NONE
	var next_integer := 0
	var selected := -1
	for entry: String in String(property["hint_string"]).split(","):
		var caption := entry
		var stored: Variant = entry
		if property["type"] == TYPE_INT:
			var separator := entry.rfind(":")
			if separator >= 0:
				caption = entry.left(separator)
				next_integer = entry.substr(separator + 1).to_int()
			stored = next_integer
			next_integer += 1
		dropdown.add_item(String(captions.get(stored, caption)))
		var index := dropdown.item_count - 1
		dropdown.set_item_metadata(index, stored)
		if stored == value:
			selected = index
	dropdown.select(selected)
	dropdown.item_selected.connect(func(index: int) -> void:
		changed.call(dropdown.get_item_metadata(index)))
	return dropdown


static func _vector_control(value: Vector2, changed: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var horizontal := _number(value.x)
	var vertical := _number(value.y)
	horizontal.prefix = "X"
	vertical.prefix = "Y"
	row.add_child(horizontal)
	row.add_child(vertical)
	var update := func(_next: float) -> void:
		changed.call(Vector2(horizontal.value, vertical.value))
	horizontal.value_changed.connect(update)
	vertical.value_changed.connect(update)
	return row


static func _readonly(property: Dictionary) -> Control:
	var label := Label.new()
	var kind := String(property["hint_string"])
	var captions: Dictionary[String, String] = {
		"Curve": "曲线", "Gradient": "渐变", "Texture2D": "纹理",
	}
	label.text = "%s（只读）" % captions.get(kind, kind)
	label.theme_type_variation = "ReadonlyField"
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = label.text
	return label


## Locked buttons, dropdowns, check boxes, sliders and value boxes say `reason` when hovered.
static func set_locked(control: Node, locked: bool, reason: String = "") -> void:
	if control.has_method("set_locked"):
		control.set_locked(locked)
		return
	var editable := control is LineEdit or control is SpinBox or control is Slider
	if editable:
		control.editable = not locked
	if editable or control is BaseButton:
		Messages.explain(control, locked, reason)
	if control is SpinBox:
		# Its text field is internal, so get_children() skips it, but the pointer hovers there.
		Messages.explain(control.get_line_edit(), locked, reason)
	for child in control.get_children():
		set_locked(child, locked, reason)
