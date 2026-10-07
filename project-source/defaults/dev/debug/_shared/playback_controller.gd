extends Node

signal changed()
signal failed(result: Dictionary)
signal next_pass()

enum State { IDLE, STARTING, PLAYING, PAUSED, TAIL }
const SPEEDS: Array[float] = [0.1, 0.25, 0.5, 0.75, 1.0, 2.0]
const LOOPS: Array[int] = [1, 3, 5, -1]

var state: State = State.IDLE
var speed: float = 1.0
var loop_count: int = 1
var completed: int = 0
var fixture: String = ""
var main_scene: String = ""
var adapter: RefCounted
var reload_scene: Callable
## The debug save that debug_project.gd chose; the adapter writes the fixture there.
var save_path: String = ""
var _previous_pause: bool
var _previous_scale: float
var _previous_audio: float
var _resume_state: State
var _generation: int = 0
var _sound_seed: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_previous_pause = get_tree().paused
	_previous_scale = Engine.time_scale
	_previous_audio = AudioServer.playback_speed_scale
	set_process(false)


func configure(path: String) -> void:
	save_path = path


func locked() -> bool:
	return state != State.IDLE


func set_speed(value: float) -> void:
	assert(value in SPEEDS)
	speed = value
	Engine.time_scale = value
	AudioServer.playback_speed_scale = value
	changed.emit()


func start(path: String, target_adapter: RefCounted) -> Error:
	if locked():
		return ERR_BUSY
	fixture = path
	adapter = target_adapter
	main_scene = adapter.MAIN_SCENE
	completed = 0
	return _reload()


## Loads the fixture again: playing from its first move, or `still` at its starting layout.
func _reload(still: bool = false) -> Error:
	_generation += 1
	var prepared: Dictionary = adapter.prepare_fixture(fixture, save_path, still)
	if prepared.error != OK:
		_abort(prepared)
		return prepared.error
	_sound_seed = prepared.seed
	get_tree().paused = _previous_pause if still else false
	state = State.IDLE if still else State.STARTING
	if still:
		set_process(false)
	next_pass.emit()
	changed.emit()
	var error: Error = reload_scene.call(main_scene) if reload_scene.is_valid() \
		else get_tree().change_scene_to_file(main_scene)
	if error != OK:
		_abort({"error": error, "message": main_scene})
	return error


## Called from node_added, before main._ready may emit a synchronous finish.
func observe_node(node: Node) -> void:
	if adapter != null and locked() and adapter.accepts(node):
		node.ready.connect(_target_ready.bind(node, _generation), CONNECT_ONE_SHOT)


func _target_ready(node: Node, generation: int) -> void:
	if not locked() or generation != _generation:
		return
	adapter.bind(node, _sound_seed)
	adapter.connect_finished(_finished.bind(_generation))
	if state == State.PAUSED:
		_resume_state = State.PLAYING
	else:
		state = State.PLAYING
	set_process(true)
	changed.emit()


func _finished(generation: int) -> void:
	if generation != _generation or not locked():
		return
	if state == State.PAUSED:
		_resume_state = State.TAIL
	else:
		state = State.TAIL
	changed.emit()


func _process(delta: float) -> void:
	if state == State.PAUSED or state == State.STARTING:
		return
	adapter.advance_feedback(delta)
	if state != State.TAIL or adapter.feedback_pending():
		return
	completed += 1
	if loop_count < 0 or completed < loop_count:
		_reload_if_current.call_deferred(_generation)
		state = State.STARTING
	else:
		state = State.IDLE
		set_process(false)
	changed.emit()


func _reload_if_current(generation: int) -> void:
	if generation == _generation and locked():
		_reload()


func toggle_pause() -> void:
	if not locked():
		return
	if state == State.PAUSED:
		state = _resume_state
		get_tree().paused = false
	else:
		_resume_state = state
		state = State.PAUSED
		get_tree().paused = true
	changed.emit()


## Ends playback and unlocks the parameters; the fixture's starting layout stays still.
func reset_to_start() -> Error:
	if fixture.is_empty():
		return ERR_UNAVAILABLE
	completed = 0
	return _reload(true)


func cancel() -> void:
	_generation += 1
	state = State.IDLE
	get_tree().paused = _previous_pause
	set_process(false)
	changed.emit()


func _abort(result: Dictionary) -> void:
	cancel()
	failed.emit(result)


func _exit_tree() -> void:
	Engine.time_scale = _previous_scale
	AudioServer.playback_speed_scale = _previous_audio
	if is_inside_tree():
		get_tree().paused = _previous_pause
