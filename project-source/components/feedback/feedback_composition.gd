extends Control

## Scene-relative node paths identify instances; a shared Cue path is only a save target.

signal object_selected(path: String)
signal playback_reported(message: String)

const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Manager = preload("res://components/feedback/feedback_playback_manager.gd")
const TimelinePlayer = preload("res://components/feedback/feedback_timeline_player.gd")

@export var object_nodes: Array[NodePath] = []
@export var timeline: FeedbackTimeline
@export_range(1, 128, 1) var managed_object_limit: int = 8

var objects: Array[ObjectView] = []
var manager: Manager
var timeline_player: TimelinePlayer


func _ready() -> void:
	for path: NodePath in object_nodes:
		var object := get_node_or_null(path) as ObjectView
		if object != null and object not in objects:
			objects.append(object)
			object.object_selected.connect(func() -> void:
				object_selected.emit(String(get_path_to(object))))
			object.tree_exiting.connect(func() -> void: objects.erase(object), CONNECT_ONE_SHOT)
	if timeline != null:
		manager = Manager.new()
		manager.max_active = managed_object_limit
		add_child(manager)
		timeline_player = TimelinePlayer.new()
		add_child(timeline_player)
		timeline_player.playback_issue.connect(playback_reported.emit)
		manager.request_rejected.connect(playback_reported.emit)


func _exit_tree() -> void:
	stop()


func object_at(path: String) -> ObjectView:
	var object := get_node_or_null(NodePath(path)) as ObjectView
	return object if object in objects else null


func preview(path: String, cue: FeedbackCue) -> void:
	var object := object_at(path)
	if object != null:
		object.preview(cue)


func trigger_all() -> void:
	_stop_managed()
	for object: ObjectView in objects:
		object.presenter.trigger()


func play_timeline(repeat: bool = false) -> String:
	if timeline_player == null:
		return "No timeline is configured for this composition."
	stop()
	return timeline_player.play(timeline, self, manager, repeat)


func highlight(path: String) -> void:
	for object: ObjectView in objects:
		object.set_pressed_no_signal(String(get_path_to(object)) == path)


func stop() -> void:
	_stop_managed()
	for object: ObjectView in objects:
		if is_instance_valid(object):
			object.presenter.stop()


func set_background(color: Color) -> void:
	($Background as ColorRect).color = color


func _stop_managed() -> void:
	if is_instance_valid(timeline_player):
		timeline_player.stop()
	if is_instance_valid(manager):
		manager.stop_all()
