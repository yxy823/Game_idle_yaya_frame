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
const Commands := preload("res://dev/debug/_shared/preset_commands.gd")
const ErrorAssert := preload("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd")
const Fixture := preload("res://dev/debug/_shared/tests/fixtures/adoption_fixture.gd")

const SaveThenFail := preload("res://dev/debug/_shared/tests/fixtures/save_then_fail_store.gd")

var _directory: String
var _store: Store
var _slot: Slot
var _uid: int = ResourceUID.INVALID_ID
var _fixture: Fixture


func before_test() -> void:
	_fixture = Fixture.new()
	_directory = "user://tests/debug-store-%d" % Time.get_ticks_usec()
	assert_int(DirAccess.make_dir_recursive_absolute(_directory)).is_equal(OK)
	var path := _directory.path_join("defaults.tres")
	assert_int(ResourceSaver.save(Params.new(), path)).is_equal(OK)
	_store = Store.new()
	_store.root = _directory
	_slot = Slot.new()
	assert_int(_slot.configure("sample", "sample", path, _directory)).is_equal(OK)


func after_test() -> void:
	_fixture.cleanup()
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
	_slot.target_id = "shared"
	_slot.id = "shared/sample"
	_store.save_slot(_slot, "bright")
	_store.save_combo("sample", "sample-combo", [_slot])
	_store.save_combo("shop", "shop-combo", [_slot])
	assert_int(_store.references(_slot.id, "bright").paths.size()).is_equal(2)
	assert_int(_store.delete_slot(_slot.id, "bright").error).is_equal(OK)
	var combo := ResourceLoader.load(_store.combo_path("shop", "shop-combo"), "",
		ResourceLoader.CACHE_MODE_IGNORE) as Combo
	assert_str(combo.entries[_slot.id]).is_empty()
	assert_bool(FileAccess.file_exists(_store.preset_path(_slot.id, "bright"))).is_false()


## A combo file that cannot be read stops saving a preset another combo may use.
func test_saving_stops_when_a_combo_cannot_be_read() -> void:
	_slot.live.count = 4
	assert_int(_store.save_slot(_slot, "bright").error).is_equal(OK)
	assert_int(_store.save_combo("sample", "uses-bright", [_slot]).error).is_equal(OK)
	assert_int(ResourceSaver.save(Curve.new(), _store.combo_path("sample", "broken"))).is_equal(OK)
	_slot.live.count = 9
	var reports: Array[Dictionary] = []
	var commands := Commands.new(_session(), null, func(result: Dictionary) -> void:
		reports.append(result), func() -> void: pass)
	commands.save_preset(_slot, "保存")
	var slots: Array[Slot] = [_slot]
	assert_bool(commands.save_dirty(slots, "关闭前").ok).is_false()
	assert_int(reports.size()).is_equal(2)
	for result in reports:
		assert_str(result.text).is_equal("没能检查哪些组合用到这个预设：文件内容和当前参数对不上。"
			+ "有组合文件读不出来，预设和当前改动都没有变。请让 Agent 检查")
	var stored := ResourceLoader.load(_store.preset_path(_slot.id, "bright"), "",
		ResourceLoader.CACHE_MODE_IGNORE) as Preset
	assert_int(stored.fields.count).is_equal(4)
	assert_bool(_slot.is_dirty()).is_true()


func test_failed_preset_delete_puts_the_combos_back() -> void:
	assert_int(_store.save_slot(_slot, "bright").error).is_equal(OK)
	assert_int(_store.save_combo("sample", "first", [_slot]).error).is_equal(OK)
	assert_int(_store.save_combo("sample", "second", [_slot]).error).is_equal(OK)
	var preset := _store.preset_path(_slot.id, "bright")
	# A read-only file cannot be deleted on Windows.
	assert_int(FileAccess.set_read_only_attribute(preset, true)).is_equal(OK)
	var result := _store.delete_slot(_slot.id, "bright")
	assert_int(FileAccess.set_read_only_attribute(preset, false)).is_equal(OK)
	assert_int(result.error).is_not_equal(OK)
	assert_bool(result.has("unrestored")).is_false()
	assert_bool(FileAccess.file_exists(preset)).is_true()
	for combo_name: String in ["first", "second"]:
		var combo := ResourceLoader.load(_store.combo_path("sample", combo_name), "",
			ResourceLoader.CACHE_MODE_IGNORE) as Combo
		assert_str(combo.entries[_slot.id]).is_equal(_slot.id + "#bright")


