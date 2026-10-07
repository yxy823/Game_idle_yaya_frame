extends GdUnitTestSuite

const Store := preload("res://dev/debug/_shared/preset_store.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Preset := preload("res://dev/debug/_shared/slot_preset.gd")
const Combo := preload("res://dev/debug/_shared/target_combo.gd")
const Writer := preload("res://dev/debug/_shared/default_writer.gd")
const Params := preload("res://dev/debug/_shared/tests/fixtures/params.gd")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Target := preload("res://dev/debug/_shared/debug_target.gd")
const ErrorAssert := preload("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd")

var _directory: String
var _store: Store
var _slot: Slot
var _uid: int = ResourceUID.INVALID_ID


func before_test() -> void:
	_directory = "user://tests/debug-store-%d" % Time.get_ticks_usec()
	assert_int(DirAccess.make_dir_recursive_absolute(_directory)).is_equal(OK)
	var path := _directory.path_join("defaults.tres")
	assert_int(ResourceSaver.save(Params.new(), path)).is_equal(OK)
	_store = Store.new()
	_store.root = _directory
	_slot = Slot.new()
	assert_int(_slot.configure("sample", "sample", path, _directory)).is_equal(OK)


func after_test() -> void:
	_slot = null
	if _uid != ResourceUID.INVALID_ID:
		ResourceUID.remove_id(_uid)
		_uid = ResourceUID.INVALID_ID
	_remove(_directory)


func test_save_load_keeps_live_instance_and_restores_disk_defaults() -> void:
	var live := _slot.live
	_slot.live.count = 17
	assert_bool(_slot.is_dirty()).is_true()
	assert_int(_store.save_slot(_slot, "round-trip").error).is_equal(OK)
	assert_bool(_slot.is_dirty()).is_false()
	assert_int(_store.load_slot(_slot, "").error).is_equal(OK)
	assert_int(_slot.live.count).is_equal(3)
	assert_int(_store.load_slot(_slot, "round-trip").error).is_equal(OK)
	assert_int(_slot.live.count).is_equal(17)
	assert_bool(_slot.live == live).is_true()


func test_saved_curve_and_gradient_are_embedded_and_isolated() -> void:
	_slot.live.curve.add_point(Vector2.ONE)
	assert_int(_store.save_slot(_slot, "curve").error).is_equal(OK)
	var path := _store.preset_path(_slot.id, "curve")
	var text := FileAccess.get_file_as_string(path)
	assert_str(text).contains("[sub_resource type=\"Curve\"")
	assert_str(text).contains("[sub_resource type=\"Gradient\"")
	var cached := ResourceLoader.load(path) as Preset
	_slot.live.curve.set_point_value(0, 0.25)
	assert_float(cached.fields.curve.get_point_position(0).y).is_equal(1.0)
	assert_int(_store.load_slot(_slot, "curve").error).is_equal(OK)
	assert_bool(_slot.is_dirty()).is_false()


func test_save_failure_keeps_selection_values_and_dirty_marker() -> void:
	assert_int(_store.save_slot(_slot, "saved").error).is_equal(OK)
	_slot.live.count = 23
	var blocker := _directory.path_join("not-directory")
	var file := FileAccess.open(blocker, FileAccess.WRITE)
	file.close()
	_store.root = blocker
	var results: Array[Dictionary] = []
	var failure := assert_error(func() -> void:
		results.append(_store.save_slot(_slot, "new"))) as ErrorAssert
	await failure.is_push_error("Method/function failed. Returning: err")
	assert_int(results[0].error).is_not_equal(OK)
	assert_str(_slot.preset_name).is_equal("saved")
	assert_int(_slot.live.count).is_equal(23)
	assert_bool(_slot.is_dirty()).is_true()


func test_missing_preset_and_schema_fields_fall_back_and_report() -> void:
	var checked := _store.load_slot(_slot, "missing")
	assert_int(checked.error).is_equal(OK)
	assert_int(checked.issues.size()).is_equal(1)
	assert_str(_slot.preset_name).is_empty()
	var preset := Preset.new()
	preset.slot_id = _slot.id
	preset.fields = {"deleted_name": 5}
	var path := _store.preset_path(_slot.id, "old")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	ResourceSaver.save(preset, path)
	checked = _store.load_slot(_slot, "old")
	assert_bool(checked.issues.has("deleted_name")).is_true()
	assert_bool(checked.issues.has("count")).is_true()
	assert_int(_slot.live.count).is_equal(3)


func test_combo_references_presets_and_missing_items_use_game_values() -> void:
	_slot.live.count = 13
	_store.save_slot(_slot, "thirteen")
	assert_int(_store.save_combo("sample", "combo", [_slot]).error).is_equal(OK)
	var checked := _store.check_combo("sample", "combo", [_slot])
	assert_int(checked.values[_slot.id].count).is_equal(13)
	var combo := ResourceLoader.load(_store.combo_path("sample", "combo"), "",
		ResourceLoader.CACHE_MODE_IGNORE) as Combo
	combo.target_id = "shop"
	assert_int(ResourceSaver.save(combo, _store.combo_path("sample", "combo"))).is_equal(OK)
	checked = _store.check_combo("sample", "combo", [_slot])
	assert_int(checked.values[_slot.id].count).is_equal(3)
	assert_int(checked.issues.size()).is_equal(1)
	combo.target_id = "sample"
	assert_int(ResourceSaver.save(combo, _store.combo_path("sample", "combo"))).is_equal(OK)
	DirAccess.remove_absolute(_store.preset_path(_slot.id, "thirteen"))
	checked = _store.check_combo("sample", "combo", [_slot])
	assert_int(checked.values[_slot.id].count).is_equal(3)
	assert_int(checked.issues.size()).is_equal(1)
	assert_int(_store.check_combo("sample", "missing", [_slot]).issues.size()).is_equal(1)


func test_combo_refuses_unsaved_slot_edits() -> void:
	_slot.live.count = 99
	assert_int(_store.save_combo("sample", "combo", [_slot]).error).is_equal(ERR_INVALID_DATA)
	assert_bool(FileAccess.file_exists(_store.combo_path("sample", "combo"))).is_false()


func test_delete_lists_cross_target_references_and_changes_them_to_game_values() -> void:
	_slot.target_id = "global"
	_slot.id = "global/sample"
	_store.save_slot(_slot, "shared")
	_store.save_combo("sample", "sample-combo", [_slot])
	_store.save_combo("shop", "shop-combo", [_slot])
	assert_int(_store.references(_slot.id, "shared").paths.size()).is_equal(2)
	assert_int(_store.delete_slot(_slot.id, "shared").error).is_equal(OK)
	var combo := ResourceLoader.load(_store.combo_path("shop", "shop-combo"), "",
		ResourceLoader.CACHE_MODE_IGNORE) as Combo
	assert_str(combo.entries[_slot.id]).is_empty()
	assert_bool(FileAccess.file_exists(_store.preset_path(_slot.id, "shared"))).is_false()


func test_default_writer_keeps_uid_and_serializes_subresources() -> void:
	var identity := ResourceUID.create_id()
	assert_int(ResourceSaver.set_uid(ProjectSettings.globalize_path(_slot.game_path), identity)).is_equal(OK)
	_uid = identity
	ResourceUID.add_id(identity, _slot.game_path)
	_slot.live.curve.add_point(Vector2.ONE)
	_slot.live.count = 42
	assert_int(Writer.write_resource(_slot.live, _slot.game_path)).is_equal(OK)
	assert_int(ResourceLoader.get_resource_uid(_slot.game_path)).is_equal(identity)
	assert_str(FileAccess.get_file_as_string(_slot.game_path)).contains(
		'uid="%s"' % ResourceUID.id_to_text(identity))
	var disk := _slot.disk_defaults()
	assert_int(disk.count).is_equal(42)
	assert_int(disk.curve.point_count).is_equal(1)


func test_names_reject_path_escape_and_preflight_rejects_non_game_destination() -> void:
	for invalid: String in ["", "../escape", "a/b", " name", "a#b"]:
		assert_bool(Store.valid_name(invalid)).is_false()
	assert_int(Writer.preflight([_slot]).error).is_not_equal(OK)


func test_default_writer_embeds_current_external_candidate_parameters() -> void:
	var sample := "res://dev/debug/_shared/tests/fixtures/sample/game/sample/"
	var params: Resource = (load(sample + "feedback/effect/ring/ring_params.gd") as Script).new()
	params.size = 77.0
	var params_path := _directory.path_join("external-params.tres")
	ResourceSaver.save(params, params_path)
	var config: Resource = (load(sample + "tuning/feedback/effect_tuning.gd") as Script).new()
	config.candidate_params = ResourceLoader.load(params_path)
	var path := _directory.path_join("vfx.tres")
	ResourceSaver.save(config, path)
	config.candidate_params.size = 160.0
	assert_int(Writer.write_resource(config, path)).is_equal(OK)
	var disk := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_float(disk.candidate_params.size).is_equal(160.0)
	assert_bool("::" in disk.candidate_params.resource_path).is_true()
	assert_float(ResourceLoader.load(params_path, "", ResourceLoader.CACHE_MODE_IGNORE).size).is_equal(77.0)


func test_modified_fields_follow_the_saved_state_and_revert_one_field() -> void:
	assert_array(_slot.modified_fields()).is_empty()
	_slot.live.count = 8
	_slot.live.weight = 1.5
	assert_array(_slot.modified_fields()).contains_exactly_in_any_order(["count", "weight"])
	assert_int(_slot.saved_value("count")).is_equal(3)
	assert_int(_slot.revert_field("count").error).is_equal(OK)
	assert_int(_slot.live.count).is_equal(3)
	assert_array(_slot.modified_fields()).contains_exactly(["weight"])
	assert_int(_store.save_slot(_slot, "light").error).is_equal(OK)
	assert_array(_slot.modified_fields()).is_empty()
	assert_float(_slot.saved_value("weight")).is_equal(1.5)


func test_differences_split_parameters_unless_the_candidate_changed() -> void:
	var saved := {"candidate": "uid://a", "candidate_params": {"script_uid": "uid://p",
		"fields": {"size": 1.0, "fps": 30.0}}, "volume": 0.0}
	var current := saved.duplicate(true)
	current.candidate_params.fields.size = 2.0
	current.volume = -3.0
	assert_array(Slot.differences(current, saved)).contains_exactly_in_any_order(
		["candidate_params/size", "volume"])
	current.candidate = "uid://b"
	current.volume = 0.0
	assert_array(Slot.differences(current, saved)).contains_exactly(["candidate"])


func test_compare_shows_game_values_read_only_and_restores_the_edits() -> void:
	var session := _session()
	assert_str(session.toggle_compare(false).text).is_equal("还没有改动可对比")
	assert_bool(session.comparing).is_false()
	_slot.live.count = 11
	_slot.live.weight = 4.0
	assert_int(session.compare_differences()).is_equal(2)
	assert_str(session.toggle_compare(false).text).contains("正在显示：游戏原值")
	assert_bool(session.comparing).is_true()
	assert_int(_slot.live.count).is_equal(3)
	assert_bool(session.slot_dirty(_slot)).is_true()
	assert_int(session.dirty_count()).is_equal(1)
	assert_int(session.compare_differences()).is_equal(2)
	assert_str(session.toggle_compare(false).text).is_equal("正在显示：当前改动")
	assert_int(_slot.live.count).is_equal(11)
	assert_float(_slot.live.weight).is_equal(4.0)
	assert_bool(_slot.is_dirty()).is_true()
	assert_array(_slot.modified_fields()).contains_exactly_in_any_order(["count", "weight"])


func test_compare_with_a_combo_waits_for_the_next_pass_while_locked() -> void:
	var session := _session()
	_slot.live.count = 5
	_store.save_slot(_slot, "five")
	assert_int(_store.save_combo("sample", "five-combo", [_slot]).error).is_equal(OK)
	assert_int(_store.load_slot(_slot, "").error).is_equal(OK)
	assert_str(session.choose_compare("five-combo", true).text).is_equal("对比对象改为组合 five-combo")
	assert_int(session.compare_differences()).is_equal(1)
	assert_str(session.toggle_compare(true).text).is_equal("下一遍开头切到组合 five-combo")
	assert_int(_slot.live.count).is_equal(3)
	session.apply_pending_compare()
	assert_int(_slot.live.count).is_equal(5)
	session.choose_compare("", true)
	assert_int(_slot.live.count).is_equal(5)
	session.apply_pending_compare()
	assert_int(_slot.live.count).is_equal(3)
	assert_str(session.toggle_compare(true).text).is_equal("下一遍开头切到当前改动")
	assert_str(session.toggle_compare(true).text).is_equal("已取消下一遍的切换")
	assert_bool(session.comparing).is_true()


func _session() -> Session:
	var session := Session.new()
	session.store = _store
	session.active = Target.new()
	session.active.id = "sample"
	session.slots = [_slot]
	session.selected = _slot
	return session


func _remove(directory: String) -> void:
	for child in DirAccess.get_directories_at(directory):
		_remove(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		assert_int(DirAccess.remove_absolute(directory.path_join(file))).is_equal(OK)
	assert_int(DirAccess.remove_absolute(directory)).is_equal(OK)
