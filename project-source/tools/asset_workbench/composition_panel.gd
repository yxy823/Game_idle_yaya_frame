extends Window

## Per-object trial sessions reuse the original property controls and save contract.

signal session_selected(session: Session)
signal analysis_requested(assets: Array[Resource])

const Session = preload("res://tools/asset_workbench/preview_session.gd")
const Stage = preload("res://components/feedback/feedback_composition.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Appearance = preload("res://tools/asset_workbench/workbench_theme.gd")

var scene_resource: PackedScene
var default_session: Session
var sound_candidates: Array[AudioStream] = []
var sessions: Dictionary[String, Session] = {}
var stage: Stage
var _selected_path: String = ""
var _status: Label = Label.new()
var _gain: SpinBox = SpinBox.new()
var _background: ColorRect = ColorRect.new()
var _dark: bool = false


func _ready() -> void:
	title = "Example reward room / interactive composition"
	size = Vector2i(1200, 620)
	min_size = Vector2i(450, 320)
	visible = false
	force_native = true
	stage = scene_resource.instantiate() as Stage
	_build()
	_load_sessions()
	stage.object_selected.connect(select_object)
	close_requested.connect(_close)
	set_background(_dark)


func _load_sessions() -> void:
	for object: ObjectView in stage.objects:
		if sessions.has(object.cue_path):
			continue
		var session := Session.new()
		var issue := session.open(object.cue_path)
		if issue.is_empty():
			_seed_alternative(session)
			sessions[object.cue_path] = session
		else:
			_status.text += issue + "\n"


func _seed_alternative(session: Session) -> void:
	for sound: AudioStream in sound_candidates:
		if sound.resource_path != session.saved.sound.resource_path:
			session.drafts[1].sound = sound
			break


func open() -> void:
	popup_centered_clamped(Vector2i(1200, 620), 0.9)
	grab_focus()


func set_background(dark: bool) -> void:
	_dark = dark
	_background.color = Appearance.background(dark)
	if stage != null:
		stage.set_background(_background.color)
		stage.theme = Appearance.create(dark)


func select_object(path: String) -> void:
	if sessions.has(path):
		_selected_path = path
		stage.highlight(path)
		session_selected.emit(sessions[path])
		_status.text = "Selected: %s. Edit in the workbench; each object retains its A/B trials." % path


func update_trial(session: Session) -> void:
	if stage != null:
		stage.preview(session.target_path, session.current())


func apply_gain(value: float) -> void:
	if not is_finite(value) or value < -48.0 or value > 0.0:
		return
	_gain.set_value_no_signal(value)
	for session: Session in sessions.values():
		session.current().gain_db = value
		update_trial(session)
	if sessions.has(_selected_path):
		session_selected.emit(sessions[_selected_path])
	_status.text = "Applied %.1f dB to each scene object's ACTIVE trial. Not saved." % value


func assets(selected_only: bool) -> Array[Resource]:
	var output: Array[Resource] = []
	for path: String in sessions:
		if selected_only and path != _selected_path:
			continue
		var cue: FeedbackCue = sessions[path].current()
		for asset: Resource in [cue.texture, cue.sound]:
			if asset not in output:
				output.append(asset)
	return output


func save_all() -> void:
	stage.stop()
	var saved: int = 0
	var issues: Array[String] = []
	for path: String in sessions:
		var issue := sessions[path].save_current()
		if issue.is_empty():
			saved += 1
		else:
			issues.append(path + ": " + issue)
	if sessions.has(_selected_path):
		session_selected.emit(sessions[_selected_path])
	_status.text = "Saved %d/%d cues. Each file is checked and saved separately.\n%s" % [
		saved, sessions.size(), "\n".join(issues)]


func _build() -> void:
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)
	var actions := HFlowContainer.new()
	root.add_child(actions)
	_button(actions, "Trigger all", stage.trigger_all)
	_button(actions, "Stop all", stage.stop)
	_button(actions, "Return to original event", _return_original)
	_button(actions, "Analyze selected object's sources", func() -> void:
		analysis_requested.emit(assets(true)))
	_button(actions, "Analyze all scene sources", func() -> void:
		analysis_requested.emit(assets(false)))
	_build_save_actions(root)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Click an object to select and activate it; edit its properties in the workbench."
	root.add_child(_status)
	stage.custom_minimum_size = Vector2(900, 390)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stage)


func _build_save_actions(root: Container) -> void:
	var actions := HFlowContainer.new()
	root.add_child(actions)
	_gain.min_value = FeedbackCue.GAIN_LIMITS[0]
	_gain.max_value = FeedbackCue.GAIN_LIMITS[1]
	_gain.value = -18
	_gain.suffix = "dB"
	actions.add_child(_gain)
	_button(actions, "Apply gain to all trials", func() -> void: apply_gain(_gain.value))
	_button(actions, "Save all scene cues (shared files)", save_all)
	_button(actions, "Open saved scene in game", _open_saved)
	_button(actions, "Close", _close)


func _button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


func _return_original() -> void:
	_selected_path = ""
	stage.highlight("")
	session_selected.emit(default_session)
	_status.text = "Returned to original event. Scene trials retained."


func _open_saved() -> void:
	stage.stop()
	var pid := OS.create_instance(["--path", ProjectSettings.globalize_path("res://"),
		scene_resource.resource_path])
	_status.text = "Opened saved scene." if pid > 0 else "Could not open saved scene."


func _close() -> void:
	stage.stop()
	hide()