func test_current_combo_is_restored_after_save_then_uid_failure(restore_fails: bool,
		_test_parameters := [[false], [true]]) -> void:
	assert_int(_store.save_slot(_slot, "bright").error).is_equal(OK)
	assert_int(_store.save_combo("sample", "uses-bright", [_slot]).error).is_equal(OK)
	var failing := SaveThenFail.new()
	failing.root = _store.root
	failing.fail_restore = restore_fails
	_store = failing
	var reports: Array[Dictionary] = []
	var commands := Commands.new(_session(), null, reports.append, func() -> void: pass)
	commands._delete_preset(_slot)
	assert_int(failing.result.error).is_equal(ERR_FILE_CANT_WRITE)
	assert_str(failing.saved_entries[_slot.id]).is_empty()
	assert_bool(FileAccess.file_exists(_store.preset_path(_slot.id, "bright"))).is_true()
	var path := _store.combo_path("sample", "uses-bright")
	var combo := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Combo
	if restore_fails:
		assert_array(failing.result.unrestored).contains_exactly([path])
		assert_str(combo.entries[_slot.id]).is_empty()
		assert_str(reports[0].text).contains("没能确认组合“uses-bright”保持原样")
	else:
		assert_bool(failing.result.has("unrestored")).is_false()
		assert_str(combo.entries[_slot.id]).is_equal(_slot.id + "#bright")
		assert_str(reports[0].text).contains("预设和用到它的组合都没有变")


## Missing presets, changed field types and unreadable combos show game values and are named;
## they never count as "the same".
func test_compare_names_the_items_it_could_not_read() -> void:
	var session := _session()
	_slot.live.count = 5
	assert_int(_store.save_slot(_slot, "five").error).is_equal(OK)
	assert_int(_store.save_combo("sample", "five-combo", [_slot]).error).is_equal(OK)
	assert_int(DirAccess.remove_absolute(_store.preset_path(_slot.id, "five"))).is_equal(OK)
	var preset := Preset.new()
	preset.slot_id = _slot.id
	preset.fields = Codec.pack_fields(_slot.live).value
	preset.fields.count = "five"
	assert_int(ResourceSaver.save(preset, _store.preset_path(_slot.id, "typed"))).is_equal(OK)
	_store.load_slot(_slot, "typed")
	assert_int(_store.save_combo("sample", "typed-combo", [_slot]).error).is_equal(OK)
	assert_int(ResourceSaver.save(Curve.new(), _store.combo_path("sample", "broken"))).is_equal(OK)
	_slot.live.count = 7
	for combo_name: String in ["five-combo", "typed-combo"]:
		session.choose_compare(combo_name, false)
		assert_int(session.compare_differences()).is_equal(1)
		assert_str(session.toggle_compare(false).text).is_equal("正在显示：组合 %s（只读，按 ` 回到当前改动）"
			% combo_name + "；其中 1 项读不出来，按游戏原值比较")
		assert_int(_slot.live.count).is_equal(3)
		session.toggle_compare(false)
		assert_int(_slot.live.count).is_equal(7)
	_slot.live.count = 3
	session.choose_compare("broken", false)
	assert_str(session.toggle_compare(false).text).is_equal(
		"当前设定和组合 broken完全相同；其中 1 项读不出来，按游戏原值比较")


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
	var slot := _fixture.sound_slot()
	assert_int(Writer.preflight([slot]).error).is_equal(OK)
	slot.game_path = _fixture.root.path_join("outside-tuning.tres")
	var checked := Writer.preflight([slot])
	assert_int(checked.error).is_equal(ERR_INVALID_DATA)
	assert_array(checked.issues).contains_exactly([
		"Not a game tuning resource: " + slot.game_path])


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
