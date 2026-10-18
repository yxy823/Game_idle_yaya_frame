extends SceneTree
## Contracts for yaya/tools/godot/measure-3d/silhouette_metrics.gd on generated images.
## Usage: godot --headless --path . --script res://tests/contracts/measure_3d_contracts.gd -- <report.json>

const Metrics := preload("res://yaya/tools/godot/measure-3d/silhouette_metrics.gd")
const SIZE := Vector2i(40, 40)

var _failures: PackedStringArray = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("pass exactly one report path after --")
		quit(2)
		return
	_dimensions()
	_threshold_and_format()
	_protrusion()
	_occlusion()
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": _failures}, "  "))
	file.close()
	for failure in _failures:
		printerr(failure)
	print("measure_3d contracts: %d failures" % _failures.size())
	quit(1 if not _failures.is_empty() else 0)


func _image(white: Array[Rect2i], format: Image.Format = Image.FORMAT_RGB8) -> Image:
	var image := Image.create_empty(SIZE.x, SIZE.y, false, format)
	image.fill(Color.BLACK)
	for rect in white:
		image.fill_rect(rect, Color.WHITE)
	return image


func _expect(name: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [name, expected, actual])


func _whole() -> Rect2i:
	return Rect2i(Vector2i.ZERO, SIZE)


func _dimensions() -> void:
	var measured := Metrics.dimensions(Metrics.mask(_image([Rect2i(5, 7, 10, 30)]), _whole()))
	_expect("dimensions bounds", measured.bounds, [5, 7, 15, 37])
	_expect("dimensions edges", [measured.long_edge, measured.short_edge, measured.area], [30, 10, 300])
	var clipped := Metrics.mask(_image([Rect2i(30, 30, 20, 20)]), Rect2i(20, 20, 60, 60))
	_expect("region is clipped to the image", clipped.region, Rect2i(20, 20, 20, 20))
	_expect("empty silhouette", Metrics.dimensions(Metrics.mask(_image([]), _whole())).error, ERR_INVALID_DATA)


func _threshold_and_format() -> void:
	var image := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	image.fill_rect(Rect2i(0, 0, 4, 4), Color8(127, 255, 255))
	image.fill_rect(Rect2i(10, 10, 2, 2), Color8(128, 128, 128))
	var measured := Metrics.dimensions(Metrics.mask(image, _whole()))
	_expect("only channels above 127 count, RGBA input", [measured.bounds, measured.area], [[10, 10, 12, 12], 4])


func _protrusion() -> void:
	var outline := PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 20), Vector2(0, 20)])
	var inside := Metrics.protrusion(Metrics.mask(_image([Rect2i(2, 2, 10, 10)]), _whole()), outline)
	_expect("inside the slot", inside.pixels, 0.0)
	var reaching := Metrics.protrusion(Metrics.mask(_image([Rect2i(5, 5, 5, 5), Rect2i(29, 10, 1, 1)]), _whole()),
		outline)
	_expect("protrusion distance", reaching.pixels, 9.5)
	_expect("protrusion ratio", reaching.ratio, 0.475)
	_expect("protrusion extremity", reaching.extremity, [29.5, 10.5])


func _occlusion() -> void:
	var alone := Metrics.mask(_image([Rect2i(0, 0, 10, 10)]), _whole())
	var shown := Metrics.mask(_image([Rect2i(0, 0, 10, 10)]), _whole())
	_expect("nothing hidden", Metrics.occlusion(alone, shown).ratio, 0.0)
	var covered := _image([Rect2i(0, 0, 10, 10)])
	covered.fill_rect(Rect2i(0, 0, 5, 5), Color.BLACK)
	var hidden := Metrics.occlusion(alone, Metrics.mask(covered, _whole()))
	_expect("quarter hidden", [hidden.hidden_pixels, hidden.ratio], [25, 0.25])
	var moved := Metrics.mask(_image([Rect2i(1, 0, 10, 10)]), _whole())
	_expect("moved silhouette", Metrics.occlusion(alone, moved).error, ERR_INVALID_DATA)
