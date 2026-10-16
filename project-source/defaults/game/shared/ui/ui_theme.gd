extends Node
## Autoload UiTheme: fills the project theme (Project Settings gui/theme/custom) from the shared
## UI tokens and refills it after a token changes. The project theme reaches every Control,
## including those under a CanvasLayer, which a theme on the root window does not.

const PALETTE := preload("res://game/shared/tuning/ui/primitives/palette.tres")
const FONT_SIZES := preload("res://game/shared/tuning/ui/primitives/font_sizes.tres")
const SPACING := preload("res://game/shared/tuning/ui/primitives/spacing.tres")
const RADII := preload("res://game/shared/tuning/ui/primitives/radii.tres")
const BORDER_WIDTHS := preload("res://game/shared/tuning/ui/primitives/border_widths.tres")
const SHADOWS := preload("res://game/shared/tuning/ui/primitives/shadows.tres")
const TEXT := preload("res://game/shared/tuning/ui/semantic/text.tres")
const PANEL := preload("res://game/shared/tuning/ui/semantic/panel.tres")
const BUTTON_PRIMARY := preload("res://game/shared/tuning/ui/semantic/buttons/primary.tres")
const BUTTON_SECONDARY := preload("res://game/shared/tuning/ui/semantic/buttons/secondary.tres")
const BUTTON_DANGER := preload("res://game/shared/tuning/ui/semantic/buttons/danger.tres")
const LINE_EDIT := preload("res://game/shared/tuning/ui/semantic/line_edit.tres")
const PROGRESS_BAR := preload("res://game/shared/tuning/ui/semantic/progress_bar.tres")

var _builder := UiThemeBuilder.new()
var _rebuild_queued := false


func _ready() -> void:
	_builder.palette = PALETTE
	_builder.font_sizes = FONT_SIZES
	_builder.spacing = SPACING
	_builder.radii = RADII
	_builder.border_widths = BORDER_WIDTHS
	_builder.shadows = SHADOWS
	_builder.text = TEXT
	_builder.panel = PANEL
	_builder.button_primary = BUTTON_PRIMARY
	_builder.button_secondary = BUTTON_SECONDARY
	_builder.button_danger = BUTTON_DANGER
	_builder.line_edit = LINE_EDIT
	_builder.progress_bar = PROGRESS_BAR
	for token in _builder.tokens():
		token.changed.connect(_queue_rebuild)
	_rebuild()


## A preset sets many fields at once; rebuild once after all of them.
func _queue_rebuild() -> void:
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	# Merging replaces every item the builder writes and emits the theme's changed once.
	ThemeDB.get_project_theme().merge_with(_builder.build())
