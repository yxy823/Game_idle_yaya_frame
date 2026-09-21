extends GdUnitTestSuite

const Group = preload("res://tools/asset_workbench/analysis_group.gd")
const Statistics = preload("res://tools/asset_workbench/analysis_group_statistics.gd")
const Batch = preload("res://tools/asset_workbench/analysis_batch.gd")
const Scan = preload("res://tools/asset_workbench/analysis_group_scan.gd")
const Service = preload("res://tools/asset_workbench/analysis_service.gd")
const Result = preload("res://tools/asset_workbench/analysis_result.gd")
const Workbench = preload("res://examples/asset_workbench/single/example-workbench.tscn")
const EXAMPLE: String = "res://examples/asset_workbench/example-analysis-group.json"
const IMAGE: String = "res://examples/asset_workbench/assets/example-star.png"
const FAULT: String = "res://tests/features/asset_analyzer/analyzer_process_fixture.py"

var _service: Service
var _batch: Batch
var _files: Array[String] = []
var _directories: Array[String] = []


func before_test() -> void:
	_service = auto_free(Service.new())
	add_child(_service)
	_batch = auto_free(Batch.new())
	_batch.service = _service
	add_child(_batch)


func after_test() -> void:
	_batch.cancel()
	for path: String in _files:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path: String in _directories:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_files.clear()
	_directories.clear()


func test_group_schema_rejects_bad_input_without_replacing_members() -> void:
	assert_str(_batch.add_paths([IMAGE, IMAGE, "D:/outside.png", "res://file.txt"])).is_empty()
	assert_int(_batch.group.assets.size()).is_equal(1)
	var invalid := _batch.group.duplicate(true)
	invalid.assets.append(invalid.assets[0])
	assert_str(_batch.load_group(invalid)).contains("duplicate")
	assert_int(_batch.group.assets.size()).is_equal(1)
	invalid = Group.empty()
	invalid.rules.append(_rule("delta", -1.0))
	assert_str(Group.validation_error(invalid)).contains("Invalid rule")
	invalid.assets = [{"path": "../outside.png", "type": "image"}]
	assert_str(Group.validation_error(invalid)).contains("invalid")
	assert_str(Group.validation_error({"group_version": 2})).contains("version")


func test_group_limit_does_not_silently_discard_existing_members() -> void:
	var paths: Array[String] = []
	for index: int in Group.MAX_ASSETS + 1:
		paths.append("res://assets/example-%d.png" % index)
	assert_str(_batch.add_paths(paths)).contains("512")
	assert_int(_batch.group.assets.size()).is_equal(Group.MAX_ASSETS)
	assert_str(Group.validation_error(_batch.group)).is_empty()


func test_statistics_and_deviations_explain_actual_distance() -> void:
	var data := {"a": _measurement(0.1), "b": _measurement(0.2), "c": _measurement(0.9)}
	var group := Group.empty()
	group.assets = [{"path": "a", "type": "image"}, {"path": "c", "type": "image"}]
	group.rules = [_rule("delta", 0.3), _rule("max", 0.5), _rule("min", 0.15)]
	var stats := Statistics.columns(data)
	assert_int(stats.values()[0].count).is_equal(3)
	assert_float(stats.values()[0].median).is_equal(0.2)
	var checks := Statistics.checks(group, data, stats)
	assert_str(checks.c[0].status).is_equal("deviation")
	assert_str(checks.c[0].message).contains("absolute distance 0.70000")
	assert_str(checks.a[0].status).is_equal("pass")
	assert_str(checks.a[2].status).is_equal("deviation")
	assert_float(data.c.metrics.luma_mean.value).is_equal(0.9)


func test_missing_states_are_not_zero_or_a_rule_pass() -> void:
	var group := Group.empty()
	group.assets = [{"path": "a", "type": "image"}]
	group.rules = [_rule("max", 1.0)]
	for state: String in Result.STATES:
		if state == "available":
			continue
		var data := _measurement(0.0)
		data.metrics.luma_mean = {"status": state, "value": null, "unit": "ratio", "reason": "fixture"}
		var stats := Statistics.columns({"a": data})
		assert_bool(stats.is_empty()).is_true()
		var checks := Statistics.checks(group, {"a": data}, stats)
		assert_str(checks.a[0].status).is_equal("unmeasured")
		assert_str(checks.a[0].message).contains(state)
	assert_str(Statistics.checks(group, {}, {}).a[0].status).is_equal("unmeasured")


