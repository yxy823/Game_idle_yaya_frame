extends Button

## A selectable presentation object. No reward logic or gameplay state is executed.

signal object_selected

const Presenter = preload("res://components/feedback/feedback_presenter.gd")

@export_file("*.tres") var cue_path: String

var presenter: Presenter = Presenter.new()
var cue: FeedbackCue
var display_name: String


func _ready() -> void:
	toggle_mode = true
	display_name = text if not text.is_empty() else String(name)
	theme_type_variation = "PreviewObject"
	var label := Label.new()
	label.text = display_name
	label.position = Vector2(10, 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	text = ""
	presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(presenter)
	presenter.offset_top = 25
	pressed.connect(_activate)
	var saved := ResourceLoader.load(cue_path, "", ResourceLoader.CACHE_MODE_IGNORE) as FeedbackCue
	if saved != null:
		preview(saved)


func preview(value: FeedbackCue) -> void:
	cue = value.trial_copy()
	presenter.configure(cue)


func _activate() -> void:
	object_selected.emit()
	presenter.trigger()
