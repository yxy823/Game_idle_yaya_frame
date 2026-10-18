extends SceneTree
## Measures 3D placeholders on screen against the project's thresholds: silhouette size, how far
## each item reaches past its slot, how much its neighbours hide it, and frame time.
## Needs a real window: headless rendering produces no images.
## Usage: godot --path . --script res://yaya/tools/godot/measure-3d/measure_3d.gd -- <request.json>
## The request names a project adapter that opens the scene and lists the subjects; see
## example_adapter.gd and yaya/tools/README.md.

const Metrics := preload("res://yaya/tools/godot/measure-3d/silhouette_metrics.gd")
const THRESHOLD_KEYS: Array[String] = ["max_protrusion_ratio", "max_neighbor_occlusion", "min_long_edge_px"]
const SETTLE_FRAMES := 3
## Pixels added around a subject's projected bounding box before scanning its masks.
const REGION_MARGIN := 64
const USEC_PER_MSEC := 1000.0
const P95 := 0.95

var _request: Dictionary = {}
var _out_dir: String = ""
var _white := _material(Color.WHITE)
var _black := _material(Color.BLACK)


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("measure_3d needs a real window; headless rendering produces no images. Run without --headless.")
		quit(2)
		return
	var problem := _read_request()
	if not problem.is_empty():
		printerr("measure_3d: " + problem)
		quit(2)
		return
	_run.call_deferred()


func _read_request() -> String:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		return "pass exactly one request file after --"
	var path := args[0] if args[0].begins_with("res://") else "res://" + args[0]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return "cannot read the request JSON at " + path
	_request = parsed
	var problem := _field_problem(_request)
	if problem.is_empty():
		_out_dir = ProjectSettings.globalize_path("res://" + String(_request.out))
	return problem


static func _field_problem(request: Dictionary) -> String:
	for key: String in ["adapter", "out"]:
		if not request.get(key) is String or String(request[key]).is_empty():
			return "request needs a non-empty \"%s\" string" % key
	var window: Variant = request.get("window")
	if not (window is Array and window.size() == 2):
		return "request needs \"window\": [width, height]"
	var thresholds: Variant = request.get("thresholds")
	for key in THRESHOLD_KEYS:
		var value: Variant = thresholds.get(key) if thresholds is Dictionary else null
		if not (value is float or value is int):
			return "request needs the number thresholds.%s; take it from the project's Art Bible" % key
	return ""


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(int(_request.window[0]), int(_request.window[1])))
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var adapter: RefCounted = load(_request.adapter).new()
	var results := {"environment": _environment_info(), "variants": {}}
	var perf: Dictionary = _request.get("perf", {})
	for variant: String in adapter.variants():
		var scene: Node = await adapter.open(self, variant)
		await _wait_frames(SETTLE_FRAMES)
		DirAccess.make_dir_recursive_absolute(_out_dir.path_join(variant))
		await _capture(_out_dir.path_join(variant + ".png"))
		var measured := await _measure_variant(variant, adapter.subjects(scene))
		if measured.has("error"):
			adapter.close(scene)
			_finish(results, "%s: %s" % [variant, measured.error])
			return
		results.variants[variant] = measured
		if perf.get("variant") == variant:
			results["performance"] = await _sample_perf(int(perf.get("warmup_frames", 120)),
				int(perf.get("sample_frames", 600)))
		adapter.close(scene)
	_finish(results, "")


