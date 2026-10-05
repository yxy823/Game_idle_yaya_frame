extends GdUnitTestSuite

const Service = preload("res://yaya/asset_workbench/ui/analysis_service.gd")
const Result = preload("res://yaya/asset_workbench/ui/analysis_result.gd")
const Chart = preload("res://yaya/asset_workbench/ui/analysis_chart.gd")
const Source = preload("res://yaya/asset_workbench/ui/analysis_source.gd")
const Schema = preload("res://yaya/asset_workbench/ui/analysis_schema.gd")
const Workbench = preload("res://yaya/asset_workbench/examples/single/example_workbench.tscn")
const AUDIO: String = "res://yaya/asset_workbench/examples/assets/example_confirmation_a.ogg"
const IMAGE: String = "res://yaya/asset_workbench/examples/assets/example_star.png"
const FAULT_WORKER: String = "res://tests/features/asset_analyzer/analyzer_process_fixture.py"

var _service: Service
var _results: Dictionary[int, Dictionary] = {}
var _contract_originals: Dictionary[String, PackedByteArray] = {}
var _window_size: Vector2i


func before_test() -> void:
	_window_size = get_tree().root.size
	get_tree().root.size = Vector2i(1600, 900)
	_results.clear()
	_service = auto_free(Service.new())
	add_child(_service)
	_service.completed.connect(func(id: int, data: Dictionary) -> void: _results[id] = data)


func after_test() -> void:
	get_tree().root.size = _window_size
	for path: String in _contract_originals:
		_restore_contract(path)
	_contract_originals.clear()


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
	assert_int(await _voices_at_sound_start(workbench)).is_greater(0)
	assert_object(workbench.get("session").current().sound).is_not_null()
	workbench.call("stop_all")
	panel.get("service").executable = _service.executable
	await _check_contract_failures(workbench)


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


func test_comparison_fingerprint_checks_parameters_versions_and_backend() -> void:
	var task := _service.submit(AUDIO, "audio")
	await _wait_for(task)
	var first: Dictionary = _results[task]
	for field: String in ["parameters", "analyzer", "backend", "schema", "type"]:
		var second: Dictionary = first.duplicate(true)
		match field:
			"parameters": second.parameters.silence_dbfs = -30
			"analyzer": second.analyzer.version += 1
			"backend": second.analyzer.backend["av"] = "different"
			"schema": second.schema_version += 1
			"type": second.asset.type = "image"
		var reason := Result.comparison_reason(first, second)
		assert_str(reason).is_not_empty()
		var chart: Chart = auto_free(Chart.new())
		chart.display(first.series.peak_envelope, second.series.peak_envelope, reason)
		assert_bool(chart.second.is_empty()).is_true()
		assert_str(chart.comparison_notice).contains("B overlay hidden")


func test_panel_marks_settings_stale_then_reanalyzes_both() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Window = workbench.get("_analysis")
	var paths: Array[String] = [AUDIO,
		"res://yaya/asset_workbench/examples/assets/example_confirmation_b.ogg"]
	var tasks: Array[int] = []
	for path: String in paths:
		tasks.append(_service.submit(path, "audio"))
	for task: int in tasks:
		await _wait_for(task)
	panel.call("open_results", _results[tasks[0]], _results[tasks[1]])
	_assert_panel_sources(panel, paths)
	await _assert_failed_reanalysis_retains_result(panel)
	panel.get("_threshold").value = -30
	assert_bool(panel.call("_stale", 0)).is_true()
	assert_str(panel.get("_comparison").text).contains("STALE")
	assert_bool(panel.get("_chart").second.is_empty()).is_true()
	panel.call("_reanalyze_both")
	await _wait_for_panel(panel)
	_assert_panel_sources(panel, paths)
	for index: int in 2:
		assert_bool(panel.call("_stale", index)).is_false()
		assert_float(panel.results[index].parameters.silence_dbfs).is_equal(-30.0)
		assert_str(panel.get("_summaries")[index].text).not_contains("旧结果")
	assert_str(Result.comparison_reason(panel.results[0], panel.results[1])).is_empty()
	panel.call("_close")


func test_zoom_preserves_data_position_under_mouse() -> void:
	var chart: Chart = auto_free(Chart.new())
	add_child(chart)
	chart.size = Vector2(600, 250)
	chart.display({"kind": "histogram", "x": [0, 1, 2], "y": [0.1, 0.2, 0.7],
		"x_unit": "bin", "y_unit": "ratio"}, {})
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP
	event.pressed = true
	event.position = Vector2(65 + (600 - 80) * 0.25, 80)
	var previous_view: Rect2 = chart.call("_view_bounds")
	chart.call("_gui_input", event)
	var current_view: Rect2 = chart.call("_view_bounds")
	assert_float(previous_view.position.x + previous_view.size.x * 0.25).is_equal_approx(
		current_view.position.x + current_view.size.x * 0.25, 0.00001)


