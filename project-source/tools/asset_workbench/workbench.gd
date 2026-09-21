extends Control

const Session = preload("res://tools/asset_workbench/preview_session.gd")
const Browser = preload("res://tools/asset_workbench/asset_browser.gd")
const Controls = preload("res://tools/asset_workbench/cue_controls.gd")
const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const Appearance = preload("res://tools/asset_workbench/workbench_theme.gd")
const Backdrop = preload("res://tools/asset_workbench/preview_backdrop.gd")
const AnalysisPanel = preload("res://tools/asset_workbench/analysis_panel.gd")

@export_file("*.tres") var cue_path: String
@export_file("*.tscn") var game_scene_path: String
@export var texture_candidates: Array[Texture2D] = []
@export var sound_candidates: Array[AudioStream] = []

var session: Session = Session.new()
var presenter: Presenter = Presenter.new()

var _browser: Browser = Browser.new()
var _controls: Controls = Controls.new()
var _status: Label = Label.new()
var _state: Label = Label.new()
var _repeat: Timer = Timer.new()
var _reload_dialog: ConfirmationDialog = ConfirmationDialog.new()
var _background: ColorRect = ColorRect.new()
var _backdrop: Backdrop = Backdrop.new()
var _analysis: AnalysisPanel = AnalysisPanel.new()


func _ready() -> void:
	_build_layout()
	add_child(_repeat)
	_repeat.timeout.connect(presenter.trigger)
	_browser.populate(texture_candidates, sound_candidates)
	_browser.candidate_requested.connect(_bind_candidate)
	add_child(_analysis)
	_browser.analysis_requested.connect(_analysis.open_asset)
	_controls.build(texture_candidates, sound_candidates)
	_controls.edited.connect(_edit)
	presenter.playback_failed.connect(_set_status)
	_reload_dialog.dialog_text = "Discard both A/B trials and reload the saved file?"
	_reload_dialog.confirmed.connect(_load_session)
	add_child(_reload_dialog)
	_load_session()


func _exit_tree() -> void:
	stop_all()


func stop_all() -> void:
	_repeat.stop()
	_browser.stop()
	presenter.stop()


func _build_layout() -> void:
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_set_dark_theme(false)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var title := Label.new()
	title.text = "ASSET WORKBENCH  /  example reward - activate"
	title.add_theme_font_size_override("font_size", 24)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title)
	var appearance := HBoxContainer.new()
	root.add_child(appearance)
	_toggle(appearance, "Dark background", _set_dark_theme)
	_toggle(appearance, "Transparency grid", _set_checker)
	_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_state)
	_build_body(root)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)


func _build_body(root: VBoxContainer) -> void:
	# Each column scrolls vertically; narrow embedded windows can also scroll the body sideways.
	var body := ScrollContainer.new()
	body.name = "WorkbenchBody"
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	_browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column(columns, "AssetColumn", 265.0).add_child(_browser)
	_build_event_panel(_column(columns, "EventColumn", 350.0, true))
	_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column(columns, "ParameterColumn", 285.0).add_child(_controls)


func _column(parent: Container, column_name: String, width: float,
		expand: bool = false) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = column_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.x = width
	scroll.follow_focus = true
	if expand:
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	return scroll