func test_units_versions_parameters_and_types_form_separate_cohorts() -> void:
	var base := _measurement(0.1)
	var unit := _measurement(20.0)
	unit.metrics.luma_mean.unit = "percent"
	var version := _measurement(0.2)
	version.analyzer.version = 2
	var backend := _measurement(0.3)
	backend.analyzer.backend = {"example": "2.0"}
	var parameters := _measurement(0.4)
	parameters.parameters = {"mode": "different"}
	var audio := _measurement(0.5)
	audio.asset.type = "audio"
	var data := {"base": base, "unit": unit, "version": version, "backend": backend,
		"parameters": parameters, "audio": audio}
	assert_int(Statistics.columns(data).size()).is_equal(6)
	var group := Group.empty()
	group.assets = [{"path": "base", "type": "image"}]
	group.rules = [_rule("delta", 0.1)]
	var checks := Statistics.checks(group, data, Statistics.columns(data))
	assert_str(checks.base[0].status).is_equal("unmeasured")
	assert_str(checks.base[0].message).contains("3 comparable")


func test_real_batch_and_cache_use_the_existing_queue() -> void:
	assert_str(_batch.load_group(Group.read_json(EXAMPLE).data)).is_empty()
	_service.max_concurrent = 1
	_batch.run(true)
	await get_tree().process_frame
	assert_int(_service.get("_running").size()).is_equal(1)
	await _wait_for_batch()
	assert_int(_batch.results.size()).is_equal(4)
	for data: Dictionary in _batch.results.values():
		assert_str(data.status).is_equal("success")
	_batch.run()
	await _wait_for_batch()
	for data: Dictionary in _batch.results.values():
		assert_bool(data.cache.hit).is_true()


func test_batch_cancel_preserves_independent_single_asset_job() -> void:
	_service.worker_path = FAULT
	_batch.add_paths([IMAGE])
	_batch.group.parameters = {"fixture": "timeout"}
	var independent := _service.submit(IMAGE, "image", {"fixture": "timeout"})
	_batch.run()
	await get_tree().process_frame
	_batch.cancel()
	assert_bool(_batch.busy()).is_false()
	assert_str(_batch.results[IMAGE].status).is_equal("cancelled")
	assert_bool(_service.get("_jobs").has(independent)).is_true()
	_service.cancel(independent)


func test_scan_handles_unicode_and_skips_generated_files() -> void:
	var directory := _owned_directory("scan \u4e2d\u6587 ")
	var ignored := directory.path_join("reports")
	DirAccess.make_dir_absolute(ignored)
	_directories.push_front(ignored)
	for path: String in [directory.path_join("sample image.png"), ignored.path_join("ignored.png")]:
		assert_int(DirAccess.copy_absolute(IMAGE, path)).is_equal(OK)
		_files.append(path)
	var scan: Scan = auto_free(Scan.new())
	add_child(scan)
	var found: Array[String] = []
	scan.found.connect(func(paths: Array[String]) -> void: found.append_array(paths))
	scan.start(directory)
	for _index: int in 30:
		await get_tree().process_frame
		if not scan.active:
			break
	assert_bool(scan.active).is_false()
	assert_array(found).is_equal([directory.path_join("sample image.png")])
	scan.start(directory)
	scan.cancel()
	assert_bool(scan.active).is_false()
	var messages: Array[String] = []
	scan.finished.connect(func(message: String) -> void: messages.append(message))
	scan.found.connect(func(_paths: Array[String]) -> void: scan.cancel())
	scan.start(directory)
	for _index: int in 30:
		await get_tree().process_frame
		if not scan.active:
			break
	assert_bool(scan.active).is_false()
	assert_array(messages).is_empty()


func test_group_json_round_trip_and_bad_json_retains_state() -> void:
	var directory := _owned_directory("group ")
	var path := directory.path_join("group.json")
	_files.append(path)
	_batch.load_group(Group.read_json(EXAMPLE).data)
	assert_str(Group.write_json(path, _batch.group)).is_empty()
	assert_str(_batch.load_group(Group.read_json(path).data)).is_empty()
	assert_int(_batch.group.assets.size()).is_equal(4)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	assert_str(Group.read_json(path).error).contains("Invalid JSON")
	assert_int(_batch.group.assets.size()).is_equal(4)


func test_snapshot_utf8_size_limit_round_trips_and_rejects_before_overwrite() -> void:
	var directory := _owned_directory("snapshot-size-")
	var path := directory.path_join("boundary.json")
	var absent := directory.path_join("too-large.json")
	_files.append_array([path, absent])
	var snapshot := _batch.snapshot()
	snapshot.group.name = ""
	var overhead := (JSON.stringify(snapshot, "  ") + "\n").to_utf8_buffer().size()
	var remaining := Group.MAX_JSON_BYTES - overhead
	snapshot.group.name = "\u4e2d".repeat(floori(remaining / 3.0)) + "a".repeat(remaining % 3)
	assert_str(Group.snapshot_error(snapshot)).is_empty()
	assert_str(Group.write_json(path, snapshot)).is_empty()
	var file := FileAccess.open(path, FileAccess.READ)
	assert_int(file.get_length()).is_equal(Group.MAX_JSON_BYTES)
	file.close()
	var loaded := Group.read_json(path)
	assert_bool(loaded.has("data")).is_true()
	assert_str(_batch.load_snapshot(loaded.data)).is_empty()
	# Normalize JSON number types; keep huge values out of assertion diagnostics.
	assert_bool(loaded.data == JSON.parse_string(JSON.stringify(snapshot))).is_true()
	snapshot.group.name += "a"
	assert_str(Group.write_json(path, snapshot)).contains("no file was written")
	assert_bool(Group.read_json(path).data == loaded.data).is_true()
	assert_str(Group.write_json(absent, snapshot)).contains("32 MiB")
	assert_bool(FileAccess.file_exists(absent)).is_false()