func _wait_for(task_id: int) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not _results.has(task_id) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_bool(_results.has(task_id)).is_true()


func _check_contract_failures(workbench: Control) -> void:
	# This suite runs only in the dedicated external fixture project. Restore exact bytes.
	var panel: Window = workbench.get("_analysis")
	for path: String in [Source.CAPABILITIES_PATH, Schema.SCHEMA_PATH]:
		_contract_originals[path] = FileAccess.get_file_as_bytes(path)
		for malformed: String in ["", "{broken", "[]", "{}"]:
			_invalidate_contract(path, malformed)
			panel.call("open_asset", load(AUDIO))
			panel.call("_analyze", 0)
			var failure_deadline := Time.get_ticks_msec() + 5000
			while panel.results[0].is_empty() and Time.get_ticks_msec() < failure_deadline:
				await get_tree().process_frame
			assert_str(panel.results[0].status).is_equal("failed")
			assert_str(panel.results[0].errors[0].code).is_equal("analyzer_config")
			assert_str(panel.results[0].errors[0].message).contains(path)
			assert_int(await _voices_at_sound_start(workbench)).is_greater(0)
			workbench.call("stop_all")
			_restore_contract(path)
		panel.call("open_asset", load(IMAGE))
		panel.call("_analyze", 0)
		var recovery_deadline := Time.get_ticks_msec() + 15000
		while panel.results[0].is_empty() and Time.get_ticks_msec() < recovery_deadline:
			await get_tree().process_frame
		assert_str(panel.results[0].status).is_equal("success")
	panel.call("_close")


func _invalidate_contract(path: String, malformed: String) -> void:
	Source.capabilities.clear()
	Schema._schema.clear()
	if malformed.is_empty():
		assert_int(DirAccess.remove_absolute(path)).is_equal(OK)
	else:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(malformed)
		file.close()


func _restore_contract(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(_contract_originals[path])
	file.close()
	Source.capabilities.clear()
	Schema._schema.clear()


func _assert_failed_reanalysis_retains_result(panel: Window) -> void:
	var previous: Dictionary = panel.results[0].duplicate(true)
	var worker: String = panel.service.worker_path
	panel.service.worker_path = FAULT_WORKER
	panel.call("_reanalyze", 0)
	assert_bool(panel.results[0] == previous).is_true()
	assert_str(panel.get("_summaries")[0].text).contains("旧结果")
	await _wait_for_panel(panel)
	assert_bool(panel.results[0] == previous).is_true()
	assert_str(panel.get("_summaries")[0].text).contains("failed")
	assert_str(panel.get("_issues").text).contains("invalid JSON")
	panel.call("_reanalyze", 0)
	panel.call("_cancel")
	assert_bool(panel.results[0] == previous).is_true()
	assert_str(panel.get("_summaries")[0].text).contains("cancelled")
	assert_str(panel.get("_details").text).contains("旧结果")
	panel.service.worker_path = worker


func _wait_for_panel(panel: Window) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while panel.get("_tasks") != [0, 0] and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_bool(panel.get("_tasks") == [0, 0]).is_true()


func _assert_panel_sources(panel: Window, paths: Array[String]) -> void:
	for index: int in 2:
		var data: Dictionary = panel.results[index]
		assert_str(data.get("status", "")).is_equal("success")
		assert_str(str(data.get("asset", {}).get("type", ""))).is_equal("audio")
		var actual := ProjectSettings.globalize_path(str(data.get("asset", {}).get("path", "")))
		var expected := ProjectSettings.globalize_path(paths[index])
		assert_str(actual.replace("\\", "/").simplify_path()).is_equal(
			expected.replace("\\", "/").simplify_path())


# 在声音真正开始的那一刻记录活动声部数，不用固定等待去赶只有零点几秒的短音频。
func _voices_at_sound_start(workbench: Control) -> int:
	var voices: Array[int] = []
	var presenter: Node = workbench.get("presenter")
	var record := func() -> void: voices.append(int(presenter.call("active_voice_count")))
	presenter.connect("sound_started", record)
	workbench.call("_trigger_once")
	var deadline := Time.get_ticks_msec() + 2000
	while voices.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	presenter.disconnect("sound_started", record)
	return voices[0] if not voices.is_empty() else -1
