extends GdUnitTestSuite
## A replaceable launcher writes result files; these tests never run real GAA.

const Service := preload("res://dev/debug/_shared/analyzer_service.gd")
const AudioAnalysis := preload("res://dev/debug/_shared/audio_analysis.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const SoundSlot := preload(
	"res://dev/debug/_shared/tests/fixtures/sample/debug/sample/slots/feedback/sound/slot.gd")
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const CHIME := SAMPLE + "debug/sample/slots/feedback/sound/chime/chime.wav"
const SOUND_TUNING := SAMPLE + "game/sample/tuning/feedback/sound_tuning.gd"

var _service: Service
var _launched: Array[Dictionary] = []
var _result: Dictionary = {}
var _running: bool = true
var _pid: int = 4242
var _raw_output: String = ""


func before_test() -> void:
	_service = auto_free(Service.new()) as Service
	add_child(_service)
	_service.audio_python = OS.get_executable_path()
	_service.launch = _launch
	_service.running = func(_id: int) -> bool: return _running
	_service.set_process(false)
	_launched.clear()
	_result = {}
	_raw_output = ""
	_running = true
	_pid = 4242


func after_test() -> void:
	_running = false
	_service.poll()


func _launch(path: String, arguments: PackedStringArray, console: bool) -> int:
	var output := arguments[arguments.find("--result-file") + 1]
	var job := {"path": path, "arguments": arguments, "output": output, "console": console,
		"existed": FileAccess.file_exists(output)}
	_launched.append(job)
	if not _result.is_empty() or not _raw_output.is_empty():
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(_raw_output if not _raw_output.is_empty() else JSON.stringify(_result))
		file.close()
	return _pid


func test_audio_job_uses_gaa_arguments_and_shows_all_nine_metrics() -> void:
	var slot := _sfx_slot()
	var view := _audio_view()
	_result = _audio_result()
	view.show_candidate(slot, slot.live.candidate)
	var job := _launched[0]
	var args: PackedStringArray = job.arguments
	assert_str(job.path).is_equal(_service.audio_python)
	assert_array(Array(args)).contains_exactly(["-B", "-m", "gaa", "analyze",
		ProjectSettings.globalize_path(CHIME), "--result-file", job.output])
	assert_bool(job.console or job.existed).is_false()
	_service.poll()
	assert_str(_text(view)).contains("分析中…")
	_running = false
	_service.poll()
	var expected := {"基础音高": "B6 · 1975.5 Hz（估算）", "时长": "0.28 s",
		"峰值": "-2.0 dBFS", "真峰值": "-1.5 dBTP（估算）", "RMS": "-14.0 dBFS",
		"20 ms 最大 RMS": "-9.25 dBFS（估算）", "起音 10%→90%": "0.002 s（估算）",
		"衰减至 10%": "0.21 s（估算）", "频谱重心": "3012.5 Hz（估算）"}
	for caption: String in expected:
		assert_str(_tile_value(view, caption)).is_equal(expected[caption])
	assert_str(_text(view)).not_contains("置信度")
	assert_bool(FileAccess.file_exists(job.output)).is_false()
	view.show_candidate(slot, slot.live.candidate)
	_service.poll()
	assert_int(_launched.size()).is_equal(1)


func test_peak_action_uses_gaa_peak_and_accepts_zero() -> void:
	var slot := _sfx_slot()
	var view := _audio_view()
	_result = _audio_result()
	view.show_candidate(slot, slot.live.candidate)
	_running = false
	_service.poll()
	assert_str(_text(view)).contains("归一后音量 2.0 dB")
	var edits: PackedStringArray = []
	view.edited.connect(func(result: Dictionary) -> void: edits.append(result.text))
	var fill := _button(view, "峰值归一")
	assert_bool(fill.disabled).is_false()
	fill.pressed.emit()
	assert_float(slot.live.volume_db).is_equal(2.0)
	assert_array(edits).contains_exactly(["已按峰值设置音量 2.0 dB"])
	var extras := SoundSlot.new().analysis_extras(slot.live, {"peak_dbfs": _metric(0.0, "dBFS")})
	assert_str(extras.reason).is_empty()
	extras.apply.call()
	assert_float(slot.live.volume_db).is_equal(0.0)


func test_unavailable_metrics_show_status_and_note_without_zero_or_note_name() -> void:
	var reasons := {"silent": "静音", "not_applicable": "不适用",
		"insufficient_data": "数据不足", "below_threshold": "低于筛选阈值",
		"not_analyzed": "未分析", "disabled": "已关闭"}
	for state: String in reasons:
		var entry := {"value": null, "unit": "Hz", "status": state, "note": "fixture reason"}
		var expected := "%s（fixture reason）" % reasons[state]
		assert_str(AudioAnalysis._format(entry)).is_equal(expected)
		assert_str(AudioAnalysis._pitch({"f0_median_hz": entry})).is_equal(expected)
	assert_str(AudioAnalysis._format(_metric(null, "dBFS"))).contains("无数值")
	var slot := _sfx_slot()
	var view := _audio_view()
	_result = _audio_result()
	_result.metrics.peak_dbfs = {"value": null, "unit": "dBFS",
		"status": "silent", "note": "All zero"}
	_result.metrics.f0_median_hz = {"value": null, "unit": "Hz",
		"status": "not_applicable", "note": "No periodic signal"}
	view.show_candidate(slot, slot.live.candidate)
	_running = false
	_service.poll()
	var fill := _button(view, "峰值归一")
	assert_bool(fill.disabled).is_true()
	assert_str(fill.tooltip_text).contains("没有算出峰值")
	assert_str(_tile_value(view, "基础音高")).is_equal("不适用（No periodic signal）")


