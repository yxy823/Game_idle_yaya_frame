extends Node2D
## Sample game for the shared debug tests. start() reads its save file and plays the rounds it
## names; each round shows the effect and plays the sound of the tuning resources, waits the
## timing's hold, then the game writes its result back to the save and reports the end.

signal round_started(number: int)
signal finished()

const SOUND := preload("res://dev/debug/_shared/tests/fixtures/sample/game/sample/tuning/feedback/sound.tres")
const EFFECT := preload("res://dev/debug/_shared/tests/fixtures/sample/game/sample/tuning/feedback/effect.tres")
const TIMING := preload("res://dev/debug/_shared/tests/fixtures/sample/game/sample/tuning/timing.tres")

## The save file, "" for none; tests point it at a temporary file, the way a project's
## debug_project.gd points the real save at a debug-only file.
static var save_path: String = ""

var sound: Resource = SOUND
var effect: Resource = EFFECT
var rng := RandomNumberGenerator.new()
var draws: Array[int] = []
var rounds_played: int = 0
var _rounds: int = 0

@onready var feedback: Node2D = %Feedback
@onready var sounds: Node = $Sounds


## Without a save that asks for rounds the game has nothing to play and ends at once.
func start() -> void:
	var data: Variant = null
	if FileAccess.file_exists(save_path):
		data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	_rounds = int(data.get("rounds", 0)) if data is Dictionary else 0
	if data is Dictionary and data.get("start", false) and _rounds > 0:
		play_round(1)
	else:
		_finish()


func play_round(number: int) -> void:
	rounds_played = number
	var wait := create_tween()
	wait.tween_interval(TIMING.hold)
	wait.tween_callback(_finish if number >= _rounds else play_round.bind(number + 1))
	draws.append(rng.randi_range(0, 99))
	if effect.candidate != null:
		var shown := effect.candidate.instantiate() as Node2D
		feedback.add_child(shown)
		shown.play(effect.candidate_params)
	if sound.candidate != null:
		var player := AudioStreamPlayer.new()
		player.stream = sound.candidate
		player.volume_db = sound.volume_db
		player.finished.connect(player.queue_free)
		sounds.add_child(player)
		player.play()
	round_started.emit(number)


func _finish() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE) if not save_path.is_empty() else null
	if file != null:
		file.store_string(JSON.stringify({"rounds_played": rounds_played, "draws": draws}))
		file.close()
	finished.emit()
