extends VBoxContainer

## Browsing/audition never changes the event; binding is an explicit user action.

signal candidate_requested(asset: Resource)
signal analysis_requested(asset: Resource)
signal group_requested(assets: Array[Resource])
signal selection_changed
signal operation_reported(message: String)

const AudioPlayback = preload("res://components/feedback/audio_playback.gd")
const Backdrop = preload("res://asset_workbench/ui/preview_backdrop.gd")
const Widgets = preload("res://asset_workbench/ui/workbench_widgets.gd")
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
var _audition: Button
var _apply: Button
var _analyze: Button
var _stop_audition: Button
var _source_status: Label
var _audition_row: HFlowContainer = HFlowContainer.new()
var _more: MenuButton = MenuButton.new()
var _heading: Label


func _ready() -> void:
	_build_browser()
	add_child(_audio)
	add_child(_timer)
	_timer.timeout.connect(audition)
	_filter.text_changed.connect(_refresh_list)
	_list.item_selected.connect(_select)
	_repeat.toggled.connect(_set_repeat)
	resized.connect(_update_actions)
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


func selected_path() -> String:
	return "" if _selected == null else _selected.resource_path


func set_analysis_status(value: String) -> void:
	_source_status.text = "源分析：" + value


func set_apply_target(object_name: String, index: int) -> void:
	_apply.tooltip_text = "应用到 %s 的对象方案 %s；其他绑定保持不变。" % [
		object_name, "A" if index == 0 else "B"]
	_apply.text = "应用到对象 " + ("A" if index == 0 else "B")


func audition() -> void:
	if not _selected is AudioStream:
		return
	_audio.stop_all()
	var error := _audio.play(_selected as AudioStream, AUDITION_GAIN_DB, 1.0, &"Master")
	if error != OK:
		_details.text = "Audition failed: %s" % error_string(error)
		operation_reported.emit(_details.text)


func _build_browser() -> void:
	_heading = Widgets.label(self, "资源候选")
	_heading.add_theme_font_size_override("font_size", 18)
	_filter.placeholder_text = "筛选候选文件名"
	_filter.clear_button_enabled = true
	add_child(_filter)
	_list.name = "Candidates"
	_list.custom_minimum_size.y = 72
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.fixed_icon_size = Vector2i(32, 32)
	_list.icon_mode = ItemList.ICON_MODE_LEFT
	_list.add_theme_constant_override("icon_margin", 8)
	_list.allow_reselect = true
	add_child(_list)
	_backdrop.custom_minimum_size.y = 80
	_backdrop.clip_contents = true
	add_child(_backdrop)
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_backdrop.add_child(_image)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_details)
	_source_status = Widgets.label(self, "源分析：未分析")
	_build_actions()
	Widgets.label(self, "浏览不会替换当前对象资源。")


func _build_actions() -> void:
	add_child(_audition_row)
	_audition = Widgets.button(_audition_row, "试听", audition)
	_audition.tooltip_text = "独立试听：-12 dB / 音高 1× / Master；不使用 Cue 播放增益。"
	_repeat.text = "循环试听"
	_repeat.toggle_mode = true
	_audition_row.add_child(_repeat)
	_stop_audition = Widgets.button(_audition_row, "停止试听", stop)
	var actions := HFlowContainer.new()
	add_child(actions)
	_analyze = Widgets.button(actions, "分析候选源文件", _analyze_selected)
	_apply = Widgets.button(actions, "应用到对象 A", _bind_selected)
	_more.text = "候选更多…"
	_more.focus_mode = Control.FOCUS_ALL
	actions.add_child(_more)
	_more.get_popup().add_item("查看并复制完整路径", 0)
	_more.get_popup().add_item("将筛选结果加入批量分析", 1)
	_more.get_popup().id_pressed.connect(func(id: int) -> void:
		if id == 0:
			Widgets.show_text(self, "候选源路径（可选择复制）", selected_path())
		else:
			_group_filtered())


func _update_actions() -> void:
	if _apply == null:
		return
	var is_audio := _selected is AudioStream
	_audition.disabled = not is_audio
	_repeat.disabled = not is_audio
	_stop_audition.disabled = not is_audio
	_audition_row.visible = is_audio
	_apply.disabled = _selected == null
	_analyze.disabled = _selected == null
	_more.get_popup().set_item_disabled(0, _selected == null)
	_more.get_popup().set_item_disabled(1, _visible_assets.is_empty())
	var compact := get_viewport_rect().size.y < 650
	_heading.visible = not compact
	_source_status.visible = not compact
	_list.custom_minimum_size.y = 48 if compact else 72
	_backdrop.visible = _selected is Texture2D and not compact and size.y >= 520
	_details.text = _candidate_summary(compact)


func _refresh_list(query: String) -> void:
	stop()
	_selected = null
	_image.texture = null
	_details.text = "未选择候选"
	_list.clear()
	_visible_assets.clear()
	for asset: Resource in _assets:
		if query.is_empty() or asset.resource_path.get_file().containsn(query):
			_visible_assets.append(asset)
			var item_name := asset.resource_path.get_file()
			var icon := asset as Texture2D
			_list.add_item(item_name if icon != null else "[音频] " + item_name, icon)
			_list.set_item_tooltip(_list.item_count - 1, asset.resource_path)
	_update_actions()
	selection_changed.emit()


func _select(index: int) -> void:
	stop()
	_selected = _visible_assets[index]
	_image.texture = _selected as Texture2D
	_details.tooltip_text = _selected.resource_path
	_update_actions()
	selection_changed.emit()


func _candidate_summary(compact: bool) -> String:
	if _selected == null:
		return "未选择候选"
	var parts: Array[String] = [_selected.resource_path.get_file()]
	if _selected is Texture2D:
		var texture := _selected as Texture2D
		parts.append("图像 · %s · 导入后 %d × %d px" % [
			_selected.resource_path.get_extension().to_upper(), texture.get_width(), texture.get_height()])
	elif _selected is AudioStream:
		parts.append("音频 · %.3f s" % (_selected as AudioStream).get_length())
		parts.append("试听：-12 dB / 1× / Master")
	return (" · " if compact else "\n").join(parts)


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


func _analyze_selected() -> void:
	if _selected != null:
		analysis_requested.emit(_selected)


func _group_filtered() -> void:
	group_requested.emit(_visible_assets.duplicate())
