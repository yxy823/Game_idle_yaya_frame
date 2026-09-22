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
	_composition.select_object(String(_composition.stage.get_path_to(_composition.stage.objects[0])))


func _build_event_panel(parent: Container) -> void:
	_composition = CompositionPanel.new()
	_composition.scene_resource = composition_scene
	_composition.sound_candidates = sound_candidates
	_composition.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_composition)
	presenter = _composition.stage.objects[0].presenter
	_composition.select_object(String(_composition.stage.get_path_to(_composition.stage.objects[0])))


func _current_object_name() -> String:
	return _composition.object_name()


func _use_session(selected: Session) -> void:
	stop_all()
	session = selected
	cue_path = session.target_path
	presenter = _composition.current_object().presenter
	_refresh()


func _preview_trial() -> void:
	# One configure per edit; object identity is independent of its shared save path.
	_composition.current_object().preview(session.current())
	_composition.refresh_state()


func _set_dark_theme(enabled: bool) -> void:
	super(enabled)
	if _composition != null:
		_composition.set_background(enabled)


func stop_all() -> void:
	super()
	if _composition != null:
		_composition.stage.stop()
