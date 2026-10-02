extends VBoxContainer

## Per-object trial sessions reuse the original property controls and save contract.

signal session_selected(session: Session)
signal analysis_requested(assets: Array[Resource])
signal stop_requested
signal operation_reported(message: String)

const Session = preload("res://asset_workbench/ui/preview_session.gd")
const Stage = preload("res://components/feedback/feedback_composition.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Appearance = preload("res://asset_workbench/ui/workbench_theme.gd")
const Widgets = preload("res://asset_workbench/ui/workbench_widgets.gd")

var scene_resource: PackedScene
var sound_candidates: Array[AudioStream] = []
var sessions: Dictionary[String, Session] = {}
var stage: Stage
var _selected_path: String = ""
var _status: Label = Label.new()
var _gain: SpinBox = SpinBox.new()
var _dark: bool = false
var _scene_trials: Array[Button] = []
var _scene_state: Label
var _gain_popup: PopupPanel = PopupPanel.new()
var _timeline_state: Label
var _timeline_repeat: CheckButton


func _ready() -> void:
	stage = scene_resource.instantiate() as Stage
	_build()
	_load_sessions()
	stage.object_selected.connect(select_object)
	stage.playback_reported.connect(_report)
	if stage.timeline_player != null:
		stage.timeline_player.state_changed.connect(_update_timeline_state)
		_update_timeline_state()
	set_background(_dark)


func _load_sessions() -> void:
	for object: ObjectView in stage.objects:
		var session := Session.new()
		var issue := session.open(object.cue_path)
		if issue.is_empty():
			_seed_alternative(session)
			sessions[String(stage.get_path_to(object))] = session
		else:
			_report(issue)
	_update_scene_state()


func _seed_alternative(session: Session) -> void:
	for sound: AudioStream in sound_candidates:
		if session.saved.sound != null and sound.resource_path != session.saved.sound.resource_path:
			session.drafts[1].sound = sound
			break


func set_background(dark: bool) -> void:
	_dark = dark
	if stage != null:
		stage.set_background(Appearance.background(dark))
		stage.theme = Appearance.create(dark)


func select_object(path: String) -> void:
	if sessions.has(path):
		_selected_path = path
		stage.highlight(path)
		session_selected.emit(sessions[path])
		_status.text = "已选择：" + object_name(path)
		var shared: int = 0
		for session: Session in sessions.values():
			shared += int(session.target_path == sessions[path].target_path)
		if shared > 1:
			_status.text += "；%d 个对象共享保存目标，草稿各自独立。" % shared


func update_trial(path: String) -> void:
	if stage != null:
		stage.preview(path, sessions[path].current())
	_update_scene_state()


func object_name(path: String = "") -> String:
	var selected := _selected_path if path.is_empty() else path
	var object := stage.object_at(selected)
	if object == null:
		return selected
	var parent := selected.get_base_dir()
	return object.display_name if parent.is_empty() else parent + " / " + object.display_name


func current_object() -> ObjectView:
	return stage.object_at(_selected_path)


func refresh_state() -> void:
	_update_scene_state()


func _update_scene_state() -> void:
	if _scene_state == null:
		return
	var indices: Array[int] = []
	for session: Session in sessions.values():
		if session.active_index not in indices:
			indices.append(session.active_index)
	var uniform := indices[0] if indices.size() == 1 else -1
	for index: int in _scene_trials.size():
		_scene_trials[index].set_pressed_no_signal(index == uniform)
	_scene_state.text = "全场景：" + (["A", "B"][uniform] if uniform >= 0 else "混合方案")


func select_all_alternatives(index: int) -> void:
	stop_requested.emit()
	stage.stop()
	for path: String in sessions:
		var session := sessions[path]
		session.active_index = index
		update_trial(path)
	if sessions.has(_selected_path):
		session_selected.emit(sessions[_selected_path])
	_report("所有对象已切换到方案 %s；尚未保存。" % ("A" if index == 0 else "B"))


func trigger_all() -> void:
	stop_requested.emit()
	stage.stop()
	stage.trigger_all()


func play_timeline() -> void:
	stop_requested.emit()
	var issue := stage.play_timeline(_timeline_repeat.button_pressed)
	if not issue.is_empty():
		_report(issue)
	elif stage.timeline_player.is_playing():
		_report("正在编排各对象的当前方案；片段到期停止，保存仍只写 Cue。")


func _update_timeline_state() -> void:
	if _timeline_state == null:
		return
	var playing := stage.timeline_player.is_playing()
	_timeline_state.text = "编排：" + ("循环播放" if stage.timeline_player.looping else "播放中") \
		if playing else "编排：已停止"


func apply_gain(value: float) -> void:
	if not is_finite(value) or value < -48.0 or value > 0.0:
		return
	_gain.set_value_no_signal(value)
	for path: String in sessions:
		var session := sessions[path]
		session.current().gain_db = value
		update_trial(path)
	if sessions.has(_selected_path):
		session_selected.emit(sessions[_selected_path])
	_report("已将 %.1f dB 增益应用到各对象的当前方案，尚未保存。" % value)


func assets(selected_only: bool) -> Array[Resource]:
	var output: Array[Resource] = []
	for path: String in sessions:
		if selected_only and path != _selected_path:
			continue
		var cue: FeedbackCue = sessions[path].current()
		for asset: Resource in [cue.texture, cue.sound]:
			if asset != null and asset not in output:
				output.append(asset)
	return output


func save_all() -> void:
	stop_requested.emit()
	stage.stop()
	var saved: int = 0
	var issues: Array[String] = []
	var files: Dictionary[String, Array] = {}
	for session: Session in sessions.values():
		files.get_or_add(session.target_path, []).append(session)
	for path: String in files:
		var group: Array[Session] = []
		group.assign(files[path])
		var issue := _save_shared_file(group)
		if issue.is_empty():
			saved += 1
		else:
			issues.append(path + ": " + issue)
	if sessions.has(_selected_path):
		session_selected.emit(sessions[_selected_path])
	_report("已保存 %d/%d 个 Cue；逐文件检查与保存，并非多文件事务。\n%s" % [
		saved, files.size(), "\n".join(issues)])


func _save_shared_file(group: Array[Session]) -> String:
	var first: Session = group[0]
	for session: Session in group:
		if not session.current().same_values(first.current()):
			return "多个对象的当前方案引用同一 Cue 但内容不同，未写入。请统一方案或只保存选中对象。"
		var conflict := session.save_error()
		if not conflict.is_empty():
			return conflict
	var issue := first.save_current()
	if not issue.is_empty():
		return issue
	for session: Session in group:
		if session != first:
			issue = session.accept_matching_save()
			if not issue.is_empty():
				return issue
	return ""


func _build() -> void:
	var actions := HFlowContainer.new()
	add_child(actions)
	var group := ButtonGroup.new()
	for index: int in 2:
		var button := Widgets.button(actions, "场景 " + ["A", "B"][index],
			select_all_alternatives.bind(index))
		button.toggle_mode = true
		button.button_group = group
		_scene_trials.append(button)
	Widgets.button(actions, "触发全部", trigger_all)
	_build_scene_menu(actions)
	var states := HFlowContainer.new()
	add_child(states)
	_scene_state = Widgets.label(states, "全场景：A")
	_scene_state.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "点击对象选择并触发；边框标示当前编辑对象。"
	add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.name = "SceneViewport"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	add_child(scroll)
	stage.custom_minimum_size = Vector2(760, 350)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(stage)
	if stage.timeline != null:
		_build_timeline_controls(actions)


func _build_timeline_controls(parent: Container) -> void:
	Widgets.button(parent, "播放编排", play_timeline)
	_timeline_repeat = CheckButton.new()
	_timeline_repeat.text = "循环编排"
	_timeline_repeat.tooltip_text = "下次播放生效；每轮结束停止所有编排片段后重新开始。"
	parent.add_child(_timeline_repeat)
	_timeline_state = Widgets.label(_scene_state.get_parent(), "编排：已停止")
	_timeline_state.autowrap_mode = TextServer.AUTOWRAP_OFF
	_timeline_state.tooltip_text = "对象当前方案；%.1f s / %d 片段；最多 %d 个受管对象。\n%s" % [
		stage.timeline.length_seconds, stage.timeline.clips.size(), stage.managed_object_limit,
		stage.timeline.resource_path]


func _build_scene_menu(parent: Container) -> void:
	var menu := MenuButton.new()
	menu.text = "全场景更多…"
	menu.focus_mode = Control.FOCUS_ALL
	parent.add_child(menu)
	var popup := menu.get_popup()
	popup.add_item("分析场景源资源（图像 / 音频）", 0)
	popup.add_item("将增益应用到各对象的当前方案…", 1)
	popup.add_item("保存全场景当前方案（逐文件）", 2)
	popup.id_pressed.connect(_scene_action)
	add_child(_gain_popup)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 320
	_gain_popup.add_child(actions)
	Widgets.label(actions, "统一增益 (dB) · 各对象的当前方案")
	_gain.min_value = FeedbackCue.GAIN_LIMITS[0]
	_gain.max_value = FeedbackCue.GAIN_LIMITS[1]
	_gain.value = -18
	_gain.suffix = "dB"
	actions.add_child(_gain)
	Widgets.button(actions, "将增益应用到各对象的当前方案", func() -> void:
		apply_gain(_gain.value)
		_gain_popup.hide())
	Widgets.label(actions, "只更改各对象当前 A 或 B 草稿，不自动保存。")


func _scene_action(id: int) -> void:
	match id:
		0: analysis_requested.emit(assets(false))
		1: _gain_popup.popup_centered()
		2: save_all()


func _report(message: String) -> void:
	_status.text = message.get_slice("\n", 0)
	_status.tooltip_text = message
	operation_reported.emit(message)