func _measure_variant(variant: String, subjects: Array) -> Dictionary:
	var by_id := {}
	for subject: Dictionary in subjects:
		by_id[subject.id] = subject
	var restore := _mask_mode(true)
	var measured: Array[Dictionary] = []
	for subject: Dictionary in subjects:
		var region := _screen_region(subject.node)
		var alone := Metrics.mask(await _render([subject.node], subject.node, variant, subject.id + "-full"), region)
		var entry := Metrics.dimensions(alone)
		if entry.error != OK:
			_mask_mode(false, restore)
			return {"error": "%s: %s" % [subject.id, entry.message]}
		entry.erase("error")
		entry["id"] = subject.id
		entry["kind"] = subject.kind
		if subject.kind == "item":
			var outline := PackedVector2Array()
			for corner: Vector3 in subject.slot_corners:
				outline.append(_camera().unproject_position(corner))
			entry["protrusion"] = Metrics.protrusion(alone, outline)
			var together: Array[Node3D] = [subject.node]
			for neighbor: String in subject.get("neighbors", []):
				together.append(by_id[neighbor].node)
			var shown := Metrics.mask(await _render(together, subject.node, variant, subject.id + "-neighbors"), region)
			var hidden := Metrics.occlusion(alone, shown)
			if hidden.error != OK:
				_mask_mode(false, restore)
				return {"error": "%s: %s" % [subject.id, hidden.message]}
			entry["neighbor_hidden_pixels"] = hidden.hidden_pixels
			entry["neighbor_occlusion"] = hidden.ratio
		measured.append(entry)
	_mask_mode(false, restore)
	return {"subjects": measured, "summary": _summary(measured)}


func _summary(measured: Array[Dictionary]) -> Dictionary:
	var items := measured.filter(func(entry: Dictionary) -> bool: return entry.kind == "item")
	var enemies := measured.filter(func(entry: Dictionary) -> bool: return entry.kind == "enemy")
	return {
		"max_protrusion": _extreme(_field(items, "protrusion", "ratio"), true),
		"max_protrusion_px": _extreme(_field(items, "protrusion", "pixels"), true),
		"max_neighbor_occlusion": _extreme(_field(items, "neighbor_occlusion"), true),
		"min_item_long_edge": _extreme(_field(items, "long_edge"), false),
		"min_enemy_long_edge": _extreme(_field(enemies, "long_edge"), false),
		"min_long_edge": _extreme(_field(measured, "long_edge"), false),
		"min_short_edge": _extreme(_field(measured, "short_edge"), false),
	}


## entry[key], or entry[key][inner] when inner is given, for every entry.
static func _field(entries: Array, key: String, inner: String = "") -> Array:
	return entries.map(func(entry: Dictionary) -> Variant:
		return entry[key] if inner.is_empty() else entry[key][inner])


## Largest or smallest value; null when there is none, for example a variant without enemies.
static func _extreme(values: Array, largest: bool) -> Variant:
	if values.is_empty():
		return null
	return values.max() if largest else values.min()


func _checks(results: Dictionary) -> Array[Dictionary]:
	var thresholds: Dictionary = _request.thresholds
	var rules := [["max_protrusion_ratio", "max_protrusion", true],
		["max_neighbor_occlusion", "max_neighbor_occlusion", true], ["min_long_edge_px", "min_long_edge", false]]
	var checks: Array[Dictionary] = []
	for rule: Array in rules:
		var values := []
		for variant: Dictionary in results.variants.values():
			if variant.summary[rule[1]] != null:
				values.append(variant.summary[rule[1]])
		var value: Variant = _extreme(values, rule[2])
		var limit: float = thresholds[rule[0]]
		var passed: bool = value != null and (value <= limit if rule[2] else value >= limit)
		checks.append({"name": rule[0], "value": value, "threshold": limit, "pass": passed})
	return checks


