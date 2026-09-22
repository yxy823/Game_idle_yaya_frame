extends SceneTree

## Maintenance-only E4 measurement, using real presenters at visible screen positions.
## Frame intervals include this harness and the OS; they are not isolated GPU timings.

const ObjectView = preload("res://components/feedback/feedback_object.gd")
const BASE: String = "res://examples/asset_workbench/effects_composition/"
const REPORT: String = "res://reports/asset-workbench-e3-e4-20260922/"
const ROLES: Array[String] = ["core", "local", "world"]

var _objects: Array[ObjectView] = []
var _host: Control
var _failed: bool = false
var _errors: Array[String] = []
var _output: String
var _baseline_nodes: int
var _baseline_orphans: int


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Scale measurement requires an actual display/rendering device.")
		quit(1)
		return
	root.size = Vector2i(1600, 900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_output = REPORT + String(RenderingServer.get_current_rendering_method()) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	await create_timer(1.1).timeout
	_baseline_nodes = get_node_count()
	_baseline_orphans = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var result := _environment()
	for count: int in [8, 32, 128]:
		var started := Time.get_ticks_usec()
		_spawn(count)
		var setup_ms := float(Time.get_ticks_usec() - started) / 1000.0
		await _sample(2.0, 0.6)
		var measured: Dictionary = {"count": count, "setup_cpu_ms": setup_ms,
			"repeat": await _sample(8.0, 0.6), "rapid": await _sample(8.0, 0.1)}
		measured["live"] = _snapshot()
		await _capture("scale-%d.png" % count)
		await _dispose()
		await create_timer(1.1).timeout
		measured["after_free"] = _snapshot()
		result["scales"].append(measured)
	_spawn(128)
	await _sample(2.0)
	result["sustained"] = await _sample(120.0)
	await _dispose()
	await create_timer(1.1).timeout
	result["after_sustained"] = _snapshot()
	result["reload_cycles"] = await _reload_cycles()
	result["passed"] = not _failed
	result["errors"] = _errors
	var file := FileAccess.open(_output + "scale-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	file.close()
	quit(1 if _failed else 0)


func _environment() -> Dictionary:
	return {"engine": Engine.get_version_info(), "os": OS.get_name(),
		"cpu": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(),
		"api": RenderingServer.get_video_adapter_api_version(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y], "vsync": "disabled", "fps_cap": 0,
		"audio": "bindings cleared only in probe drafts; audio regression is separate",
		"particle_delay": "zero in probe drafts so rapid retriggers do not prevent emission",
		"interval_seconds": [0.6, 0.1], "baseline": _snapshot(), "scales": []}


func _spawn(count: int) -> void:
	_host = Control.new()
	root.add_child(_host)
	var columns := ceili(sqrt(float(count) * 16.0 / 9.0))
	var rows := ceili(float(count) / columns)
	var cell := Vector2(1600.0 / columns, 900.0 / rows)
	for index: int in count:
		var object := ObjectView.new()
		object.name = "Object%d" % index
		object.text = "%d / %s" % [index + 1, ROLES[index % 3]]
		object.cue_path = BASE + "example-cluster-" + ROLES[index % 3] + "-cue.tres"
		object.position = Vector2(index % columns, floori(float(index) / columns)) * cell
		object.size = cell - Vector2(4, 4)
		_host.add_child(object)
		var cue := object.cue.trial_copy()
		cue.sound = null
		cue.particle_delay_seconds = 0.0
		object.preview(cue)
		object.presenter.playback_failed.connect(_error)
		_objects.append(object)


func _sample(seconds: float, interval: float = 0.1) -> Dictionary:
	var intervals: Array[float] = []
	var batch_times: Array[float] = []
	var snapshots: Array[Dictionary] = []
	var started := Time.get_ticks_usec()
	var previous := started
	var next_trigger: float = 0.0
	var next_snapshot: float = 0.0
	var triggers: int = 0
	var peak_effects: int = 0
	while float(Time.get_ticks_usec() - started) / 1000000.0 < seconds:
		var elapsed := float(Time.get_ticks_usec() - started) / 1000000.0
		if elapsed >= next_trigger:
			var batch_started := Time.get_ticks_usec()
			for object: ObjectView in _objects:
				object.presenter.trigger()
			batch_times.append(float(Time.get_ticks_usec() - batch_started) / 1000.0)
			next_trigger = elapsed + interval
			triggers += 1
		if elapsed >= next_snapshot:
			var snapshot := _snapshot()
			snapshot["elapsed_seconds"] = elapsed
			snapshots.append(snapshot)
			peak_effects = maxi(peak_effects, _active_effects())
			next_snapshot = elapsed + 10.0
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append(float(now - previous) / 1000.0)
		previous = now
	return {"elapsed_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"frames": intervals.size(), "trigger_batches": triggers,
		"peak_sampled_effects": peak_effects, "frame_interval_ms": _distribution(intervals),
		"trigger_batch_cpu_ms": _distribution(batch_times), "snapshots": snapshots}


func _distribution(values: Array[float]) -> Dictionary:
	values.sort()
	return {"median": values[floori((values.size() - 1) * 0.5)],
		"p95": values[floori((values.size() - 1) * 0.95)],
		"p99": values[floori((values.size() - 1) * 0.99)], "max": values.back()}


func _snapshot() -> Dictionary:
	return {"nodes": get_node_count(),
		"engine_process_monitor_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"engine_static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"render_video_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"emitters": _emitter_count(), "active_effects": _active_effects()}


func _emitter_count() -> int:
	var count: int = 0
	for object: ObjectView in _objects:
		count += object.presenter.get("_particles").get_child_count()
	return count


func _active_effects() -> int:
	var count: int = 0
	for object: ObjectView in _objects:
		count += object.presenter.active_effect_count()
	return count


func _dispose() -> void:
	for object: ObjectView in _objects:
		object.presenter.stop()
		if object.presenter.active_effect_count() != 0 or object.presenter.active_voice_count() != 0:
			_error("Stop left active playback.")
	_objects.clear()
	_host.queue_free()
	await process_frame
	await process_frame
	if get_node_count() != _baseline_nodes:
		_error("Free left live scene nodes.")


func _reload_cycles() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for cycle: int in 10:
		_spawn(32)
		await _sample(0.3)
		await _dispose()
		await create_timer(1.1).timeout
		var snapshot := _snapshot()
		snapshot["cycle"] = cycle + 1
		output.append(snapshot)
		if int(snapshot["orphans"]) != _baseline_orphans:
			_error("Reload cycle left orphan nodes.")
	return output


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture.save_png(_output + filename) != OK:
		_error("Failed to write scale screenshot.")


func _error(message: String) -> void:
	_failed = true
	if message not in _errors:
		_errors.append(message)
		push_error(message)
