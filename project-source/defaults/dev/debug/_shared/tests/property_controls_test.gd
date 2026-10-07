extends GdUnitTestSuite

const Controls := preload("res://dev/debug/_shared/property_controls.gd")
const Params := preload("res://dev/debug/_shared/tests/fixtures/params.gd")
const Stub := preload("res://dev/debug/_shared/tests/fixtures/editor_stub.gd")


func test_ranges_integer_float_color_bool_enum_and_vector_controls() -> void:
	var params := Params.new()
	var controls: Dictionary[String, Control] = {}
	for field in Controls.fields(params):
		var control := Controls.create(field, params.get(field.name), func(value: Variant) -> void:
			params.set(field.name, value))
		controls[field.name] = auto_free(control)
	assert_bool(controls.ranged_int is HBoxContainer).is_true()
	assert_bool(controls.count is LineEdit).is_true()
	assert_bool(controls.weight is SpinBox).is_true()
	assert_bool(controls.tint is ColorPickerButton).is_true()
	assert_bool(controls.enabled is CheckBox).is_true()
	assert_bool(controls.mode is OptionButton).is_true()
	assert_bool(controls.offset is HBoxContainer).is_true()
	assert_bool(controls.curve is Label).is_true()
	assert_bool(controls.has("stored_only")).is_false()


func test_integer_input_keeps_64_bit_and_float_input_is_finer_than_slider() -> void:
	var params := Params.new()
	var values: Array = []
	for field in Controls.fields(params):
		if field.name == "count":
			var input := auto_free(Controls.create(field, 3, values.append)) as LineEdit
			input.text_changed.emit("9223372036854775800")
		if field.name == "ranged_float":
			var row := auto_free(Controls.create(field, 1.0, values.append)) as HBoxContainer
			assert_float((row.get_child(1) as SpinBox).step).is_equal(0.01)
	assert_int(values[0]).is_equal(9223372036854775800)


func test_registered_editor_binds_same_resource_and_obeys_lock_contract() -> void:
	var params := Params.new()
	var editors: Dictionary[String, Callable] = {"Curve": func() -> Control: return Stub.new()}
	for field in Controls.fields(params):
		if field.name != "curve":
			continue
		var editor := auto_free(Controls.create(field, params.curve, func(_value: Variant) -> void:
			params.emit_changed(), editors)) as Stub
		assert_bool(editor.value == params.curve).is_true()
		Controls.set_locked(editor, true)
		assert_bool(editor.locked).is_true()
		Controls.set_locked(editor, false)
		assert_bool(editor.locked).is_false()