func _finish(results: Dictionary, failure: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var code := 2
	if failure.is_empty():
		results["checks"] = _checks(results)
		results["pass"] = results.checks.all(func(check: Dictionary) -> bool: return check.pass)
		code = 0 if results.pass else 1
	else:
		results["error"] = failure
		printerr("measure_3d: " + failure)
	var file := FileAccess.open(_out_dir.path_join("measurements.json"), FileAccess.WRITE)
	if file == null:
		printerr("measure_3d: cannot write " + _out_dir.path_join("measurements.json"))
		code = 2
	else:
		file.store_string(JSON.stringify(results, "  "))
		file.close()
	for check: Dictionary in results.get("checks", []):
		if not check.pass:
			printerr("measure_3d: %s is %s, threshold %s" % [check.name, check.value, check.threshold])
	quit(code)


## Mask conditions: black background, linear tone mapping, no MSAA, no 2D overlays. Called with
## true it applies them and returns what to restore; with false it restores.
func _mask_mode(enable: bool, saved: Dictionary = {}) -> Dictionary:
	if not enable:
		root.msaa_3d = saved.msaa
		for entry: Array in saved.environments:
			var environment: Environment = entry[0]
			environment.background_mode = entry[1]
			environment.background_color = entry[2]
			environment.tonemap_mode = entry[3]
		for entry: Array in saved.layers:
			entry[0].visible = entry[1]
		for entry: Array in saved.geometry:
			entry[0].visible = entry[1]
			entry[0].material_override = entry[2]
		return {}
	var state := {"msaa": root.msaa_3d, "environments": [], "layers": [], "geometry": []}
	root.msaa_3d = Viewport.MSAA_DISABLED
	for environment in _environments():
		state.environments.append([environment, environment.background_mode, environment.background_color,
			environment.tonemap_mode])
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color.BLACK
		environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	for layer: CanvasLayer in root.find_children("*", "CanvasLayer", true, false):
		state.layers.append([layer, layer.visible])
		layer.hide()
	for geometry: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		state.geometry.append([geometry, geometry.visible, geometry.material_override])
	return state


func _environments() -> Array[Environment]:
	var found: Array[Environment] = []
	for node: WorldEnvironment in root.find_children("*", "WorldEnvironment", true, false):
		if node.environment != null:
			found.append(node.environment)
	var camera := _camera()
	if camera != null and camera.environment != null and not camera.environment in found:
		found.append(camera.environment)
	return found


## Renders only models, the subject white and the others black, and saves the frame as
## <out>/<variant>/<file_name>.png.
func _render(models: Array[Node3D], subject: Node3D, variant: String, file_name: String) -> Image:
	for geometry: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		geometry.visible = false
	for model in models:
		for geometry in _geometry(model):
			geometry.visible = true
			geometry.material_override = _white if model == subject else _black
	await _wait_frames(SETTLE_FRAMES)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_out_dir.path_join(variant).path_join(file_name + ".png"))
	return image


func _capture(path: String) -> void:
	await _wait_frames(SETTLE_FRAMES)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


## The subject's projected bounding box plus REGION_MARGIN; the silhouette cannot leave it.
func _screen_region(model: Node3D) -> Rect2i:
	var camera := _camera()
	var bounds := Rect2()
	var first := true
	for geometry in _geometry(model):
		var box := geometry.global_transform * geometry.get_aabb()
		for index in 8:
			var point := camera.unproject_position(box.get_endpoint(index))
			bounds = Rect2(point, Vector2.ZERO) if first else bounds.expand(point)
			first = false
	return Rect2i(bounds.grow(REGION_MARGIN))


func _geometry(model: Node3D) -> Array[GeometryInstance3D]:
	var found: Array[GeometryInstance3D] = []
	if model is GeometryInstance3D:
		found.append(model)
	for node: GeometryInstance3D in model.find_children("*", "GeometryInstance3D", true, false):
		found.append(node)
	return found


func _camera() -> Camera3D:
	return root.get_viewport().get_camera_3d()


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _sample_perf(warmup: int, frames: int) -> Dictionary:
	await _wait_frames(warmup)
	var viewport_rid := root.get_viewport_rid()
	var frame_ms: Array[float] = []
	var cpu_ms := 0.0
	var gpu_ms := 0.0
	var last := Time.get_ticks_usec()
	for _frame in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_ms.append((now - last) / USEC_PER_MSEC)
		last = now
		cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
		gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	frame_ms.sort()
	var total := 0.0
	for value in frame_ms:
		total += value
	return {
		"frames": frames,
		"frame_ms_avg": total / frames,
		"frame_ms_p95": frame_ms[int(frame_ms.size() * P95)],
		"frame_ms_max": frame_ms[-1],
		"render_cpu_ms_avg": cpu_ms / frames,
		"render_gpu_ms_avg": gpu_ms / frames,
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
	}


func _environment_info() -> Dictionary:
	return {
		"godot": Engine.get_version_info()["string"],
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"cpu": OS.get_processor_name(),
		"window": [int(_request.window[0]), int(_request.window[1])],
		"vsync": "disabled",
		"msaa_3d": root.msaa_3d,
	}


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
