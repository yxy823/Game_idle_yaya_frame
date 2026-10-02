extends SceneTree

## Run with --main-pack from the report directory, not the source project.
## This probes the exported dependency closure; it is not a production export preset.

const BASE: String = "res://asset_workbench/examples/"
const ENTRIES: Array[String] = ["single/example_game.tscn",
	"composition/example_composition.tscn", "shader_composition/example_composition.tscn",
	"effects_composition/example_consumer.tscn"]

var _failures: Array[String] = []
var _cases: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(not DirAccess.dir_exists_absolute("res://asset_workbench/ui"), "No workbench in pack")
	_check(not DirAccess.dir_exists_absolute("res://asset_workbench/analyzer"), "No analyzer in pack")
	_check(not DirAccess.dir_exists_absolute("res://tests"), "No tests in pack")
	for index: int in ENTRIES.size():
		await _consume(index)
	# The audio thread retires stopped stream playbacks on its next mix, after node release.
	await create_timer(AudioServer.get_output_latency() + 0.1).timeout
	var result := {"passed": _failures.is_empty(), "cases": _cases, "failures": _failures,
		"engine": Engine.get_version_info().string}
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass one absolute JSON output path after --.")
		quit(2)
		return
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		push_error("Cannot write export probe result: " + args[0])
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	quit(0 if _failures.is_empty() else 1)


func _consume(index: int) -> void:
	var path := BASE + ENTRIES[index]
	var packed := load(path) as PackedScene
	_check(packed != null, path + ": load")
	if packed == null:
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	var presenters: Array[Node] = []
	if index == 0:
		_check(scene.get("cue") != null, path + ": saved cue")
		presenters.append(scene.get("_presenter"))
		scene.call("activate_example")
	else:
		var objects: Array = scene.get("objects")
		_check(objects.size() == (6 if index == 3 else 3), path + ": objects")
		for object: Node in objects:
			_check(object.get("cue") != null, path + ": " + String(object.name) + " cue")
			presenters.append(object.get("presenter"))
		scene.call("trigger_all")
	await create_timer(0.2).timeout
	var voices := 0
	for presenter: Node in presenters:
		_check(presenter.call("playback_error") == "", path + ": valid media bindings")
		_check(presenter.call("is_playing"), path + ": active playback")
		voices += int(presenter.call("active_voice_count"))
	_check(voices > 0, path + ": real audio voices")
	if index == 3:
		_check(scene.call("play_timeline", true) == "", path + ": timeline start")
		await create_timer(0.1).timeout
		_check(scene.get("manager").active_count() > 0, path + ": managed playback")
	await _release_scene(scene, presenters, path)
	_cases.append({"entry": ENTRIES[index], "presenters": presenters.size(), "voices": voices})


func _release_scene(scene: Node, presenters: Array[Node], path: String) -> void:
	if scene.has_method("stop"):
		scene.call("stop")
	for presenter: Node in presenters:
		presenter.call("stop")
		_check(not presenter.call("is_playing"), path + ": stopped")
	scene.free()
	await process_frame
	_check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == 0,
		path + ": released")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
