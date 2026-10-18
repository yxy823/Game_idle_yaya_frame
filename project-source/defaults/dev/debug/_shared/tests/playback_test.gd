extends GdUnitTestSuite
## Fixture playback on the sample game: two rounds a pass, pause, speed, loops, reset and the
## compare switch that waits for the next pass. The sample game saves to a temporary file.

const Playback := preload("res://dev/debug/_shared/playback_controller.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Trial := preload(
	"res://dev/debug/_shared/tests/fixtures/sample/debug/sample/slots/feedback/effect/slot.gd")
## Paths, not preloads: a test-script constant holding a script that cached tuning resources
## use leaks at exit.
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const ADAPTER := SAMPLE + "debug/sample/debug_target.gd"
const MAIN := SAMPLE + "game/sample/sample_main.tscn"
const GAME := SAMPLE + "game/sample/sample_game.gd"
const TUNING := SAMPLE + "game/sample/tuning/"

var _controller: Playback
var _game: Script
var _adapter: Script
var _original_save: String
var _directory: String
var _scene: Node
var _held: Array[Tween] = []
var _rounds: Array[int] = []
var _passes: Array[int] = []


func before_test() -> void:
	_directory = "user://tests/debug-playback-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_directory)
	_game = load(GAME) as Script
	_adapter = load(ADAPTER) as Script
	_original_save = _game.get("save_path")
	# What a project's debug_project.gd does: the game saves to a debug-only file.
	_game.set("save_path", _directory.path_join("sample.json"))
	_controller = auto_free(Playback.new()) as Playback
	add_child(_controller)
	_controller.configure(_game.get("save_path"))
	_controller.reload_scene = _reload
	_controller.next_pass.connect(func() -> void: _passes.append(_passes.size() + 1))
	_held.clear()
	_rounds.clear()
	_passes.clear()


func after_test() -> void:
	_controller.cancel()
	if is_instance_valid(_scene):
		_scene.queue_free()
		_scene = null
	_game.set("save_path", _original_save)
	await get_tree().process_frame
	_remove(_directory)


func test_fixture_runs_its_rounds_with_the_same_rng_into_the_debug_save() -> void:
	assert_int(_start()).is_equal(OK)
	assert_int(_controller.state).is_equal(Playback.State.PLAYING)
	_finish_rounds()
	var draws: Array = _scene.get_node("Game").draws.duplicate()
	assert_array(_rounds).contains_exactly([1, 2])
	assert_int(draws.size()).is_equal(2)
	assert_int(_controller.state).is_equal(Playback.State.TAIL)
	assert_bool(_controller.locked()).is_true()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		_controller.save_path))
	assert_int(int(saved.rounds_played)).is_equal(2)
	await _drain_feedback()
	assert_int(_controller.state).is_equal(Playback.State.IDLE)
	assert_int(_controller.completed).is_equal(1)
	_start()
	_finish_rounds()
	assert_array(_scene.get_node("Game").draws).contains_exactly(draws)


func test_paused_playback_locks_parameters_and_debug_controller_remains_active() -> void:
	_start()
	_controller.toggle_pause()
	assert_bool(get_tree().paused).is_true()
	assert_int(_controller.state).is_equal(Playback.State.PAUSED)
	assert_bool(_controller.locked()).is_true()
	assert_bool(_controller.can_process()).is_true()
	assert_bool(_scene.get_node("Game").can_process()).is_false()
	_controller.toggle_pause()
	assert_bool(get_tree().paused).is_false()
	assert_int(_controller.state).is_equal(Playback.State.PLAYING)


func test_speed_sets_engine_and_audio_without_changing_tuning() -> void:
	var sound := ResourceLoader.load(TUNING + "feedback/sound.tres")
	var volume: float = sound.volume_db
	for value in Playback.SPEEDS:
		_controller.set_speed(value)
		assert_float(Engine.time_scale).is_equal(value)
		assert_float(AudioServer.playback_speed_scale).is_equal_approx(value, 0.0001)
	assert_float(sound.volume_db).is_equal(volume)
	_controller.set_speed(1.0)


func test_loops_reset_fixture_and_only_finish_after_feedback_tail() -> void:
	_controller.loop_count = 3
	_start()
	for pass_index in range(3):
		_finish_rounds()
		await _drain_feedback()
		if pass_index < 2:
			await get_tree().process_frame
	assert_int(_controller.completed).is_equal(3)
	assert_array(_passes).contains_exactly([1, 2, 3])
	assert_int(_controller.state).is_equal(Playback.State.IDLE)


