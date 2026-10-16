extends GdUnitTestSuite
## The saved project theme, which the editor's 2D view shows, matches the build from the tokens.

const SaveProjectTheme := preload("res://dev/debug/shared/save_project_theme.gd")
const BUILT := "user://tests/project_theme.tres"
const COMMAND := ("& $projectGodot --headless --editor --path . --script "
	+ "res://dev/debug/shared/save_project_theme.gd")


func after_test() -> void:
	DirAccess.remove_absolute(BUILT)


func test_saved_project_theme_matches_tokens() -> void:
	DirAccess.make_dir_recursive_absolute(BUILT.get_base_dir())
	assert_int(ResourceSaver.save(SaveProjectTheme.build(), BUILT)).is_equal(OK)
	assert_str(_body(SaveProjectTheme.PATH)).override_failure_message(
		"project_theme.tres 与当前 token 生成的主题不一致，在项目根目录运行：" + COMMAND
	).is_equal(_body(BUILT))


## Without the header line, which holds each file's own UID.
func _body(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	return text.substr(text.find("\n"))
