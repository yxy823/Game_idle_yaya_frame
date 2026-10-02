extends GdUnitTestSuite

## Source capability changes share one contract across single, batch and scan entry points.

const Group = preload("res://tools/asset_workbench/analysis_group.gd")
const Batch = preload("res://tools/asset_workbench/analysis_batch.gd")
const Scan = preload("res://tools/asset_workbench/analysis_group_scan.gd")
const Service = preload("res://tools/asset_workbench/analysis_service.gd")
const Source = preload("res://tools/asset_workbench/analysis_source.gd")
const Result = preload("res://tools/asset_workbench/analysis_result.gd")
const IMAGE: String = "res://examples/asset_workbench/assets/example_star.png"

var _batch: Batch
var _files: Array[String] = []
var _directories: Array[String] = []
var _capabilities_before: Dictionary = {}
var _capability_original: PackedByteArray = []


func before_test() -> void:
	_capabilities_before = Source.capabilities.duplicate(true)
	var service: Service = auto_free(Service.new())
	add_child(service)
	_batch = auto_free(Batch.new())
	_batch.service = service
	add_child(_batch)


func after_test() -> void:
	_batch.cancel()
	_restore_capability_file()
	Source.capabilities = _capabilities_before
	for path: String in _files:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path: String in _directories:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_files.clear()
	_directories.clear()


func test_source_membership_and_scan_use_one_capability_format_list() -> void:
	assert_str(Source.initialize()).is_empty()
	Source.capabilities.sources.image.extensions = ["sample"]
	var directory := _owned_directory("capability-formats-")
	var accepted := directory.path_join("supported.sample")
	var removed := directory.path_join("previous.png")
	for path: String in [accepted, removed]:
		assert_int(DirAccess.copy_absolute(IMAGE, path)).is_equal(OK)
		_files.append(path)
	assert_str(Source.asset_type(accepted)).is_equal("image")
	assert_bool(Source.path_issue(accepted, "image").is_empty()).is_true()
	assert_str(Source.path_issue(removed, "image").code).is_equal("unsupported_format")
	assert_str(_batch.add_paths([accepted, removed])).is_empty()
	assert_array(_batch.group.assets).is_equal([{"path": accepted, "type": "image"}])
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
	assert_array(found).is_equal([accepted])


func test_bad_capabilities_stop_membership_and_scan_then_allow_retry() -> void:
	_capability_original = FileAccess.get_file_as_bytes(Source.CAPABILITIES_PATH)
	var file := FileAccess.open(Source.CAPABILITIES_PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	Source.capabilities.clear()
	assert_str(_batch.add_paths([IMAGE])).contains("Invalid JSON")
	assert_array(_batch.group.assets).is_empty()
	var scan: Scan = auto_free(Scan.new())
	add_child(scan)
	var messages: Array[String] = []
	scan.finished.connect(func(message: String) -> void: messages.append(message))
	scan.start(IMAGE.get_base_dir())
	assert_bool(scan.active).is_false()
	assert_str(messages[0]).contains("Invalid JSON")
	_restore_capability_file()
	assert_str(_batch.add_paths([IMAGE])).is_empty()
	scan.start(IMAGE.get_base_dir())
	assert_bool(scan.active).is_true()
	scan.cancel()


func test_extra_source_type_is_rejected_before_classification_and_allows_retry() -> void:
	_capability_original = FileAccess.get_file_as_bytes(Source.CAPABILITIES_PATH)
	var declared: Dictionary = JSON.parse_string(_capability_original.get_string_from_utf8())
	declared.sources = {"other": {}, "audio": declared.sources.audio,
		"image": declared.sources.image}
	var file := FileAccess.open(Source.CAPABILITIES_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(declared))
	file.close()
	Source.capabilities.clear()
	assert_str(_batch.add_paths([IMAGE])).contains("Invalid source formats")
	assert_array(_batch.group.assets).is_empty()
	assert_str(Source.path_issue(IMAGE, "image").code).is_equal("analyzer_config")
	var scan: Scan = auto_free(Scan.new())
	add_child(scan)
	var messages: Array[String] = []
	scan.finished.connect(func(message: String) -> void: messages.append(message))
	scan.start(IMAGE.get_base_dir())
	assert_bool(scan.active).is_false()
	assert_str(messages[0]).contains("Invalid source formats")
	_restore_capability_file()
	assert_str(_batch.add_paths([IMAGE])).is_empty()
	assert_int(_batch.group.assets.size()).is_equal(1)


func test_history_does_not_require_current_source_or_supported_extension() -> void:
	assert_str(Source.initialize()).is_empty()
	Source.capabilities.sources.image.extensions = ["sample"]
	var missing := "res://reports/asset-analyzer/history-missing.png"
	assert_bool(FileAccess.file_exists(missing)).is_false()
	var data := _measurement(0.2)
	data.asset.path = missing
	var saved_group := Group.empty()
	saved_group.assets = [{"path": missing, "type": "image"}]
	var snapshot := {"snapshot_version": 1, "created_at": "historical",
		"group": saved_group, "results": {missing: data}}
	assert_str(_batch.load_snapshot(snapshot)).is_empty()
	assert_str(_batch.historical).is_equal("historical")
	assert_float(_batch.results[missing].metrics.luma_mean.value).is_equal(0.2)


func _measurement(value: float) -> Dictionary:
	var data := Result.failure("res://example.png", "image", "fixture", "fixture")
	data.status = "success"
	data.errors = []
	data.metrics = {"luma_mean": {"status": "available", "value": value,
		"unit": "ratio", "reason": ""}}
	return data


func _restore_capability_file() -> void:
	if _capability_original.is_empty():
		return
	var file := FileAccess.open(Source.CAPABILITIES_PATH, FileAccess.WRITE)
	file.store_buffer(_capability_original)
	file.close()
	_capability_original.clear()
	Source.capabilities.clear()


func _owned_directory(prefix: String) -> String:
	var path := "res://reports/asset-analyzer/" + prefix + str(Time.get_ticks_usec())
	assert_int(DirAccess.make_dir_recursive_absolute(path)).is_equal(OK)
	_directories.append(path)
	return path
