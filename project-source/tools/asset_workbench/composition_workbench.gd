extends "res://tools/asset_workbench/workbench.gd"

## Independent scene entry; shares controls and analysis, never opens the single-object scene.

const CompositionPanel = preload("res://tools/asset_workbench/composition_panel.gd")

@export var composition_scene: PackedScene

var _composition: CompositionPanel


func _ready() -> void:
	super()
	_composition.session_selected.connect(_use_session)
	_composition.analysis_requested.connect(_batch.open_assets)
	_composition.stop_requested.connect(stop_all)
	_composition.operation_reported.connect(_set_status)
	for object: Control in _composition.stage.objects:
		if object.presenter != presenter:
			object.presenter.playback_failed.connect(_set_status)
	_composition.select_object(_composition.stage.objects[0].cue_path)


func _build_event_panel(parent: Container) -> void:
	_composition = CompositionPanel.new()
	_composition.scene_resource = composition_scene
	_composition.sound_candidates = sound_candidates
	_composition.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_composition)
	presenter = _composition.stage.objects[0].presenter


func _current_object_name() -> String:
	return _composition.object_name(cue_path)


func _use_session(selected: Session) -> void:
	stop_all()
	session = selected
	cue_path = session.target_path
	for object: Control in _composition.stage.objects:
		if object.cue_path == cue_path:
			presenter = object.presenter
	_refresh()


func _refresh() -> void:
	super()
	_composition.update_trial(session)


func _set_dark_theme(enabled: bool) -> void:
	super(enabled)
	if _composition != null:
		_composition.set_background(enabled)


func stop_all() -> void:
	super()
	if _composition != null:
		_composition.stage.stop()
