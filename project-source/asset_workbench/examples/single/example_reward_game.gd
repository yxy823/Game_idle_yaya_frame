extends Control

## Test consumer, not a starter game's product or business requirement.

const Presenter = preload("res://components/feedback/feedback_presenter.gd")

@export var cue_resource: FeedbackCue

var cue: FeedbackCue
var reward_count: int = 0

var _presenter: Presenter = Presenter.new()
var _count: Label = Label.new()
var _button: Button = Button.new()


func _init() -> void:
	# Labels sit on white; buttons keep Godot's native styles, state colors and focus border.
	theme = Theme.new()
	theme.set_color("font_color", "Label", Color.BLACK)
	var background := ColorRect.new()
	background.color = Color.WHITE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	var title := Label.new()
	title.text = "EXAMPLE GAME  /  saved cue consumer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	_presenter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_presenter)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_count)
	_button.text = "Collect example reward"
	_button.custom_minimum_size.y = 60.0
	_button.pressed.connect(activate_example)
	column.add_child(_button)


func _ready() -> void:
	var path := cue_resource.resource_path if cue_resource != null else ""
	if not path.is_empty() and ResourceLoader.exists(path):
		# The bound resource may be cached by the PackedScene before the workbench saves.
		cue = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as FeedbackCue
	if cue == null:
		_count.text = "Missing or invalid example cue."
		_button.disabled = true
		return
	_presenter.configure(cue)
	_count.text = "0 example rewards. This counter exists only in this running scene."


func activate_example() -> void:
	if cue == null:
		return
	reward_count += 1
	_count.text = "%d example rewards / saved gain %.1f dB / delay %.2f s" % [
		reward_count, cue.gain_db, cue.delay_seconds,
	]
	_presenter.trigger()