func _build_event_panel(parent: ScrollContainer) -> void:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var heading := Label.new()
	heading.text = "02 / EVENT PREVIEW"
	panel.add_child(heading)
	_backdrop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_backdrop.custom_minimum_size = Vector2(350.0, 240.0)
	_backdrop.clip_contents = true
	panel.add_child(_backdrop)
	presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(presenter)
	var alternatives := HBoxContainer.new()
	panel.add_child(alternatives)
	_button(alternatives, "A", _select_alternative.bind(0))
	_button(alternatives, "B", _select_alternative.bind(1))
	_button(alternatives, "Copy active to other", _copy_alternative)
	var play := HBoxContainer.new()
	panel.add_child(play)
	_button(play, "Trigger", _trigger_once)
	_button(play, "Repeat 0.6s", _start_repeat.bind(0.6))
	_button(play, "Rapid 0.1s", _start_repeat.bind(0.1))
	_button(panel, "Stop all / reset effects", stop_all)
	_button(panel, "Reset active trial to last save", _reset_trial)
	_button(panel, "Save active cue to the target below", _save)
	_button(panel, "Reload from disk (discard both trials)", _reload_dialog.popup_centered)
	_button(panel, "Open example game using saved cue", _open_game)
	var target := Label.new()
	target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target.text = "Save target: %s\nAffects every consumer of this cue.\n" % cue_path
	target.text += "Source images/audio stay unchanged. No loudness matching is applied."
	panel.add_child(target)


func _button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


func _toggle(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.toggled.connect(action)
	parent.add_child(button)


func _set_dark_theme(enabled: bool) -> void:
	theme = Appearance.create(enabled)
	_background.color = Appearance.background(enabled)
	_analysis.set_background(enabled)


func _set_checker(enabled: bool) -> void:
	_backdrop.checker_enabled = enabled
	_browser.set_checker(enabled)


func _load_session() -> void:
	stop_all()
	var issue := session.open(cue_path)
	if not issue.is_empty():
		_set_status(issue)
		return
	# A keeps the saved cue; B changes only the sound so the example is immediately comparable.
	for sound: AudioStream in sound_candidates:
		if sound.resource_path != session.saved.sound.resource_path:
			session.drafts[1].sound = sound
			break
	_refresh()
	_set_status("A starts from the saved cue; B uses another sound when available. "
		+ "Save applies only the active trial.")


func _refresh() -> void:
	_controls.display(session.current())
	presenter.configure(session.current())
	_state.text = "Active: %s   |   %s   |   Event sound: %s" % [
		"A" if session.active_index == 0 else "B",
		"UNSAVED TRIAL" if session.is_dirty() else "matches saved cue",
		session.current().sound.resource_path.get_file(),
	]


func _edit() -> void:
	if session.saved == null:
		return
	stop_all()
	_controls.apply_to(session.current())
	_refresh()
	presenter.trigger()


func _bind_candidate(asset: Resource) -> void:
	if session.saved == null:
		return
	stop_all()
	if asset is Texture2D:
		session.current().texture = asset as Texture2D
	elif asset is AudioStream:
		session.current().sound = asset as AudioStream
	_refresh()
	presenter.trigger()


func _select_alternative(index: int) -> void:
	if session.saved == null:
		return
	stop_all()
	session.active_index = index
	_refresh()
	presenter.trigger()


func _copy_alternative() -> void:
	if session.saved != null:
		session.copy_to_other()
		_set_status("Copied active trial to the other alternative. Nothing was saved.")


func _trigger_once() -> void:
	stop_all()
	presenter.trigger()


func _start_repeat(interval: float) -> void:
	stop_all()
	_repeat.start(interval)
	presenter.trigger()


func _reset_trial() -> void:
	if session.saved != null:
		stop_all()
		session.reset_current()
		_refresh()


func _save() -> void:
	if session.saved == null:
		return
	stop_all()
	var issue := session.save_current()
	if not issue.is_empty():
		_set_status(issue)
		return
	_refresh()
	_set_status("Saved and reloaded. Open the example game to check the actual consumer.")


func _open_game() -> void:
	stop_all()
	if not OS.has_feature("editor") or not ResourceLoader.exists(game_scene_path):
		_set_status("Game launch requires the editor binary and an existing project scene.")
		return
	var process := OS.create_instance(["--path", ProjectSettings.globalize_path("res://"),
		game_scene_path])
	_set_status("Game opened with saved data." if process > 0 else "Game launch failed.")


func _set_status(message: String) -> void:
	_status.text = message
