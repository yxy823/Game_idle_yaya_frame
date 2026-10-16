extends Node
## Autoload UiTheme: fills the project theme (Project Settings gui/theme/custom) from the shared
## UI tokens and refills it after a token changes. The project theme reaches every Control,
## including those under a CanvasLayer, which a theme on the root window does not. The file holds
## the same build so the editor's 2D view shows the tokens; a development script saves it.

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

var _builder := builder()
var _rebuild_queued := false


static func builder() -> UiThemeBuilder:
	var result := UiThemeBuilder.new()
	result.palette = PALETTE
	result.font_sizes = FONT_SIZES
	result.spacing = SPACING
	result.radii = RADII
	result.border_widths = BORDER_WIDTHS
	result.shadows = SHADOWS
	result.text = TEXT
	result.panel = PANEL
	result.button_primary = BUTTON_PRIMARY
	result.button_secondary = BUTTON_SECONDARY
	result.button_danger = BUTTON_DANGER
	result.line_edit = LINE_EDIT
	result.progress_bar = PROGRESS_BAR
	return result


func _ready() -> void:
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
