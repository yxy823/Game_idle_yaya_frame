extends RefCounted
## Adapter of the sample debug target: its main scene, fixtures and how playback knows a pass
## has ended; the shared code never names the sample game's script or signals.

## Name in the target dropdown.
const TITLE := "样例"
const MAIN_SCENE := "res://dev/debug/_shared/tests/fixtures/sample/game/sample/sample_main.tscn"
const GAME := preload("res://dev/debug/_shared/tests/fixtures/sample/game/sample/sample_game.gd")
const FIXTURES: Dictionary[String, String] = {
	"两轮": "res://dev/debug/_shared/tests/fixtures/sample/debug/sample/fixtures/two_rounds.json",
}
## Slot list group titles by category path.
const CATEGORIES: Dictionary[String, String] = {"sample": "样例", "sample/feedback": "反馈"}

var game: Node


func matches(scene: Node) -> bool:
	var game_node := scene.get_node_or_null("Game") if scene != null else null
	return game_node != null and accepts(game_node)


func accepts(node: Node) -> bool:
	return node.get_script() == GAME


## Writes the fixture into the debug save; `still` keeps the game at its start.
func prepare_fixture(path: String, save_path: String, still: bool = false) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("seed") is String:
		return {"error": ERR_INVALID_DATA, "message": path}
	if still:
		data.start = false
	var error := DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var output := FileAccess.open(save_path, FileAccess.WRITE) if error == OK else null
	if output == null:
		return {"error": error if error != OK else FileAccess.get_open_error(), "message": save_path}
	output.store_string(JSON.stringify(data))
	output.close()
	return {"error": OK, "seed": String(data.seed).to_int()}


func bind(node: Node, seed_value: int) -> void:
	game = node
	game.rng.seed = seed_value


func connect_finished(callback: Callable) -> void:
	game.finished.connect(callback)


func advance_feedback(_delta: float) -> void:
	pass


func feedback_pending() -> bool:
	if not is_instance_valid(game):
		return false
	return game.feedback.get_child_count() > 0 or game.sounds.get_child_count() > 0
