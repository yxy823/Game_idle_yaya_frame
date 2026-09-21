extends Control

## Real scene objects expose a small explicit presentation interface to the workbench.

signal object_selected(path: String)

const ObjectView = preload("res://components/feedback/feedback_object.gd")

@export var object_nodes: Array[NodePath] = []

var objects: Array[ObjectView] = []


func _ready() -> void:
	for path: NodePath in object_nodes:
		var object := get_node(path) as ObjectView
		if object != null:
			objects.append(object)
			object.object_selected.connect(func(cue_path: String) -> void:
				object_selected.emit(cue_path))


func preview(path: String, cue: FeedbackCue) -> void:
	for object: ObjectView in objects:
		if object.cue_path == path:
			object.preview(cue)


func trigger_all() -> void:
	for object: ObjectView in objects:
		object.presenter.trigger()


func highlight(path: String) -> void:
	for object: ObjectView in objects:
		object.set_pressed_no_signal(object.cue_path == path)


func stop() -> void:
	for object: ObjectView in objects:
		object.presenter.stop()


func set_background(color: Color) -> void:
	($Background as ColorRect).color = color
