extends VBoxContainer

## Browsing/audition never changes the event; binding is an explicit user action.

signal candidate_requested(asset: Resource)

const AudioPlayback = preload("res://components/feedback/audio_playback.gd")
const Backdrop = preload("res://tools/asset_workbench/preview_backdrop.gd")
const AUDITION_GAIN_DB: float = -12.0

var _assets: Array[Resource] = []
var _visible_assets: Array[Resource] = []
var _selected: Resource
var _filter: LineEdit = LineEdit.new()
var _list: ItemList = ItemList.new()
var _image: TextureRect = TextureRect.new()
var _backdrop: Backdrop = Backdrop.new()
var _details: Label = Label.new()
var _audio: AudioPlayback = AudioPlayback.new()
var _repeat: Button = Button.new()
var _timer: Timer = Timer.new()


func _ready() -> void:
	_build_browser()
	add_child(_audio)
	add_child(_timer)
	_timer.timeout.connect(audition)
	_filter.text_changed.connect(_refresh_list)
	_list.item_selected.connect(_select)
	_repeat.toggled.connect(_set_repeat)
	_refresh_list("")


func populate(textures: Array[Texture2D], sounds: Array[AudioStream]) -> void:
	_assets.clear()
	_assets.append_array(textures)
	_assets.append_array(sounds)
	if is_node_ready():
		_refresh_list(_filter.text)


func stop() -> void:
	_timer.stop()
	_repeat.set_pressed_no_signal(false)
	_audio.stop_all()


func set_checker(enabled: bool) -> void:
	_backdrop.checker_enabled = enabled


func audition() -> void:
	if not _selected is AudioStream:
		return
	_audio.stop_all()
	var error := _audio.play(_selected as AudioStream, AUDITION_GAIN_DB, 1.0, &"Master")
	if error != OK:
		_details.text = "Audition failed: %s" % error_string(error)


func _build_browser() -> void:
	var title := Label.new()
	title.text = "01 / SINGLE ASSET"
	add_child(title)
	_filter.placeholder_text = "Filter candidate filenames"
	add_child(_filter)
	_list.custom_minimum_size.y = 170.0
	add_child(_list)
	_backdrop.custom_minimum_size.y = 120.0
	_backdrop.clip_contents = true
	add_child(_backdrop)
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_backdrop.add_child(_image)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_details)
	_add_button("Audition (-12 dB / 1x / Master)", audition)
	_repeat.text = "Repeat audition"
	_repeat.toggle_mode = true
	add_child(_repeat)
	_add_button("Stop audition", stop)
	_add_button("Use selection in active A/B", _bind_selected)


func _add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	add_child(button)


func _refresh_list(query: String) -> void:
	stop()
	_selected = null
	_image.texture = null
	_details.text = "Select a candidate. Browsing does not change the event."
	_list.clear()
	_visible_assets.clear()
	for asset: Resource in _assets:
		if query.is_empty() or asset.resource_path.get_file().containsn(query):
			_visible_assets.append(asset)
			_list.add_item(asset.resource_path.get_file())


func _select(index: int) -> void:
	stop()
	_selected = _visible_assets[index]
	_image.texture = _selected as Texture2D
	_details.text = _selected.resource_path + "\n\n"
	if _selected is Texture2D:
		var texture := _selected as Texture2D
		_details.text += "Imported texture: %d x %d px" % [texture.get_width(), texture.get_height()]
	elif _selected is AudioStream:
		_details.text += "Imported stream: %.3f s" % (_selected as AudioStream).get_length()
	_details.text += "\nSource and license: examples/asset_workbench/README.md"


func _set_repeat(enabled: bool) -> void:
	if not enabled or not _selected is AudioStream:
		stop()
		return
	_timer.wait_time = maxf((_selected as AudioStream).get_length() + 0.2, 0.2)
	audition()
	_timer.start()


func _bind_selected() -> void:
	if _selected != null:
		candidate_requested.emit(_selected)