func test_history_is_validated_and_reanalysis_invalidates_changed_file() -> void:
	var directory := _owned_directory("history ")
	var path := directory.path_join("source.png")
	_files.append(path)
	DirAccess.copy_absolute(IMAGE, path)
	_batch.add_paths([path])
	_batch.run()
	await _wait_for_batch()
	var snapshot := _batch.snapshot()
	var key: String = _batch.results[path].cache.key
	assert_str(Group.snapshot_error(snapshot)).is_empty()
	assert_str(_batch.load_snapshot(snapshot)).is_empty()
	assert_str(_batch.historical).is_not_empty()
	assert_str(snapshot.results[path].asset.path).is_equal(path)
	assert_str(_batch.snapshot().created_at).is_equal(snapshot.created_at)
	var invalid := snapshot.duplicate(true)
	invalid.results[path].asset.path = "res://different.png"
	assert_str(_batch.load_snapshot(invalid)).contains("does not match")
	var image := Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	assert_int(image.save_png(path)).is_equal(OK)
	_batch.run()
	await _wait_for_batch()
	assert_str(_batch.historical).is_empty()
	assert_bool(_batch.results[path].cache.hit).is_false()
	assert_str(_batch.results[path].cache.key).is_not_equal(key)
	_files.append("res://reports/asset-analyzer/cache/" + key + ".json")
	_files.append("res://reports/asset-analyzer/cache/" + _batch.results[path].cache.key + ".json")


func test_group_comparison_reuses_existing_analysis_ui_without_new_jobs() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Window = workbench.get("_batch")
	var batch: Batch = panel.get("batch")
	batch.load_group(Group.read_json(EXAMPLE).data)
	batch.run()
	while batch.busy():
		await get_tree().process_frame
	panel.call("_refresh")
	var table: Tree = panel.get("_members")
	table.get_root().get_child(0).select(0)
	table.get_root().get_child(1).select(0)
	var last_id: int = batch.service.get("_next_id")
	panel.call("_compare")
	var analysis: Window = workbench.get("_analysis")
	assert_str(analysis.get("results")[0].asset.type).is_equal("image")
	assert_int(batch.service.get("_next_id")).is_equal(last_id)
	assert_bool(workbench.session.is_dirty()).is_false()
	analysis.call("_close")


func test_batch_failure_keeps_event_preview_and_close_cleans_tasks() -> void:
	var workbench: Control = auto_free(Workbench.instantiate())
	add_child(workbench)
	var panel: Window = workbench.get("_batch")
	var batch: Batch = panel.get("batch")
	batch.service.executable = "res://missing-python.exe"
	batch.add_paths([IMAGE])
	batch.run()
	for _index: int in 5:
		await get_tree().process_frame
	assert_str(batch.results[IMAGE].status).is_equal("failed")
	workbench.call("_trigger_once")
	await get_tree().create_timer(0.12).timeout
	assert_int(workbench.presenter.active_voice_count()).is_greater(0)
	workbench.call("stop_all")
	batch.run()
	panel.call("_close")
	assert_bool(batch.busy()).is_false()
	assert_int(batch.service.get("_jobs").size()).is_equal(0)


func _measurement(value: float) -> Dictionary:
	var data := Result.failure("res://example.png", "image", "fixture", "fixture")
	data.status = "success"
	data.errors = []
	data.metrics = {"luma_mean": {"status": "available", "value": value,
		"unit": "ratio", "reason": ""}}
	return data


func _rule(operator: String, value: float) -> Dictionary:
	return {"type": "image", "metric": "luma_mean", "unit": "ratio",
		"operator": operator, "value": value}


func _owned_directory(prefix: String) -> String:
	var path := "res://reports/asset-analyzer/" + prefix + str(Time.get_ticks_usec())
	assert_int(DirAccess.make_dir_recursive_absolute(path)).is_equal(OK)
	_directories.append(path)
	return path


func _wait_for_batch() -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while _batch.busy() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_bool(_batch.busy()).is_false()
