extends GdUnitTestSuite
## A stand-in launcher writes the worker's result file; librosa never runs here.

const Service := preload("res://dev/debug/_shared/analyzer_service.gd")
const AudioAnalysis := preload("res://dev/debug/_shared/audio_analysis.gd")
const ScreenshotAnalysis := preload("res://dev/debug/_shared/screenshot_analysis.gd")
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


func before_test() -> void:
	_service = auto_free(Service.new()) as Service
	add_child(_service)
	_service.python = OS.get_executable_path()
	_service.launch = _launch
	_service.running = func(_id: int) -> bool: return _running
	_service.set_process(false)
	_launched.clear()
	_result = {}
	_running = true
	_pid = 4242


func _launch(path: String, arguments: PackedStringArray, _console: bool) -> int:
	var request: Variant = JSON.parse_string(FileAccess.get_file_as_string(arguments[3]))
	_launched.append({"path": path, "arguments": arguments, "request": request})
	if not _result.is_empty():
		var file := FileAccess.open(arguments[5], FileAccess.WRITE)
		file.store_string(JSON.stringify(_result))
		file.close()
	return _pid


func test_audio_job_starts_polls_reads_and_shows_metrics_and_the_slot_action() -> void:
	var slot := _sfx_slot()
	var view := _audio_view()
	_result = _audio_result(1975.5, "B6", 0.96)
	view.show_candidate(slot, slot.live.candidate)
	assert_int(_launched.size()).is_equal(1)
	var job := _launched[0]
	assert_str(job.path).is_equal(OS.get_executable_path())
	assert_str(job.request.path).is_equal(ProjectSettings.globalize_path(CHIME))
	assert_str(job.request.asset_type).is_equal("audio")
	assert_array(job.request.modules).contains_exactly(AudioAnalysis.MODULES)
	assert_dict(job.request.parameters).is_empty()
	assert_bool(job.request.force).is_false()
	assert_str(_text(view)).contains("分析中…")
	_service.poll()
	assert_str(_text(view)).contains("分析中…")
	_running = false
	_service.poll()
	var expected := {"时长": "0.28 s", "真峰值": "-1.5 dBTP", "20 ms 最大 RMS": "-9.25 dBFS",
		"频谱重心": "3012.5 Hz", "基础音高 · 置信度 0.96": "B6 · 1975.5 Hz"}
	for caption: String in expected:
		assert_str(_tile_value(view, caption)).is_equal(expected[caption])
	assert_str(_text(view)).contains("归一后音量 2.0 dB")
	assert_bool(FileAccess.file_exists(ProjectSettings.localize_path(job.arguments[3]))).is_false()
	assert_bool(FileAccess.file_exists(ProjectSettings.localize_path(job.arguments[5]))).is_false()
	var fill := _button(view, "峰值归一")
	assert_bool(fill.disabled).is_false()
	var edits: Array[int] = []
	var texts: PackedStringArray = []
	view.edited.connect(func(result: Dictionary) -> void:
		edits.append(1)
		texts.append(result.text))
	fill.pressed.emit()
	assert_float(slot.live.volume_db).is_equal(2.0)
	assert_int(edits.size()).is_equal(1)
	assert_array(texts).contains_exactly(["已按峰值设置音量 2.0 dB"])
	# Each file is analyzed once per session.
	view.show_candidate(slot, slot.live.candidate)
	assert_int(_launched.size()).is_equal(1)


func test_missing_metric_disables_the_slot_action_and_explains_why() -> void:
	var slot := _sfx_slot()
	var view := _audio_view()
	_result = _audio_result(0.0, "", 0.45)
	_result.metrics.sample_peak = {"status": "not_applicable", "value": null, "unit": "",
		"reason": "silent"}
	view.show_candidate(slot, slot.live.candidate)
	_running = false
	_service.poll()
	var fill := _button(view, "峰值归一")
	assert_bool(fill.disabled).is_true()
	assert_str(fill.tooltip_text).contains("没有算出峰值")
	assert_str(_text(view)).contains("基础音高 · 置信度 0.45")
	assert_str(_text(view)).contains("无明确音高（normal for noise）")


