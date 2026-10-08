extends GdUnitTestSuite

const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Guard := preload("res://dev/debug/_shared/reference_guard.gd")
const Params := preload("res://dev/debug/_shared/tests/fixtures/params.gd")
const EFFECT := "res://dev/debug/_shared/tests/fixtures/sample/game/sample/tuning/feedback/effect.tres"
const TEXTURE := "res://dev/debug/_shared/icons/check.svg"


func test_storage_fields_include_hidden_and_exclude_ordinary() -> void:
	var result := Codec.pack_fields(Params.new())
	assert_int(result.error).is_equal(OK)
	assert_bool(result.value.has("stored_only")).is_true()
	assert_bool(result.value.has("ordinary_member")).is_false()
	assert_int(result.value.huge).is_equal(9223372036854775800)


func test_all_scalar_values_null_arrays_and_dictionaries_round_trip() -> void:
	var params := Params.new()
	params.sequence = [null, 9223372036854775800, Color.RED, Vector2(2, 5)]
	params.mapping = {"enabled": false, 3: ["nested", null]}
	var packed := Codec.pack_fields(params)
	var checked := Codec.check_fields(params, packed.value, Params.new())
	assert_array(checked.issues).is_empty()
	var restored := Params.new()
	Codec.apply_fields(restored, checked.values)
	assert_that(Codec.content(restored)).is_equal(Codec.content(params))


func test_curve_gradient_are_internal_copies_and_dirty_compares_content() -> void:
	var params := Params.new()
	params.curve.add_point(Vector2.ZERO)
	params.curve.add_point(Vector2.ONE)
	var packed := Codec.pack_fields(params)
	assert_bool(packed.value.curve == params.curve).is_false()
	assert_bool(packed.value.gradient == params.gradient).is_false()
	assert_that(Codec.content(packed.value.curve)).is_equal(Codec.content(params.curve))
	packed.value.curve.set_point_value(1, 0.5)
	assert_float(params.curve.get_point_position(1).y).is_equal(1.0)


func test_external_resources_are_uid_strings_even_inside_containers() -> void:
	var params := Params.new()
	params.texture = ResourceLoader.load(TEXTURE)
	params.sequence = [params.texture]
	params.mapping = {"texture": params.texture}
	params.typed_sequence = [params.texture]
	params.typed_mapping = {"texture": params.texture}
	var packed := Codec.pack_fields(params)
	assert_str(packed.value.texture).starts_with("uid://")
	assert_str(packed.value.sequence[0]).is_equal(packed.value.texture)
	assert_str(packed.value.mapping.texture).is_equal(packed.value.texture)
	assert_bool(Codec.decode(packed.value.texture).value == params.texture).is_true()
	var restored := Params.new()
	var checked := Codec.check_fields(restored, packed.value, restored)
	assert_array(checked.issues).is_empty()
	Codec.apply_fields(restored, checked.values)
	assert_bool(restored.typed_sequence[0] == params.texture).is_true()
	assert_bool(restored.typed_mapping.texture == params.texture).is_true()
	var copied: Resource = Codec.copy_value(params)
	assert_bool(copied.typed_sequence[0] == params.texture).is_true()
	assert_int(Codec.pack_fields(copied).error).is_equal(OK)


func test_changed_typed_container_elements_fall_back_without_assignment_errors() -> void:
	var params := Params.new()
	var packed := Codec.pack_fields(params)
	packed.value.typed_sequence = ["not a resource"]
	packed.value.typed_mapping = {5: "wrong key and value"}
	var checked := Codec.check_fields(params, packed.value, params)
	assert_array(checked.issues).contains_exactly(["typed_sequence", "typed_mapping"])
	Codec.apply_fields(params, checked.values)
	assert_array(params.typed_sequence).is_empty()
	assert_dict(params.typed_mapping).is_empty()


func test_renamed_deleted_missing_and_changed_type_fields_are_reported() -> void:
	var params := Params.new()
	var packed := Codec.pack_fields(params)
	packed.value.erase("count")
	packed.value.old_count = 9
	packed.value.weight = "wrong"
	packed.value.mode = 999
	var checked := Codec.check_fields(params, packed.value, params)
	assert_array(checked.issues).contains_exactly(["count", "weight", "mode", "old_count"])
	assert_int(checked.values.count).is_equal(3)
	assert_float(checked.values.weight).is_equal(-2.5)


func test_missing_candidate_falls_back_as_one_candidate_parameter_pair() -> void:
	var defaults := ResourceLoader.load(EFFECT, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	var packed := Codec.pack_fields(defaults)
	packed.value.candidate = "uid://missing"
	packed.value.candidate_params.fields.size = 999.0
	var checked := Codec.check_fields(defaults, packed.value, defaults)
	assert_array(checked.issues).contains(["candidate"])
	assert_bool(checked.values.candidate == defaults.candidate).is_true()
	assert_float(checked.values.candidate_params.size).is_equal(defaults.candidate_params.size)


func test_missing_parameter_script_and_missing_uid_are_explicit_failures() -> void:
	assert_int(Codec.decode({"script_uid": "uid://missing", "fields": {}}).error).is_not_equal(OK)
	assert_int(Codec.decode("uid://missing").error).is_equal(ERR_FILE_NOT_FOUND)
	var uid := ResourceLoader.get_resource_uid("res://dev/debug/_shared/tests/fixtures/editor_stub.gd")
	assert_int(Codec.decode({"script_uid": ResourceUID.id_to_text(uid), "fields": {}}).error).is_not_equal(OK)


## Plain values that look like references come back unchanged, also as keys and nested.
func test_values_shaped_like_references_round_trip_as_plain_values() -> void:
	for plain: Variant in ["uid://label", {"slot_id": "display-choice"}, {"literal": "uid://x"},
			{"script_uid": "uid://p", "fields": {}}, ["uid://in-array", {"slot_id": 1}]]:
		var encoded := Codec.encode(plain)
		assert_int(encoded.error).is_equal(OK)
		assert_that(Codec.decode(encoded.value).value).is_equal(plain)
	var params := Params.new()
	params.mapping = {"uid://key": {"nested": [{"slot_id": "a/b"}, "uid://value"]}}
	params.sequence = [{"literal": {"slot_id": "x"}}]
	var packed := Codec.pack_fields(params)
	var checked := Codec.check_fields(params, packed.value, Params.new())
	assert_array(checked.issues).is_empty()
	assert_that(checked.values.mapping).is_equal(params.mapping)
	assert_that(checked.values.sequence).is_equal(params.sequence)


## Links between tuning resources are stored by slot id, which maps back to the same path.
func test_tuning_paths_and_slot_ids_map_both_ways() -> void:
	var path := "res://game/shop/tuning/feedback/sound.tres"
	assert_str(Codec.slot_id_for(path)).is_equal("shop/feedback/sound")
	assert_str(Codec.path_for_slot("shop/feedback/sound")).is_equal(path)


func test_dev_paths_uid_scripts_and_nested_dependencies_are_rejected() -> void:
	assert_int(Guard.check("res://game/../dev/debug/debug_main.tscn").error).is_not_equal(OK)
	var uid := ResourceLoader.get_resource_uid("res://dev/debug/_shared/tests/fixtures/params.gd")
	assert_int(Guard.check({"nested": [ResourceUID.id_to_text(uid)]}).error).is_not_equal(OK)
	assert_int(Guard.check(Params.new()).error).is_not_equal(OK)
	assert_int(Guard.check(Curve.new()).error).is_equal(OK)