func test_reset_ends_playback_unlocks_and_stays_at_the_start() -> void:
	_start()
	_controller.toggle_pause()
	var old_tweens := _held.duplicate()
	assert_int(_controller.reset_to_start()).is_equal(OK)
	assert_int(_controller.state).is_equal(Playback.State.IDLE)
	assert_bool(_controller.locked()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_array(_rounds).is_empty()
	assert_int(_scene.get_node("Game").rounds_played).is_equal(0)
	for tween: Tween in old_tweens:
		tween.custom_step(2.0)
	await get_tree().process_frame
	assert_int(_controller.state).is_equal(Playback.State.IDLE)
	assert_int(_start()).is_equal(OK)
	assert_array(_rounds).contains_exactly([1])


func test_five_loops_complete_and_infinite_loops_wait_for_cancel() -> void:
	_controller.loop_count = 5
	_start()
	for pass_index in range(5):
		_finish_rounds()
		await _drain_feedback()
		if pass_index < 4:
			await get_tree().process_frame
	assert_int(_controller.completed).is_equal(5)
	assert_int(_controller.state).is_equal(Playback.State.IDLE)
	_controller.loop_count = -1
	_start()
	_finish_rounds()
	await _drain_feedback()
	await get_tree().process_frame
	assert_bool(_controller.locked()).is_true()
	assert_int(_controller.completed).is_equal(1)
	_controller.cancel()
	assert_bool(_controller.locked()).is_false()


func test_fixture_without_a_start_captures_the_synchronous_finish() -> void:
	var path := _directory.path_join("no-start.json")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_fixture()))
	data.start = false
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	assert_int(_controller.start(path, _adapter.new())).is_equal(OK)
	assert_array(_rounds).is_empty()
	assert_int(_controller.state).is_equal(Playback.State.TAIL)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(_controller.state).is_equal(Playback.State.IDLE)
	assert_int(_controller.completed).is_equal(1)


func test_compare_switch_is_delayed_until_next_pass() -> void:
	var path := _directory.path_join("timing.tres")
	var tuning := ResourceLoader.load(TUNING + "timing.tres", "",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	ResourceSaver.save(tuning, path)
	var slot := Slot.new()
	slot.configure("sample", "timing", path, _directory)
	var session := Session.new()
	session.store.root = _directory
	session.slots = [slot]
	session.selected = slot
	var game_value: float = slot.live.hold
	slot.live.hold = game_value + 0.25
	_start()
	_controller.next_pass.connect(session.compare.apply_pending)
	assert_str(session.compare.toggle(true).text).is_equal("下一遍开头切到游戏原值")
	assert_float(slot.live.hold).is_equal(game_value + 0.25)
	assert_bool(session.compare.pending).is_true()
	_controller.cancel()
	_start()
	assert_float(slot.live.hold).is_equal(game_value)
	assert_bool(session.compare.showing).is_true()
	assert_bool(session.compare.pending).is_false()
	session.compare.toggle(true)
	_controller.cancel()
	_start()
	assert_float(slot.live.hold).is_equal(game_value + 0.25)
	assert_bool(session.compare.showing).is_false()


func test_slot_trial_uses_live_candidate_parameters() -> void:
	_start()
	var tuning := ResourceLoader.load(TUNING + "feedback/effect.tres", "",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	tuning.candidate_params.size = 160.0
	assert_int(Trial.new().run("中央试播一次", tuning, _scene).error).is_equal(OK)
	var feedback := _scene.get_node("Game/%Feedback")
	var effect := feedback.get_child(feedback.get_child_count() - 1) as Node2D
	assert_vector(effect.position).is_equal(Vector2.ONE * 320.0)
	assert_float(effect.scale.x).is_equal_approx(1.6, 0.001)


func _fixture() -> String:
	return _adapter.get_script_constant_map().FIXTURES["两轮"]


func _start() -> Error:
	return _controller.start(_fixture(), _adapter.new())


func _reload(_path: String) -> Error:
	if is_instance_valid(_scene):
		_scene.queue_free()
	_scene = (load(MAIN) as PackedScene).instantiate()
	var game := _scene.get_node("Game")
	_controller.observe_node(game)
	game.round_started.connect(_round_started)
	_held.clear()
	_rounds.clear()
	add_child(_scene)
	return OK


## Holds each round's wait so the test decides when a round ends.
func _round_started(number: int) -> void:
	_rounds.append(number)
	for tween in get_tree().get_processed_tweens():
		if tween.is_running() and not _held.has(tween):
			tween.pause()
			_held.append(tween)


func _finish_rounds() -> void:
	for index in range(2):
		_held[index].custom_step(2.0)


func _drain_feedback() -> void:
	var game := _scene.get_node("Game")
	for effect in game.feedback.get_children():
		effect.set_process(false)
		effect._process(4.0)
	# Sounds may outlast the test's frames; their players end here.
	for player in game.sounds.get_children():
		player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _remove(directory: String) -> void:
	for child in DirAccess.get_directories_at(directory):
		_remove(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
