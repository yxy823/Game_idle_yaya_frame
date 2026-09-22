extends Node2D

## Separate transform layers let Tween motion and authored clips compose without property races.
## The object label, selection border and the presenter's layout remain outside both layers.

var content: Node2D = Node2D.new()

var _tween_root: Node2D = Node2D.new()
var _player: AnimationPlayer = AnimationPlayer.new()
var _tween: Tween
var _cue: FeedbackCue


func _ready() -> void:
	add_child(_tween_root)
	_tween_root.add_child(content)
	content.add_child(_player)
	_player.animation_finished.connect(_on_clip_finished)


func _exit_tree() -> void:
	stop()


func configure(cue: FeedbackCue) -> void:
	stop()
	_cue = cue
	if _player.has_animation_library(&""):
		_player.remove_animation_library(&"")
	if cue.animation_clip != null:
		var library := AnimationLibrary.new()
		library.add_animation(&"effect", cue.animation_clip)
		_player.add_animation_library(&"", library)


func trigger() -> void:
	stop()
	if _cue.tween_enabled:
		_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_tween_root, "position:y", -_cue.tween_distance,
			_cue.tween_seconds * 0.5)
		_tween.tween_property(_tween_root, "position:y", 0.0, _cue.tween_seconds * 0.5)
	if _cue.animation_clip != null:
		_player.play(&"effect", -1.0, _cue.animation_speed)
		_player.advance(0.0)


func stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	# Restore our owned transform below, without seeking a clip that configure may have removed.
	_player.stop(true)
	_tween_root.position = Vector2.ZERO
	content.transform = Transform2D.IDENTITY


func active_count() -> int:
	var tween_active := _tween != null and _tween.is_valid() and _tween.is_running()
	return int(tween_active) + int(_player.is_playing())


func _on_clip_finished(_animation: StringName) -> void:
	content.transform = Transform2D.IDENTITY
