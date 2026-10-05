extends Node

## Owns a local upstream pool. No singleton, shared bus gain, or escaped player handles.
## Only this file knows the third-party API; music and spatial audio are outside this slice.

const PlayerPool = preload("res://addons/sound_manager/abstract_audio_player_pool.gd")
const MAX_VOICES: int = 16

var _pool: PlayerPool = PlayerPool.new(["Master"], 2)


func _init() -> void:
	add_child(_pool)


func _exit_tree() -> void:
	stop_all()


func play(stream: AudioStream, gain_db: float, pitch: float, bus: StringName) -> Error:
	if stream == null or AudioServer.get_bus_index(bus) < 0:
		return ERR_INVALID_PARAMETER
	if active_voice_count() >= MAX_VOICES:
		return ERR_BUSY
	# Immediate play avoids an upstream deferred play surviving a same-frame stop.
	var player: AudioStreamPlayer = _pool.get_available_player()
	player.stream = stream
	player.bus = bus
	player.volume_db = gain_db
	player.pitch_scale = pitch
	_pool.mark_player_as_busy(player)
	player.play()
	return OK


func stop_all() -> void:
	# stop() emits no finished signal; return each owned player explicitly.
	for player: AudioStreamPlayer in _pool.busy_players.duplicate():
		player.stop()
		player.stream = null
		_pool.mark_player_as_available(player)


func active_voice_count() -> int:
	return _pool.busy_players.size()
