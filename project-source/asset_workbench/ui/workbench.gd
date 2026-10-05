extends Control

const Session = preload("res://yaya/asset_workbench/ui/preview_session.gd")
const Browser = preload("res://yaya/asset_workbench/ui/asset_browser.gd")
const Controls = preload("res://yaya/asset_workbench/ui/cue_controls.gd")
const Presenter = preload("res://components/feedback/feedback_presenter.gd")
const Appearance = preload("res://yaya/asset_workbench/ui/workbench_theme.gd")
const Backdrop = preload("res://yaya/asset_workbench/ui/preview_backdrop.gd")
const AnalysisPanel = preload("res://yaya/asset_workbench/ui/analysis_panel.gd")
const BatchPanel = preload("res://yaya/asset_workbench/ui/analysis_batch_panel.gd")
const Layout = preload("res://yaya/asset_workbench/ui/workbench_layout.gd")

@export_file("*.tres") var cue_path: String
@export_file("*.tscn") var game_scene_path: String
@export var texture_candidates: Array[Texture2D] = []
@export var sound_candidates: Array[AudioStream] = []
@export var shader_candidates: Array[FeedbackShaderPreset] = []
@export var particle_candidates: Array[FeedbackParticlePreset] = []
@export var animation_candidates: Array[Animation] = []
@export var workbench_title: String = "Asset Workbench · 单对象"

var session: Session = Session.new()
var presenter: Presenter

var _browser: Browser
var _controls: Controls
var _status: Label
var _state: Label
var _repeat: Timer
var _reload_dialog: ConfirmationDialog
var _background: ColorRect
var _backdrop: Backdrop
var _analysis: AnalysisPanel
var _batch: BatchPanel
var _target: Label
var _ui: Layout


func _ready() -> void:
	# UI nodes gain their parents below; cold scene instances must not create detached trees.
	_browser = Browser.new()
	_controls = Controls.new()
	_repeat = Timer.new()
	_reload_dialog = ConfirmationDialog.new()
	_background = ColorRect.new()
	_analysis = AnalysisPanel.new()
	_batch = BatchPanel.new()
	_ui = Layout.new()
	_build_layout()
	add_child(_repeat)
	_repeat.timeout.connect(func() -> void: presenter.trigger())
	_browser.populate(texture_candidates, sound_candidates)
	_browser.candidate_requested.connect(_bind_candidate)
	_browser.operation_reported.connect(_set_status)
	add_child(_analysis)
	_browser.analysis_requested.connect(_analysis.open_asset)
	_browser.selection_changed.connect(_refresh_source_status)
	_analysis.results_changed.connect(_refresh_source_status)
	_batch.batch.service = _analysis.service
	add_child(_batch)
	_browser.group_requested.connect(_batch.open_assets)
	_batch.compare_requested.connect(_analysis.open_results)
	_controls.build(texture_candidates, sound_candidates, shader_candidates,
		particle_candidates, animation_candidates)
	_controls.edited.connect(_edit)
	presenter.playback_failed.connect(_set_status)
	_reload_dialog.dialog_text = "从磁盘重载当前 Cue？这会丢弃当前对象 A/B 两份草稿。"
	_reload_dialog.confirmed.connect(_load_session)
	add_child(_reload_dialog)
	_load_session()
	_refresh_source_status()


func _refresh_source_status() -> void:
	_browser.set_analysis_status(_analysis.source_status(_browser.selected_path()))


func _exit_tree() -> void:
	stop_all()


func stop_all() -> void:
	_repeat.stop()
	_browser.stop()
	if presenter != null:
		presenter.stop()


func _build_layout() -> void:
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_set_dark_theme(false)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	add_child(margin)
	margin.add_child(_ui)
	_ui.build(workbench_title)
	_state = _ui.state
	_status = _ui.status
	_target = _ui.target
	_ui.action_requested.connect(_dispatch_action)
	_ui.appearance_changed.connect(func(dark: bool, checker: bool) -> void:
		_set_dark_theme(dark)
		_set_checker(checker))
	_browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ui.assets.add_child(_browser)
	_build_event_panel(_ui.preview)
	_ui.finish_preview()
	_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ui.properties.add_child(_controls)


