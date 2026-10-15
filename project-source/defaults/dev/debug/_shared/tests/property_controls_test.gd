extends GdUnitTestSuite

const Controls := preload("res://dev/debug/_shared/property_controls.gd")
const Params := preload("res://dev/debug/_shared/tests/fixtures/params.gd")
const Stub := preload("res://dev/debug/_shared/tests/fixtures/editor_stub.gd")

var _described: Array = []


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
	var found: PackedStringArray = []
	for field in Controls.fields(params):
		if field.name == "count":
			found.append("count")
			var input := auto_free(Controls.create(field, 3, values.append)) as LineEdit
			input.text_changed.emit("9223372036854775800")
		if field.name == "ranged_float":
			found.append("ranged_float")
			var row := auto_free(Controls.create(field, 1.0, values.append)) as HBoxContainer
			assert_float((row.get_child(1) as SpinBox).step).is_equal(0.01)
	assert_array(found).contains_exactly_in_any_order(["count", "ranged_float"])
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


func test_named_values_come_first_then_the_described_text_then_the_number() -> void:
	var params := Params.new()
	var editors: Dictionary[String, Callable] = {}
	_described.clear()
	for field in Controls.fields(params):
		if field.name != "ranged_int":
			continue
		var row := auto_free(Controls.create(field, 4, _ignore, editors, {4: "四档"}, _rank)) \
			as HBoxContainer
		add_child(row)
		var number := row.get_child(1) as SpinBox
		await get_tree().process_frame
		assert_str(number.get_line_edit().text).is_equal("四档")
		number.value = 8
		await get_tree().process_frame
		assert_str(number.get_line_edit().text).is_equal("第 8 档")
		assert_int(typeof(_described.back())).is_equal(TYPE_INT)
		number.value = 6
		await get_tree().process_frame
		assert_str(number.get_line_edit().text).is_equal("6")
	assert_array(_described).not_contains([4])


func _ignore(_value: Variant) -> void:
	pass


## Names every value but 6, which keeps the default format.
func _rank(value: Variant) -> String:
	_described.append(value)
	return "" if value == 6 else "第 %d 档" % value


## value_text() writes what the box shows, so other places naming a value read the same.
func test_whole_float_reads_without_decimals_after_the_value_changes() -> void:
	var params := Params.new()
	for field in Controls.fields(params):
		if field.name != "ranged_float":
			continue
		var row := auto_free(Controls.create(field, 1.5, _ignore)) as HBoxContainer
		add_child(row)
		var number := row.get_child(1) as SpinBox
		await get_tree().process_frame
		assert_str(number.get_line_edit().text).is_equal("1.5 s")
		number.value = 2.0
		await get_tree().process_frame
		assert_str(number.get_line_edit().text).is_equal("2 s")
		assert_str(Controls.value_text(number, 1.5)).is_equal("1.5 s")
