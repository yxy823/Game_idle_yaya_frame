extends Control

## Scene-relative node paths identify instances; a shared Cue path is only a save target.

signal object_selected(path: String)

const ObjectView = preload("res://components/feedback/feedback_object.gd")

@export var object_nodes: Array[NodePath] = []

var objects: Array[ObjectView] = []


func _ready() -> void:
	for path: NodePath in object_nodes:
		var object := get_node_or_null(path) as ObjectView
		if object != null and object not in objects:
			objects.append(object)
			object.object_selected.connect(func() -> void:
				object_selected.emit(String(get_path_to(object))))
			object.tree_exiting.connect(func() -> void: objects.erase(object), CONNECT_ONE_SHOT)


func object_at(path: String) -> ObjectView:
	var object := get_node_or_null(NodePath(path)) as ObjectView
	return object if object in objects else null


func preview(path: String, cue: FeedbackCue) -> void:
	var object := object_at(path)
	if object != null:
		object.preview(cue)


func trigger_all() -> void:
	for object: ObjectView in objects:
		object.presenter.trigger()


func highlight(path: String) -> void:
	for object: ObjectView in objects:
		object.set_pressed_no_signal(String(get_path_to(object)) == path)


func stop() -> void:
	for object: ObjectView in objects:
		object.presenter.stop()


func set_background(color: Color) -> void:
	($Background as ColorRect).color = color