func _build_event_panel(parent: Container) -> void:
	var heading := Label.new()
	heading.text = "对象预览 · 当前方案"
	parent.add_child(heading)
	_backdrop = Backdrop.new()
	_backdrop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_backdrop.custom_minimum_size = Vector2(180.0, 180.0)
	_backdrop.clip_contents = true
	parent.add_child(_backdrop)
	presenter = Presenter.new()
	presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(presenter)


func _dispatch_action(action: StringName) -> void:
	var actions: Dictionary[StringName, Callable] = {
		&"object_a": _select_alternative.bind(0), &"object_b": _select_alternative.bind(1),
		&"trigger": _trigger_once, &"repeat": _start_repeat.bind(0.6),
		&"rapid": _start_repeat.bind(0.1), &"stop": stop_all, &"save": _save,
		&"copy": _copy_alternative, &"reset": _reset_trial,
		&"reload": _reload_dialog.popup_centered, &"open": _open_game,
		&"analyze_object": _analyze_object,
	}
	actions[action].call()


func _analyze_object() -> void:
	if not _has_current_cue():
		return
	var assets: Array[Resource] = []
	for asset: Resource in [session.current().texture, session.current().sound]:
		if asset != null:
			assets.append(asset)
	_batch.open_assets(assets)


func _set_dark_theme(enabled: bool) -> void:
	theme = Appearance.create(enabled)
	_background.color = Appearance.background(enabled)
	_analysis.set_background(enabled)
	_batch.set_background(enabled)


func _set_checker(enabled: bool) -> void:
	if _backdrop != null:
		_backdrop.checker_enabled = enabled
	_browser.set_checker(enabled)


func _load_session() -> void:
	stop_all()
	var issue := session.open(cue_path)
	if not issue.is_empty():
		if session.saved == null:
			_refresh()
		_set_status(issue)
		return
	# A keeps the saved cue; B changes only the sound so the example is immediately comparable.
	for sound: AudioStream in sound_candidates:
		if session.saved.sound != null and sound.resource_path != session.saved.sound.resource_path:
			session.drafts[1].sound = sound
			break
	_refresh()
	_set_status("A 从已保存 Cue 开始；B 在已有声音时换用另一候选。浏览不会绑定，保存只写当前方案。")


func _refresh() -> void:
	var loaded := session.saved != null
	_controls.visible = loaded
	_ui.display_context(_current_object_name(), session.active_index if loaded else -1,
		loaded and session.is_dirty(), cue_path)
	_browser.set_apply_target(_current_object_name(), session.active_index)
	if not loaded:
		_set_status(session.load_error)
		return
	_controls.display(session.current())
	_preview_trial()


func _preview_trial() -> void:
	presenter.configure(session.current())


func _current_object_name() -> String:
	return cue_path.get_file().get_basename()


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
		_set_status("已复制到当前对象的另一方案，尚未保存。")


func _trigger_once() -> void:
	if not _has_current_cue():
		return
	stop_all()
	presenter.trigger()


func _start_repeat(interval: float) -> void:
	if not _has_current_cue():
		return
	stop_all()
	_repeat.start(interval)
	presenter.trigger()


func _has_current_cue() -> bool:
	if session.saved != null:
		return true
	_set_status("尚未加载有效 Cue；请修复 Cue 路径后重新加载。候选资源仍可独立试听和分析。")
	return false


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
	_set_status("当前方案已保存并重新读取。请打开消费场景验证实际效果。")


func _open_game() -> void:
	stop_all()
	var path := game_scene_path
	if not OS.has_feature("editor") or not ResourceLoader.exists(path):
		_set_status("Game launch requires the editor binary and an existing project scene.")
		return
	var process := OS.create_instance(["--path", ProjectSettings.globalize_path("res://"),
		path])
	_set_status("Game opened with saved data." if process > 0 else "Game launch failed.")


func _set_status(message: String) -> void:
	_status.text = message
	_status.tooltip_text = message