func test_failures_and_missing_configuration_show_a_summary() -> void:
	var slot := _sfx_slot()
	var cases: Array[Dictionary] = [
		{"pid": -1, "result": {}, "text": "无法启动 analyzer"},
		{"pid": 7, "result": {}, "text": "analyzer 已退出，但没有写出结果"},
		{"pid": 7, "result": {"status": "failed", "metrics": {},
			"errors": [{"code": "decode_failed", "message": "bad stream"}]},
			"text": "分析失败：analyzer 无法分析这个文件。悬停这行文字看原因"},
	]
	for item in cases:
		var view := _audio_view()
		_pid = item.pid
		_result = item.result
		_running = false
		view.show_candidate(slot, slot.live.candidate)
		_service.poll()
		assert_str(_text(view)).contains(item.text)
	_service.python = "C:/missing/python.exe"
	var unconfigured := _audio_view()
	unconfigured.show_candidate(slot, slot.live.candidate)
	assert_str(_text(unconfigured)).is_equal("分析\nchime.wav\n未配置 analyzer，分析不可用；其他功能照常")


func test_screenshot_request_points_at_saved_png_and_shows_the_grid() -> void:
	var grid := "user://tests/analysis-grid-%d.png" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(grid.get_base_dir())
	Image.create(8, 4, false, Image.FORMAT_RGBA8).save_png(grid)
	_result = {"status": "success", "errors": [], "metrics": {"cvd_grid": {"status": "available",
		"value": {"path": ProjectSettings.globalize_path(grid)}, "unit": "PNG", "reason": ""}}}
	var view := auto_free(ScreenshotAnalysis.new(_service)) as ScreenshotAnalysis
	add_child(view)
	view.capture(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	var request: Dictionary = _launched[0].request
	var screenshot := ProjectSettings.localize_path(request.path)
	assert_str(screenshot.get_base_dir()).is_equal(Service.JOBS)
	assert_bool(FileAccess.file_exists(screenshot)).is_true()
	assert_str(request.asset_type).is_equal("image")
	assert_array(request.modules).contains_exactly(["image_cvd_grid"])
	_running = false
	_service.poll()
	assert_int(view.tiles.get_child_count()).is_equal(4)
	var captions: PackedStringArray = []
	for tile in view.tiles.get_children():
		var image := tile.find_children("*", "TextureRect", true, false)[0] as TextureRect
		assert_vector((image.texture as AtlasTexture).region.size).is_equal(Vector2(4, 2))
		captions.append((tile.find_children("*", "Label", true, false)[0] as Label).text)
	assert_array(captions).contains_exactly(["正常", "灰度", "红色盲", "绿色盲"])
	var last := view.tiles.get_child(3).find_children("*", "TextureRect", true, false)[0]
	assert_vector((last.texture as AtlasTexture).region.position).is_equal(Vector2(4, 2))
	var open := _tooltip_button(view, "打开原图")
	assert_bool(open.visible and not open.disabled).is_true()
	assert_str(view.grid_path).is_equal(ProjectSettings.globalize_path(grid))
	DirAccess.remove_absolute(screenshot)
	DirAccess.remove_absolute(grid)


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


func _audio_result(hz: float, note: String, confidence: float) -> Dictionary:
	var metrics := {
		"duration": _metric(0.28, "s"), "sample_peak": _metric(-2.0, "dBFS"),
		"true_peak": _metric(-1.5, "dBTP"), "rms": _metric(-14.0, "dBFS"),
		"max_rms_20ms": _metric(-9.25, "dBFS"), "attack_10_90": _metric(0.002, "s"),
		"decay_to_10": _metric(0.21, "s"), "spectral_centroid": _metric(3012.5, "Hz"),
		"pitch_confidence": _metric(confidence, "ratio"),
	}
	if note.is_empty():
		for key: String in ["pitch", "pitch_note"]:
			metrics[key] = {"status": "not_applicable", "value": null, "unit": "",
				"reason": "normal for noise"}
	else:
		metrics.pitch = _metric(hz, "Hz")
		metrics.pitch_note = _metric(note, "note")
	return {"status": "success", "errors": [], "metrics": metrics}


func _metric(value: Variant, unit: String) -> Dictionary:
	return {"status": "available", "value": value, "unit": unit, "reason": ""}


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


func _tooltip_button(node: Node, prefix: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).tooltip_text.begins_with(prefix):
			return child
	return null


func _button(node: Node, caption: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).text == caption:
			return child
	return null
