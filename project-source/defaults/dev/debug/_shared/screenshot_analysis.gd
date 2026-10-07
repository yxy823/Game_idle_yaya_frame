extends VBoxContainer
## The analysis page's screenshot section: captures the game window's root viewport, runs the
## color-vision grid and shows its four panels side by side. The debug window is a separate
## native window, so it never appears in the capture.

const Service := preload("res://dev/debug/_shared/analyzer_service.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const MODULES: Array[String] = ["image_cvd_grid"]
const PANEL_NAMES := {"normal": "正常", "gray": "灰度", "protan": "红色盲", "deutan": "绿色盲"}
const IMAGE_HEIGHT := 180.0
const TILE_LABEL_HEIGHT := 22.0

var service: Service
var grid_path: String = ""
var tiles: HBoxContainer
var capture_button: Button
var _status: Label
var _open: Button
var _empty: Label


func _init(analyzer: Service) -> void:
	service = analyzer
	name = "ScreenshotAnalysis"
	add_theme_constant_override("separation", 0)
	var block := Kit.section("截图分析")
	add_child(block)
	var header := block.get_child(0) as HBoxContainer
	var hint := Kit.label("色觉模拟：正常、灰度、红色盲、绿色盲", &"HintText")
	header.add_child(hint)
	header.move_child(hint, 1)
	_status = Kit.label("", &"StatusText")
	header.add_child(_status)
	_open = Kit.icon_button("external-link", "打开原图：用系统看图程序打开四宫格图片")
	_open.visible = false
	_open.pressed.connect(func() -> void: OS.shell_open(grid_path))
	header.add_child(_open)
	capture_button = Kit.text_button("截图分析", "camera",
		"截取游戏窗口的当前画面并分析，调试窗口不会出现在截图中", &"PrimaryButton")
	capture_button.pressed.connect(func() -> void: capture(get_tree().root.get_texture().get_image()))
	header.add_child(capture_button)
	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_top", 8)
	block.add_child(body)
	tiles = Kit.row(12)
	tiles.name = "Tiles"
	body.add_child(tiles)
	_empty = Kit.label("点右上角“截图分析”截取游戏画面，分析期间游戏照常运行", &"HintText")
	_empty.custom_minimum_size.y = IMAGE_HEIGHT + TILE_LABEL_HEIGHT
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tiles.add_child(_empty)


func capture(image: Image) -> void:
	_open.visible = false
	var path := Service.JOBS.path_join("game-%d.png" % Time.get_ticks_usec())
	var error := DirAccess.make_dir_recursive_absolute(Service.JOBS)
	if error == OK:
		error = image.save_png(path)
	if error != OK:
		_status.text = "截图没有保存下来：%s。关掉占用截图文件夹的程序后再试" % Messages.reason(error)
		_status.tooltip_text = Messages.detail({"error": error, "message": path})
		return
	var started := service.analyze(path, "image", MODULES, _finished)
	_status.text = "分析中…" if started.error == OK else started.message
	_status.tooltip_text = Messages.detail(started)


func _finished(state: Dictionary) -> void:
	var entry: Dictionary = state.get("data", {}).get("metrics", {}).get("cvd_grid", {})
	if state.status == "failed" or entry.get("status") != "available":
		_status.text = "截图分析没有完成：analyzer 没有给出四宫格。悬停这行文字看原因"
		_status.tooltip_text = state.message if state.status == "failed" 			else String(entry.get("reason", "no cvd_grid result"))
		return
	grid_path = entry.value.path
	show_grid(ImageTexture.create_from_image(Image.load_from_file(grid_path)), entry.value)
	_open.visible = true
	_status.text = ""
	_status.tooltip_text = ""


## Splits the analyzer's 2x2 grid (each panel under a caption strip) into four tiles.
func show_grid(texture: Texture2D, value: Dictionary) -> void:
	Kit.clear(tiles)
	var full := texture.get_size()
	var panel_size := full / 2.0
	if value.get("panel_size") is Array:
		panel_size = Vector2(value.panel_size[0], value.panel_size[1])
	var caption := maxf(full.y / 2.0 - panel_size.y, 0.0)
	var names: Array = value.get("panels", PANEL_NAMES.keys())
	for index in range(mini(names.size(), 4)):
		var region := Rect2(Vector2((index % 2) * panel_size.x,
			floorf(index / 2.0) * (panel_size.y + caption) + caption), panel_size)
		tiles.add_child(_tile(texture, region, PANEL_NAMES.get(names[index], names[index])))


func _tile(texture: Texture2D, region: Rect2, caption: String) -> PanelContainer:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var image := TextureRect.new()
	image.texture = atlas
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size.y = IMAGE_HEIGHT
	var label := Kit.label(caption, &"TileCaption")
	label.custom_minimum_size.y = TILE_LABEL_HEIGHT
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 8)
	margins.add_child(label)
	var lines := Kit.column(0)
	lines.add_child(image)
	lines.add_child(margins)
	var tile := Kit.panel(&"ImageTile", lines)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return tile
