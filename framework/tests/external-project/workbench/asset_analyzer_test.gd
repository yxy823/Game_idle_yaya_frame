extends GdUnitTestSuite

const Service = preload("res://yaya/asset_workbench/ui/analysis_service.gd")
const Result = preload("res://yaya/asset_workbench/ui/analysis_result.gd")
const Source = preload("res://yaya/asset_workbench/ui/analysis_source.gd")
const AUDIO: String = "res://yaya/asset_workbench/examples/assets/example_confirmation_a.ogg"
const IMAGE: String = "res://yaya/asset_workbench/examples/assets/example_star.png"
const FAULT_WORKER: String = "res://tests/features/asset_analyzer/analyzer_process_fixture.py"

var _service: Service
var _results: Dictionary[int, Dictionary] = {}
var _owned_files: Array[String] = []
var _original_path: String


func before_test() -> void:
	_results.clear()
	_original_path = OS.get_environment("PATH")
	_service = auto_free(Service.new())
	add_child(_service)
	_service.completed.connect(func(id: int, data: Dictionary) -> void: _results[id] = data)


func after_test() -> void:
	OS.set_environment("PATH", _original_path)
	for path: String in _owned_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_owned_files.clear()


func test_real_audio_image_and_cache_through_process_boundary() -> void:
	var audio := _service.submit(AUDIO, "audio", {}, true)
	var image := _service.submit(IMAGE, "image", {}, true)
	await _wait_for(audio)
	await _wait_for(image)
	assert_str(_results[audio].status).is_equal("success")
	assert_str(_results[image].status).is_equal("success")
	assert_bool(Result.is_valid(_results[audio])).is_true()
	assert_bool(_results[audio].series.has("peak_envelope")).is_true()
	assert_bool(_results[image].series.has("alpha_histogram")).is_true()
	var cached := _service.submit(AUDIO, "audio")
	await _wait_for(cached)
	assert_bool(_results[cached].cache.hit).is_true()


func test_python_command_and_missing_explicit_paths() -> void:
	var python_path := _service.executable
	_service.executable = "res://tests/nonexistent-python.exe"
	var task := _service.submit(AUDIO, "audio")
	await _wait_for(task)
	assert_str(_results[task].errors[0].code).is_equal("process_missing")
	assert_bool(python_path.is_absolute_path()).is_true()
	OS.set_environment("PATH", python_path.get_base_dir() + ";" + _original_path)
	_service.executable = python_path.get_file().get_basename()
	task = _service.submit(IMAGE, "image", {}, true)
	await _wait_for(task)
	assert_str(_results[task].status).is_equal("success")
	assert_bool(_results[task].series.has("alpha_histogram")).is_true()
	_service.executable = "reports/nonexistent/" + python_path.get_file()
	task = _service.submit(IMAGE, "image", {}, true)
	await _wait_for(task)
	assert_str(_results[task].errors[0].code).is_equal("process_missing")


func test_unicode_space_path_and_content_change_invalidate_cache() -> void:
	var path := "res://reports/asset-analyzer/space \u4e2d\u6587 %d.png" % Time.get_ticks_usec()
	_owned_files.append(path)
	assert_int(DirAccess.copy_absolute(IMAGE, path)).is_equal(OK)
	var first := _service.submit(path, "image")
	await _wait_for(first)
	assert_str(_results[first].status).is_equal("success")
	var replacement := "res://yaya/asset_workbench/examples/assets/example_trophy.png"
	assert_int(DirAccess.copy_absolute(replacement, path)).is_equal(OK)
	var second := _service.submit(path, "image")
	await _wait_for(second)
	assert_bool(_results[second].cache.hit).is_false()
	assert_str(_results[first].cache.key).is_not_equal(_results[second].cache.key)
	for task: int in [first, second]:
		_owned_files.append("res://reports/asset-analyzer/cache/%s.json" % _results[task].cache.key)


func test_project_rule_is_separate_from_measurement() -> void:
	var data := Result.failure(AUDIO, "audio", "fixture", "fixture")
	data.metrics.leading_silence = {"status": "available", "value": 0.1, "unit": "s", "reason": ""}
	assert_int(Result.rule_messages(data, 0.05).size()).is_equal(1)
	assert_bool(Result.rule_messages(data, 0.2).is_empty()).is_true()
	assert_float(data.metrics.leading_silence.value).is_equal(0.1)


func test_timeout_kills_owned_process_and_removes_files() -> void:
	_service.worker_path = FAULT_WORKER
	_service.timeout_seconds = 0.2
	var task := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	await get_tree().process_frame
	var job: RefCounted = _service.get("_jobs")[task]
	var pid: int = job.get("process").pid
	var path: String = job.get("request_path")
	await _wait_for(task)
	assert_str(_results[task].errors[0].code).is_equal("timeout")
	assert_bool(OS.is_process_running(pid)).is_false()
	assert_bool(FileAccess.file_exists(path)).is_false()


