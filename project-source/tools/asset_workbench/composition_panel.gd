extends VBoxContainer

## Per-object trial sessions reuse the original property controls and save contract.

signal session_selected(session: Session)
signal analysis_requested(assets: Array[Resource])
signal stop_requested

const Session = preload("res://tools/asset_workbench/preview_session.gd")
const Stage = preload("res://components/feedback/feedback_composition.gd")
const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Appearance = preload("res://tools/asset_workbench/workbench_theme.gd")

var scene_resource: PackedScene
var sound_candidates: Array[AudioStream] = []
var sessions: Dictionary[String, Session] = {}
var stage: Stage
var _selected_path: String = ""
var _status: Label = Label.new()
var _gain: SpinBox = SpinBox.new()
var _dark: bool = false


func _ready() -> void:
	stage = scene_resource.instantiate() as Stage
	_build()
	_load_sessions()
	stage.object_selected.connect(select_object)
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
		_status.text = "Selected: %s. Edit in the workbench; each object retains its A/B trials." % path


func update_trial(session: Session) -> void:
	if stage != null:
		stage.preview(session.target_path, session.current())


func select_all_alternatives(index: int) -> void:
	stop_requested.emit()
	stage.stop()
	for session: Session in sessions.values():
		session.active_index = index
		update_trial(session)
	if sessions.has(_selected_path):
		session_selected.emit(sessions[_selected_path])
	_status.text = "All scene objects use trial %s. Trigger all to compare." % ("A" if index == 0 else "B")


func trigger_all() -> void:
	stop_requested.emit()
	stage.stop()
	stage.trigger_all()


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
			if asset != null and asset not in output:
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
	var root: Container = self
	var actions := HFlowContainer.new()
	root.add_child(actions)
	_button(actions, "Scene A", select_all_alternatives.bind(0))
	_button(actions, "Scene B", select_all_alternatives.bind(1))
	_button(actions, "Trigger all", trigger_all)
	_button(actions, "Stop all", func() -> void: stop_requested.emit())
	_button(actions, "Analyze selected object's sources", func() -> void:
		analysis_requested.emit(assets(true)))
	_button(actions, "Analyze all scene sources", func() -> void:
		analysis_requested.emit(assets(false)))
	_build_save_actions(root)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Click an object to select and activate it; edit its properties in the workbench."
	root.add_child(_status)
	stage.custom_minimum_size = Vector2(760, 350)
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


func _button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
