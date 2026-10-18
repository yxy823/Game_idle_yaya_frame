extends GdUnitTestSuite
## Failed saves keep actual written progress, the queue and follow-up log consistent.

const Fixture := preload("res://dev/debug/_shared/tests/fixtures/adoption_fixture.gd")
const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const Files := preload("res://dev/debug/_shared/adoption_files.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Request := preload("res://dev/debug/_shared/adoption_request.gd")
const Writer := preload("res://dev/debug/_shared/default_writer.gd")
const ErrorAssert := preload("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd")

var _fixture: Fixture


func before_test() -> void:
	_fixture = Fixture.new()


func after_test() -> void:
	_fixture.cleanup()


func test_queued_parameter_mismatch_keeps_game_bytes_queue_and_log_until_retry() -> void:
	var slot := _fixture.effect_slot()
	_fixture.select(slot, "spark")
	assert_int(Adoption.adopt_all([slot], Adoption.plans_for([slot])).error).is_equal(OK)
	var request := ResourceLoader.load(Files.queue_path(slot), "",
		ResourceLoader.CACHE_MODE_IGNORE) as Request
	var count: int = request.fields.candidate_params.fields.count
	request.fields.candidate_params.fields.count = "invalid"
	assert_int(ResourceSaver.save(request, Files.queue_path(slot))).is_equal(OK)
	var original := FileAccess.get_file_as_bytes(slot.game_path)
	var log_path := _fixture.dev_root().path_join(Files.LOG)
	var recorded := FileAccess.get_file_as_string(log_path)
	var result := Files.run_queue(_fixture.dev_root())
	assert_int(result.error).is_not_equal(OK)
	assert_array(result.done).is_empty()
	assert_str(result.detail).contains("candidate_params.count")
	assert_bool(FileAccess.get_file_as_bytes(slot.game_path) == original).is_true()
	assert_str(Files.queued_candidate(slot)).is_equal("spark")
	assert_str(FileAccess.get_file_as_string(log_path)).is_equal(recorded)
	request.fields.candidate_params.fields.count = count
	assert_int(ResourceSaver.save(request, Files.queue_path(slot))).is_equal(OK)
	assert_int(Files.run_queue(_fixture.dev_root()).error).is_equal(OK)
	assert_str(Files.queued_candidate(slot)).is_empty()


func test_immediate_dev_candidate_cancels_the_previous_queued_candidate() -> void:
	var slot := _fixture.sound_slot()
	assert_int(ResourceSaver.save(Curve.new(), slot.directory.path_join("chime/deferred.tres"))).is_equal(OK)
	_fixture.select(slot, "chime")
	assert_int(Adoption.adopt_all([slot], Adoption.plans_for([slot])).error).is_equal(OK)
	assert_str(Files.queued_candidate(slot)).is_equal("chime")
	_fixture.select(slot, "click")
	assert_int(Adoption.adopt_all([slot], Adoption.plans_for([slot])).error).is_equal(OK)
	assert_str(Files.queued_candidate(slot)).is_empty()
	assert_array(Files.run_queue(_fixture.dev_root()).done).is_empty()
	assert_str(slot.disk_defaults().candidate.resource_path).ends_with("/click/click.wav")


func test_partial_write_records_only_written_files_and_names_them() -> void:
	var sound := _fixture.sound_slot()
	var effect := _fixture.effect_slot()
	sound.live.volume_db = -2.0
	effect.live.candidate_params.size = 160.0
	var original := FileAccess.get_file_as_bytes(effect.game_path)
	assert_int(FileAccess.set_read_only_attribute(effect.game_path, true)).is_equal(OK)
	var results: Array[Dictionary] = []
	var attempt := func() -> void: results.append(Adoption.adopt_all([sound, effect], {}))
	await (assert_error(attempt) as ErrorAssert).is_push_error(
		'Condition "err" is true. Returning: ERR_CANT_OPEN')
	assert_int(FileAccess.set_read_only_attribute(effect.game_path, false)).is_equal(OK)
	var result := results[0]
	assert_int(result.error).is_not_equal(OK)
	assert_array(result.written).contains_exactly([sound.game_path])
	assert_str(result.text).contains("已写入：sound.tres")
	assert_str(result.detail).contains(sound.game_path)
	assert_bool(FileAccess.get_file_as_bytes(effect.game_path) == original).is_true()
	assert_float(sound.disk_defaults().volume_db).is_equal(-2.0)
	var recorded := FileAccess.get_file_as_string(_fixture.dev_root().path_join(Files.LOG))
	assert_str(recorded).contains("写入 " + sound.game_path)
	assert_str(recorded).not_contains("写入 " + effect.game_path)


func test_saved_file_is_recorded_when_uid_restoration_fails() -> void:
	var slot := _fixture.sound_slot()
	var identity := _fixture._new_uid(slot.game_path)
	assert_int(ResourceSaver.set_uid(ProjectSettings.globalize_path(slot.game_path), identity)).is_equal(OK)
	slot.live.volume_db = -2.0
	var writer_source: Script = Writer
	var writer_path := _fixture.root.path_join("failed_writer.gd")
	_fixture._write(writer_path, writer_source.source_code.replace(
		"ResourceSaver.set_uid(ProjectSettings.globalize_path(path), identity)", "ERR_FILE_CANT_WRITE")
	)
	var adoption_source: Script = Adoption
	var adoption := GDScript.new()
	adoption.source_code = adoption_source.source_code.replace(
		'preload("res://dev/debug/_shared/default_writer.gd")', 'preload("%s")' % writer_path)
	assert_int(adoption.reload()).is_equal(OK)
	var slots: Array[Slot] = [slot]
	var result: Dictionary = adoption.adopt_all(slots, {})
	assert_int(result.error).is_equal(ERR_FILE_CANT_WRITE)
	assert_array(result.written).contains_exactly([slot.game_path])
	assert_float(slot.disk_defaults().volume_db).is_equal(-2.0)
	assert_str(FileAccess.get_file_as_string(_fixture.dev_root().path_join(Files.LOG))).contains(
		"写入 " + slot.game_path)


func test_queue_save_failure_records_common_values_without_claiming_a_queued_candidate() -> void:
	var slot := _fixture.effect_slot()
	_fixture.select(slot, "spark")
	assert_int(DirAccess.make_dir_recursive_absolute(Files.queue_path(slot))).is_equal(OK)
	var results: Array[Dictionary] = []
	var attempt := func() -> void: results.append(Adoption.adopt_all([slot], Adoption.plans_for([slot])))
	await (assert_error(attempt) as ErrorAssert).is_push_error(
		'Condition "err" is true. Returning: ERR_CANT_OPEN')
	var result := results[0]
	assert_int(result.error).is_not_equal(OK)
	assert_array(result.written).contains_exactly([slot.game_path])
	assert_str(result.text).contains("已写入：effect.tres")
	assert_bool(slot.is_dirty()).is_true()
	var recorded := FileAccess.get_file_as_string(_fixture.dev_root().path_join(Files.LOG))
	assert_str(recorded).contains("写入 " + slot.game_path)
	assert_str(recorded).contains("本次仅写入通用参数，候选 spark 未排队")
	assert_str(recorded).not_contains("排队移入")
	assert_str(Files.queued_candidate(slot)).is_empty()