func test_bad_json_empty_exit_and_output_limit() -> void:
	_service.worker_path = FAULT_WORKER
	for mode: String in ["invalid", "empty", "exit", "overflow"]:
		var task := _service.submit(AUDIO, "audio", {"fixture": mode})
		await _wait_for(task)
		var expected: String = "invalid_result"
		if mode == "exit":
			expected = "process_exit"
		elif mode == "overflow":
			expected = "output_limit"
		assert_str(_results[task].errors[0].code).is_equal(expected)


func test_queue_limit_and_running_and_queued_cancel() -> void:
	_service.worker_path = FAULT_WORKER
	_service.max_concurrent = 1
	var running := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	var queued := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	await get_tree().process_frame
	assert_int(_service.get("_running").size()).is_equal(1)
	assert_int(_service.get("_queue").size()).is_equal(1)
	_service.cancel(queued)
	_service.cancel(running)
	assert_str(_results[queued].status).is_equal("cancelled")
	assert_str(_results[running].status).is_equal("cancelled")
	assert_int(_service.get("_jobs").size()).is_equal(0)
	_service.max_concurrent = 2
	var first := _service.submit(AUDIO, "audio", {"fixture": "empty"})
	var other := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	_service.completed.connect(func(id: int, _data: Dictionary) -> void:
		if id == first:
			_service.cancel(other))
	await _wait_for(first)
	assert_str(_results[other].status).is_equal("cancelled")


func test_scene_removal_cleans_process_and_request() -> void:
	_service.worker_path = FAULT_WORKER
	var task := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	await get_tree().process_frame
	var job: RefCounted = _service.get("_jobs")[task]
	var pid: int = job.get("process").pid
	var path: String = job.get("request_path")
	remove_child(_service)
	assert_bool(OS.is_process_running(pid)).is_false()
	assert_bool(FileAccess.file_exists(path)).is_false()
	add_child(_service)


func test_missing_metrics_keep_status_and_do_not_become_zero() -> void:
	var data := Result.failure(AUDIO, "audio", "fixture", "fixture")
	data.metrics["pitch"] = {"status": "not_applicable", "value": null,
		"unit": "Hz", "reason": "not tonal"}
	var rows := Result.compare_rows(data, {})
	assert_str(rows[0].a).contains("not_applicable")
	assert_str(rows[0].b).contains("missing")
	assert_str(rows[0].b).is_not_equal("0")


func test_corrupt_protocol_is_rejected_before_ui() -> void:
	var data := Result.failure(AUDIO, "audio", "fixture", "fixture")
	data.series["bad"] = {"status": "available", "kind": "line", "x": [1],
		"y": [], "x_unit": "s", "y_unit": "dB"}
	assert_bool(Result.is_valid(data)).is_false()
	data.series.clear()
	data.metrics["bad"] = {"status": "failed", "value": 0, "unit": "", "reason": "bad"}
	assert_bool(Result.is_valid(data)).is_false()


func _wait_for(task_id: int) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not _results.has(task_id) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_bool(_results.has(task_id)).is_true()


func test_shared_schema_corpus_matches_godot_and_rejects_nonfinite() -> void:
	var corpus: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/features/asset_analyzer/analyzer_protocol_cases.json"))
	assert_bool(Result.is_valid(corpus.base)).is_true()
	for case: Dictionary in corpus.cases:
		var data: Dictionary = corpus.base.duplicate(true)
		var target: Variant = data
		for index: int in range(case.path.size() - 1):
			var key: Variant = int(case.path[index]) if target is Array else case.path[index]
			target = target[key]
		var last: Variant = case.path.back()
		if case.get("remove", false):
			target.erase(last)
		else:
			target[last] = case.value
		assert_bool(Result.is_valid(data)).override_failure_message(case.name).is_equal(case.valid)
	corpus.base.series.example.y[0] = NAN
	assert_bool(Result.is_valid(corpus.base)).is_false()


func test_source_preflight_rejects_indirect_and_unsupported_resources() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(IMAGE)
	assert_str(Source.describe(atlas).issue.code).is_equal("source_not_file")
	assert_str(Source.describe(ImageTexture.new()).issue.code).is_equal("source_not_file")
	var path := "res://reports/asset-analyzer/legal vector.svg"
	_owned_files.append(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"/>')
	file.close()
	var task := _service.submit(path, "image")
	await _wait_for(task)
	assert_str(_results[task].errors[0].code).is_equal("unsupported_format")


func test_memory_reservations_serialize_large_workers_and_allow_two_images() -> void:
	_service.worker_path = FAULT_WORKER
	var first := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	var second := _service.submit(AUDIO, "audio", {"fixture": "timeout"})
	await get_tree().process_frame
	assert_int(_service.get("_running").size()).is_equal(1)
	assert_int(_service.reserved_memory_mib()).is_equal(384)
	_service.cancel(first)
	_service.cancel(second)
	first = _service.submit(IMAGE, "image", {"fixture": "timeout"})
	second = _service.submit(IMAGE, "image", {"fixture": "timeout"})
	await get_tree().process_frame
	assert_int(_service.get("_running").size()).is_equal(2)
	assert_int(_service.reserved_memory_mib()).is_equal(512)
	_service.cancel(first)
	_service.cancel(second)
