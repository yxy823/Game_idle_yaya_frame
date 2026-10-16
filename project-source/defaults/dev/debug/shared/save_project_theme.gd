extends SceneTree
## Saves the theme built from the shared UI tokens into the project theme file, so the editor's 2D
## view shows the tokens; the UiTheme autoload still rebuilds it at runtime. Run after a token
## changes, see the follow-up steps in dev/debug/_shared/README.md.
## Usage: --headless --editor --path . --script res://dev/debug/shared/save_project_theme.gd

const UiThemeScript := preload("res://game/shared/ui/ui_theme.gd")
const PATH := "res://game/shared/ui/project_theme.tres"


## Outside the editor the saver drops the file's UID.
func _initialize() -> void:
	if not Engine.is_editor_hint():
		push_error("Run with --headless --editor --script")
		quit(2)
		return
	_run.call_deferred()


func _run() -> void:
	var filesystem := EditorInterface.get_resource_filesystem()
	while filesystem.is_scanning() or filesystem.is_importing():
		await process_frame
	var error := ResourceSaver.save(build(), PATH)
	if error != OK:
		push_error("Cannot save %s: %s" % [PATH, error_string(error)])
	quit(0 if error == OK else 1)


## Style boxes get IDs from where the theme uses them, so an unchanged build saves the same text.
static func build() -> Theme:
	var theme := UiThemeScript.builder().build()
	for type in theme.get_stylebox_type_list():
		for item in theme.get_stylebox_list(type):
			theme.get_stylebox(item, type).resource_scene_unique_id = "%s_%s" % [type, item]
	return theme
