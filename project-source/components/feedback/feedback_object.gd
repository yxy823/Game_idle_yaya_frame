extends Button

## A selectable presentation object. No reward logic or gameplay state is executed.

signal object_selected

const Presenter = preload("res://components/feedback/feedback_presenter.gd")

@export var cue_resource: FeedbackCue

var presenter: Presenter = Presenter.new()
var cue: FeedbackCue
var display_name: String
var cue_path: String:
	get:
		return cue_resource.resource_path if cue_resource != null else ""

var _label: Label = Label.new()


func _init() -> void:
	# Keep the label below the presenter and own both before any scene-tree entry.
	add_child(_label)
	add_child(presenter)


func _ready() -> void:
	toggle_mode = true
	display_name = text if not text.is_empty() else String(name)
	theme_type_variation = "PreviewObject"
	_label.text = display_name
	_label.position = Vector2(10, 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = ""
	presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	presenter.offset_top = 25
	pressed.connect(_activate)
	if cue_path.is_empty() or not ResourceLoader.exists(cue_path):
		tooltip_text = "Missing or invalid saved Cue binding."
		return
	# The scene reference declares export dependencies; reload to see the latest saved values.
	var saved := ResourceLoader.load(cue_path, "", ResourceLoader.CACHE_MODE_IGNORE) as FeedbackCue
	if saved != null:
		preview(saved)
	else:
		tooltip_text = "Missing or invalid saved Cue binding."


func preview(value: FeedbackCue) -> void:
	cue = value.trial_copy()
	presenter.configure(cue)


func _activate() -> void:
	object_selected.emit()
	presenter.trigger()
