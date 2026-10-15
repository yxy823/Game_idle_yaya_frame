extends RefCounted
## Keeps Resource UIDs pointing at files that adoption moved from dev/ into game/. The UID
## never changes; only the running game's UID table and the editor's cache learn the new path.

const HEADER_UID := "uid=\"(uid://[a-z0-9]+)\""
const EDITOR_OPEN := "Godot 编辑器正开着本项目：切回编辑器窗口，它会自动更新文件登记；更新前请从调试台启动游戏"
const GODOT_PROCESSES := "Get-CimInstance Win32_Process -Filter 'Name LIKE ''%godot%''' -ErrorAction Stop " \
	+ "| ForEach-Object CommandLine"

## This debug session owns the import; pending requests merge until its next poll.
static var _import_pid: int = -1
static var _refresh_pending: bool = false


## The UID table the game loads at start is the editor's cache, which still names the old
## dev/ paths until the editor scans again. Runs at every debug start before anything loads:
## each UID found in .import, .uid and resource headers under `root` points at its real file.
static func repair(root: String = "res://game") -> int:
	var fixed := 0
	for path in _files(root):
		var resource := path.trim_suffix(".import").trim_suffix(".uid")
		if resource == path and not path.get_extension() in ["tscn", "tres"]:
			continue
		var identity := _file_uid(resource)
		if identity == ResourceUID.INVALID_ID:
			continue
		if not ResourceUID.has_id(identity):
			ResourceUID.add_id(identity, resource)
			fixed += 1
		elif ResourceUID.get_id_path(identity) != resource:
			ResourceUID.set_id(identity, resource)
			fixed += 1
	return fixed


## Starts a headless editor import in the background, which rescans the project and saves the
## UID cache and import files with the new paths; the game itself keeps running. Only res://
## moves need it, so test fixtures under user:// never start an editor. When this project's
## editor is open it rescans by itself once its window gets focus, and a second editor would
## write the same .godot cache beside it, so no import starts and the returned note says so.
static func refresh_cache(moved: String) -> String:
	if not moved.begins_with("res://") or Engine.is_editor_hint():
		return ""
	if _import_pid > 0 and OS.is_process_running(_import_pid):
		_refresh_pending = true
		return "正在更新文件登记，本次移动会随后更新"
	var finished := _finish_import() if _import_pid > 0 else ""
	var started := _start_import()
	return _notes(finished, started)


static func poll_refresh() -> String:
	if _import_pid <= 0 or OS.is_process_running(_import_pid):
		return ""
	var finished := _finish_import()
	return _notes(finished, _start_import()) if _refresh_pending else finished


static func _finish_import() -> String:
	var code := OS.get_process_exit_code(_import_pid)
	_import_pid = -1
	return "" if code == 0 else "文件登记更新失败，请让 Agent 重新导入项目"


static func _start_import() -> String:
	_refresh_pending = false
	var project := ProjectSettings.globalize_path("res://")
	var output: Array = []
	var code := OS.execute("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command", GODOT_PROCESSES],
		output)
	if code != 0:
		return "没能检查 Godot 编辑器，请让 Agent 查看进程查询是否可用"
	if editor_running("".join(output), project):
		return EDITOR_OPEN
	_import_pid = OS.create_process(OS.get_executable_path(), ["--headless", "--path", project, "--import"])
	return "" if _import_pid > 0 else "没能启动文件登记更新，请让 Agent 重新导入项目"


static func _notes(first: String, second: String) -> String:
	return second if first.is_empty() else first + ("；" + second if not second.is_empty() else "")


## Whether one of `processes` (a command line per line) is a windowed editor of `project`:
## the project manager passes "--path <project> --editor", `godot -e --path` and the editor's
## own restart pass -e, and opening project.godot passes that file. Headless editors (imports,
## scripts) never get focus, and games run from the editor carry --editor-pid, not --editor.
static func editor_running(processes: String, project: String) -> bool:
	var own := _normalized(project)
	for line in processes.split("\n", false):
		var arguments := _arguments(line)
		var editor := false
		var here := false
		for argument in arguments:
			var path := _normalized(argument)
			editor = editor or argument in ["-e", "--editor"] or path == own + "/project.godot"
			here = here or path == own or path == own + "/project.godot"
		if editor and here and not "--headless" in arguments:
			return true
	return false


## Windows paths ignore case and may use either slash.
static func _normalized(path: String) -> String:
	return path.replace("\\", "/").trim_suffix("/").to_lower()


## A command line's arguments; quoted ones keep their spaces.
static func _arguments(line: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var parts := line.strip_edges().split("\"")
	for index in parts.size():
		if index % 2 == 1:
			result.append(parts[index])
		else:
			result.append_array(parts[index].split(" ", false))
	return result


## The UID stays the same; only the running game's UID table learns the new path.
static func remap(destination: String, files: PackedStringArray) -> void:
	for file in files:
		if file.get_extension() in ["import", "uid"]:
			continue
		var path := destination.path_join(file)
		var identity := _file_uid(path)
		if identity == ResourceUID.INVALID_ID:
			continue
		if ResourceUID.has_id(identity):
			ResourceUID.set_id(identity, path)
		else:
			ResourceUID.add_id(identity, path)


static func _file_uid(path: String) -> int:
	if FileAccess.file_exists(path + ".import"):
		var config := ConfigFile.new()
		if config.load(path + ".import") != OK:
			return ResourceUID.INVALID_ID
		return ResourceUID.text_to_id(String(config.get_value("remap", "uid", "")))
	if FileAccess.file_exists(path + ".uid"):
		return ResourceUID.text_to_id(FileAccess.get_file_as_string(path + ".uid").strip_edges())
	if path.get_extension() in ["tscn", "tres"]:
		# The running game only knows UIDs by their old path, so read the file header itself.
		var header := FileAccess.open(path, FileAccess.READ)
		var found := RegEx.create_from_string(HEADER_UID).search(header.get_line()) \
			if header != null else null
		return ResourceUID.text_to_id(found.get_string(1)) if found != null else ResourceUID.INVALID_ID
	return ResourceUID.INVALID_ID


## Every file under `directory`, as full paths.
static func _files(directory: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for file in DirAccess.get_files_at(directory):
		result.append(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		result.append_array(_files(directory.path_join(child)))
	return result
