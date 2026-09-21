extends GdUnitTestSuite

const Service = preload("res://tools/asset_workbench/analysis_service.gd")
const Result = preload("res://tools/asset_workbench/analysis_result.gd")
const Chart = preload("res://tools/asset_workbench/analysis_chart.gd")
const Workbench = preload("res://examples/asset_workbench/example-workbench.tscn")
const AUDIO: String = "res://examples/asset_workbench/assets/example-confirmation-a.ogg"
const IMAGE: String = "res://examples/asset_workbench/assets/example-star.png"
const FAULT_WORKER: String = "res://tests/features/asset_analyzer/analyzer_process_fixture.py"

var _service: Service
var _results: Dictionary[int, Dictionary] = {}
var _owned_files: Array[String] = []


func before_test() -> void:
	_results.clear()
	_service = auto_free(Service.new())
	add_child(_service)
	_service.completed.connect(func(id: int, data: Dictionary) -> void: _results[id] = data)


func after_test() -> void:
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


func test_missing_process_is_structured_failure() -> void:
	_service.executable = "res://tests/nonexistent-python.exe"
	var task := _service.submit(AUDIO, "audio")
	await _wait_for(task)
	assert_str(_results[task].errors[0].code).is_equal("process_missing")


func test_unicode_space_path_and_content_change_invalidate_cache() -> void:
	var path := "res://reports/asset-analyzer/space \u4e2d\u6587 %d.png" % Time.get_ticks_usec()
	_owned_files.append(path)
	assert_int(DirAccess.copy_absolute(IMAGE, path)).is_equal(OK)
	var first := _service.submit(path, "image")
	await _wait_for(first)
	assert_str(_results[first].status).is_equal("success")
	var replacement := "res://examples/asset_workbench/assets/example-trophy.png"
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


func test_workbench_still_previews_after_analyzer_failure() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Window = workbench.get("_analysis")
	panel.get("service").executable = "res://missing.exe"
	panel.set("_selected", load(AUDIO))
	panel.call("_analyze", 0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(panel.get("results")[0].status).is_equal("failed")
	workbench.call("_trigger_once")
	await get_tree().create_timer(0.12).timeout
	assert_int(workbench.get("presenter").active_voice_count()).is_greater(0)
	assert_object(workbench.get("session").current().sound).is_not_null()
	workbench.call("stop_all")


func test_chart_uses_normalized_series_and_rejects_unit_mismatch() -> void:
	var chart: Chart = auto_free(Chart.new())
	add_child(chart)
	var first := {"status": "available", "kind": "line", "x": [0, 1], "y": [0, 1],
		"x_unit": "s", "y_unit": "ratio"}
	var second := first.duplicate(true)
	second.y_unit = "dB"
	chart.display(first, second)
	assert_int(chart.first.x.size()).is_equal(2)
	assert_bool(chart.second.is_empty()).is_true()
	var zoom := InputEventMouseButton.new()
	zoom.button_index = MOUSE_BUTTON_WHEEL_UP
	zoom.pressed = true
	zoom.position = Vector2(100, 80)
	chart.call("_gui_input", zoom)
	assert_float(chart.get("_zoom")).is_greater(1.0)
	zoom.button_index = MOUSE_BUTTON_RIGHT
	chart.call("_gui_input", zoom)
	assert_float(chart.get("_zoom")).is_equal(1.0)


func _wait_for(task_id: int) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not _results.has(task_id) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_bool(_results.has(task_id)).is_true()