func test_pitch_uses_equal_temperament_and_keeps_estimate_state() -> void:
	for pair: Array in [[440.0, "A4"], [261.625565, "C4"], [1975.533, "B6"], [880.0, "A5"]]:
		var entry := _metric(pair[0], "Hz", "estimate")
		assert_str(AudioAnalysis._pitch({"f0_median_hz": entry})).starts_with(pair[1] + " · ")
		assert_str(AudioAnalysis._pitch({"f0_median_hz": entry})).ends_with("（估算）")
	assert_str(AudioAnalysis._pitch({"f0_median_hz": _metric(0.0, "Hz")})).is_equal("0.0 Hz")


func test_failed_result_shows_error_instead_of_metrics() -> void:
	_running = false
	var slot := _sfx_slot()
	var view := _audio_view()
	_result = _audio_result()
	_result.merge({"status": "failed", "metrics": null,
		"error": {"code": "decode_failed", "message": "Fixture failure"}}, true)
	view.show_candidate(slot, slot.live.candidate)
	_service.poll()
	assert_str(_text(view)).contains("GAA 未完成分析")
	var labels := view.find_children("*", "Label", true, false)
	assert_str((labels.back() as Label).tooltip_text).contains("decode_failed")
	assert_str(_tile_value(view, "时长")).is_empty()
	assert_object(_button(view, "峰值归一")).is_null()


func test_launch_missing_result_and_configuration_failures_are_readable() -> void:
	var slot := _sfx_slot()
	_running = false
	for item: Dictionary in [
		{"pid": -1, "raw": "", "text": "无法启动 GAA"},
		{"pid": 7, "raw": "", "text": "GAA 已退出，但没有可读结果"},
		{"pid": 7, "raw": "{broken", "text": "GAA 已退出，但没有可读结果"}]:
		var view := _audio_view()
		_pid = item.pid
		_raw_output = item.raw
		view.show_candidate(slot, slot.live.candidate)
		_service.poll()
		assert_str(_text(view)).contains(item.text)
		assert_bool(FileAccess.file_exists(_launched.back().output)).is_false()
		if item.pid > 0:
			var labels := view.find_children("*", "Label", true, false)
			var detail := (labels.back() as Label).tooltip_text
			assert_str(detail).contains(_service.audio_python)
			assert_str(detail).contains(_launched.back().output)
	for executable: String in ["", "C:/missing/python.exe"]:
		_service.audio_python = executable
		var unconfigured := _audio_view()
		unconfigured.show_candidate(slot, slot.live.candidate)
		assert_str(_text(unconfigured)).is_equal("分析\nchime.wav\n未配置 GAA")


func test_jobs_have_unique_paths_and_callbacks() -> void:
	_result = _audio_result()
	var states: Array[Dictionary] = []
	var done := func(state: Dictionary) -> void: states.append(state)
	for _index in range(2):
		assert_int(_service.analyze(CHIME, "audio", done).error).is_equal(OK)
	assert_str(_launched[0].output).is_not_equal(_launched[1].output)
	for job in _launched:
		assert_bool(job.existed).is_false()
		assert_bool(FileAccess.file_exists(job.output)).is_true()
	_service.poll()
	assert_array(states).is_empty()
	_running = false
	_service.poll()
	_service.poll()
	assert_int(states.size()).is_equal(2)
	for job in _launched:
		assert_bool(FileAccess.file_exists(job.output)).is_false()


func _sfx_slot() -> Slot:
	var slot := Slot.new()
	var config: Resource = (load(SOUND_TUNING) as Script).new()
	config.candidate = load(CHIME) as AudioStream
	slot.live = config
	slot.actions = SoundSlot.new()
	return slot


func _audio_view() -> AudioAnalysis:
	var view := auto_free(AudioAnalysis.new(_service)) as AudioAnalysis
	add_child(view)
	return view


func _audio_result() -> Dictionary:
	return {"status": "completed", "file": {"path": ProjectSettings.globalize_path(CHIME)},
		"warnings": [], "error": null, "metrics": {
			"f0_median_hz": _metric(1975.5, "Hz", "estimate"),
			"duration_s": _metric(0.28, "s"), "peak_dbfs": _metric(-2.0, "dBFS"),
			"true_peak_estimate_dbtp": _metric(-1.5, "dBTP", "estimate"),
			"rms_dbfs": _metric(-14.0, "dBFS"),
			"max_rms_20ms_dbfs": _metric(-9.25, "dBFS", "estimate"),
			"attack_10_90_s": _metric(0.002, "s", "estimate"),
			"decay_to_10_s": _metric(0.21, "s", "estimate"),
			"spectral_centroid_hz": _metric(3012.5, "Hz", "estimate")}}


func _metric(value: Variant, unit: String, status: String = "ok") -> Dictionary:
	return {"status": status, "value": value, "unit": unit, "note": "Fixture metric"}


func _text(node: Node) -> String:
	var lines: PackedStringArray = []
	for child in node.find_children("*", "Label", true, false):
		lines.append((child as Label).text)
	return "\n".join(lines)


func _tile_value(node: Node, caption: String) -> String:
	for tile in node.find_children("*", "PanelContainer", true, false):
		var labels := tile.find_children("*", "Label", true, false)
		if tile.theme_type_variation == &"MetricTile" and (labels[0] as Label).text == caption:
			return (labels[1] as Label).text
	return ""


func _button(node: Node, caption: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).text == caption:
			return child
	return null
