extends GdUnitTestSuite
## Copy this suite and the Python stub to the debug tests in the external project.

const Service := preload("res://dev/debug/_shared/analyzer_service.gd")
const STUB := "res://dev/debug/_shared/tests/fixtures/gaa_summary_stub.py"
const SOURCE := "res://dev/debug/_shared/tests/fixtures/sample/" \
	+ "debug/sample/slots/feedback/sound/chime/chime.wav"
const WAIT_MSEC := 5000

var _service: Service
var _states: Array[Dictionary] = []
var _case: String = "completed"
var _hold: bool = false
var _pid: int = 0
var _output: String = ""
var _release: String = ""


func before_test() -> void:
	_service = auto_free(Service.new()) as Service
	add_child(_service)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Service.CONFIG))
	_service.audio_python = config.python_executable
	_service.launch = _launch
	_service.set_process(false)
	_states.clear()
	_case = "completed"
	_hold = false
	_pid = 0
	_output = ""
	_release = ""


func after_test() -> void:
	if _pid > 0 and OS.is_process_running(_pid):
		OS.kill(_pid)
		await _until(func() -> bool: return not OS.is_process_running(_pid))
	_service.poll()
	for path: String in [_release, _release + ".ready", _output]:
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _launch(executable: String, arguments: PackedStringArray, console: bool) -> int:
	_output = arguments[arguments.find("--result-file") + 1]
	_release = _output + ".release"
	var actual: PackedStringArray = ["-B", ProjectSettings.globalize_path(STUB)]
	actual.append_array(arguments.slice(3))
	actual.append_array(["--case", _case])
	if _hold:
		actual.append_array(["--release-file", _release])
	_pid = OS.create_process(executable, actual, console)
	return _pid


func test_real_child_waits_for_publication_and_service_cleans_the_result() -> void:
	_hold = true
	assert_int(_start().error).is_equal(OK)
	await _until(func() -> bool: return FileAccess.file_exists(_release + ".ready"))
	assert_bool(FileAccess.file_exists(_release + ".ready")).is_true()
	assert_bool(OS.is_process_running(_pid)).is_true()
	assert_bool(FileAccess.file_exists(_output)).is_false()
	_service.poll()
	assert_array(_states).is_empty()
	var release_file := FileAccess.open(_release, FileAccess.WRITE)
	release_file.store_string("release")
	release_file.close()
	await _until(func() -> bool: return not OS.is_process_running(_pid))
	assert_bool(OS.is_process_running(_pid)).is_false()
	_service.poll()
	_service.poll()
	assert_int(_states.size()).is_equal(1)
	assert_str(_states[0].status).is_equal("success")
	var data: Dictionary = _states[0].data
	assert_int(data.metrics.size()).is_equal(9)
	assert_float(data.metrics.f0_median_hz.value).is_equal(440.0)
	assert_bool(FileAccess.file_exists(_output)).is_false()


func test_real_child_failed_result_keeps_error_detail() -> void:
	_case = "failed"
	assert_int(_start().error).is_equal(OK)
	await _until(func() -> bool: return not OS.is_process_running(_pid))
	_service.poll()
	assert_int(_states.size()).is_equal(1)
	assert_str(_states[0].status).is_equal("failed")
	assert_str(_states[0].detail).contains("decode_failed")
	assert_bool(_states[0].has("data")).is_false()
	assert_bool(FileAccess.file_exists(_output)).is_false()


func test_real_child_without_result_reports_interpreter_and_output_path() -> void:
	_case = "missing"
	assert_int(_start().error).is_equal(OK)
	await _until(func() -> bool: return not OS.is_process_running(_pid))
	_service.poll()
	assert_int(_states.size()).is_equal(1)
	assert_str(_states[0].message).is_equal("GAA 已退出，但没有可读结果")
	assert_str(_states[0].detail).contains(_service.audio_python)
	assert_str(_states[0].detail).contains(_output)


func _start() -> Dictionary:
	return _service.analyze(SOURCE, "audio",
		func(state: Dictionary) -> void: _states.append(state))


func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + WAIT_MSEC
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
