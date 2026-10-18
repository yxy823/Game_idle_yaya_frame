extends RefCounted
## Moves an adopted candidate's files into game/: every file or none, with the res:// paths inside
## them rewritten. Moves that must wait for the next debug start are queued here, and each
## adoption leaves a line in the follow-up log for the Agent.

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Request := preload("res://dev/debug/_shared/adoption_request.gd")
const Writer := preload("res://dev/debug/_shared/default_writer.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")
const LOG := "adoption-log.md"
const QUEUE := "adoption-queue"
const DESCRIPTOR := Slot.DESCRIPTOR
const TEXT_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "gdshader"]
const LOG_HEADER := "# 待 Agent 收尾的采纳\n\n调试台每次采纳到游戏都在这里追加一行；Agent 按[收尾步骤](_shared/README.md#收尾步骤)收尾并提交后，删除已处理的行。\n\n"


## Moves one candidate; when it does not load from its new place, its files go back.
static func move(adoption: Dictionary) -> Dictionary:
	var moved := _move_files(adoption.source, adoption.destination, adoption.files)
	if moved.error != OK:
		return moved
	Uids.remap(adoption.destination, adoption.files)
	var slot: Slot = adoption.slot
	var path := String(adoption.destination) + String(adoption.candidate_path).trim_prefix(adoption.source)
	var fresh := ResourceLoader.load(path) if ResourceLoader.exists(path) else null
	if fresh == null:
		var stranded := _move_back(adoption.source, adoption.destination, adoption.files)
		Uids.remap(adoption.source, adoption.files)
		var back := "文件已放回 %s/" % Messages.relative(adoption.source) if stranded.is_empty() \
			else "%s 留在了 %s/" % ["、".join(stranded), Messages.relative(adoption.destination)]
		return {"error": ERR_CANT_OPEN, "message": path, "text": "没能采纳“%s”：移入游戏后读不出来，%s" % [
			adoption.name, back]}
	_retire_descriptor(adoption.source)
	slot.live.set("candidate", fresh)
	return {"error": OK}


static func enqueue(adoption: Dictionary) -> Dictionary:
	var slot: Slot = adoption.slot
	var packed := Codec.pack_fields(slot.live)
	if packed.error != OK:
		return packed
	var request := Request.new()
	request.slot_id = slot.id
	request.target_id = slot.target_id
	request.slot_path = slot.slot_path
	request.game_path = slot.game_path
	request.candidate_name = adoption.name
	request.source = adoption.source
	request.destination = adoption.destination
	request.files = adoption.files
	request.fields = packed.value
	var path := queue_path(slot)
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error == OK:
		error = ResourceSaver.save(request, path)
	return {"error": error, "message": path}


static func queue_path(slot: Slot) -> String:
	return slot.debug_root.path_join(QUEUE).path_join(slot.id.replace("/", "--") + ".tres")


## The candidate directory name waiting in the queue for this slot, "" when none.
static func queued_candidate(slot: Slot) -> String:
	if not FileAccess.file_exists(queue_path(slot)):
		return ""
	var request := ResourceLoader.load(queue_path(slot), "", ResourceLoader.CACHE_MODE_IGNORE) as Request
	return "" if request == null else request.source.get_file()


## A later adoption of another implementation replaces a queued one.
static func cancel(slot: Slot) -> Error:
	if not FileAccess.file_exists(queue_path(slot)):
		return OK
	return DirAccess.remove_absolute(queue_path(slot))


## Runs at the debug start before any game resource is loaded; failed requests stay queued.
static func run_queue(debug_root: String) -> Dictionary:
	var directory := debug_root.path_join(QUEUE)
	var done: PackedStringArray = []
	var failed: PackedStringArray = []
	var details: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return {"error": OK, "done": done}
	var problems: PackedStringArray = []
	for file in DirAccess.get_files_at(directory):
		var path := directory.path_join(file)
		var request := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Request
		var result := {"error": ERR_INVALID_DATA, "message": path} if request == null \
			else _run(request, debug_root)
		if result.error != OK:
			failed.append(request.candidate_name if request != null else file)
			details.append(Messages.detail(result))
			continue
		done.append(request.candidate_name)
		if result.log != OK:
			details.append(result.line)
			problems.append("%s 的待收尾记录没能写进 %s，请让 Agent 按详情补记" % [request.candidate_name, LOG])
		if DirAccess.remove_absolute(path) != OK:
			details.append(path)
			problems.append("%s 的排队记录没能删除，下次启动会再写一次游戏文件：请让 Agent 删除 %s" % [
				request.candidate_name, Messages.relative(path)])
	DirAccess.remove_absolute(directory)
	var note := Uids.refresh_cache(debug_root) if not done.is_empty() else ""
	return _queue_result(done, failed, problems, details, note)


static func _queue_result(done: PackedStringArray, failed: PackedStringArray,
		problems: PackedStringArray, details: PackedStringArray, note: String) -> Dictionary:
	if not failed.is_empty():
		problems.insert(0, "上次排队采纳的 %s 没能移入游戏：文件移动或写入失败，下次启动再试。请让 Agent 查看详情"
			% "、".join(failed))
	if not problems.is_empty():
		if not note.is_empty():
			problems.append(note)
		return {"error": ERR_CANT_CREATE, "done": done, "detail": "\n".join(details),
			"text": "；".join(problems)}
	return {"error": OK, "done": done, "note": note}


static func _run(request: Request, debug_root: String) -> Dictionary:
	var remaining: PackedStringArray = []
	for file in request.files:
		if FileAccess.file_exists(request.source.path_join(file)):
			remaining.append(file)
	var moved := _move_files(request.source, request.destination, remaining)
	if moved.error != OK:
		return moved
	var rewritten := _rewrite_paths(request.source, request.destination, request.files)
	if rewritten.error != OK:
		return rewritten
	Uids.remap(request.destination, request.files)
	var slot := Slot.new()
	var error := slot.configure(request.target_id, request.slot_path, request.game_path, debug_root)
	if error != OK:
		return {"error": error, "message": request.game_path}
	var checked := slot.apply_values(request.fields)
	if checked.error != OK:
		return checked
	if not checked.issues.is_empty():
		return {"error": ERR_INVALID_DATA, "message": "Queued fields no longer match the slot",
			"issues": checked.issues}
	error = Writer.write_resource(slot.live, slot.game_path)
	if error != OK:
		return {"error": error, "message": slot.game_path}
	_retire_descriptor(request.source)
	var line := "%s（%s）· 排队的 %s 已移入 %s，写入 %s" % [request.slot_id,
		slot.display_name(), request.candidate_name, Messages.relative(request.destination),
		Messages.relative(slot.game_path)]
	return {"error": OK, "log": append_log(debug_root, line), "line": line}


## One line per adoption, for the Agent's follow-up; the file only lists unfinished work.
static func append_log(debug_root: String, line: String) -> Error:
	var path := debug_root.path_join(LOG)
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if exists:
		file.seek_end()
	var text := ("" if exists else LOG_HEADER) \
		+ "- %s · %s\n" % [Time.get_datetime_string_from_system(false, true), line]
	var stored := file.store_string(text)
	file.close()
	return OK if stored else ERR_FILE_CANT_WRITE


## The descriptor stays as adopted.tres: it no longer lists a candidate but still names it.
static func _retire_descriptor(source: String) -> void:
	DirAccess.rename_absolute(source.path_join(DESCRIPTOR), source.path_join(Slot.ADOPTED))


## Moves every file or none: all targets must be free first, and when one move fails the
## files already moved go back. "stranded" names those that could not go back.
static func _move_files(source: String, destination: String, files: PackedStringArray) -> Dictionary:
	for file in files:
		if FileAccess.file_exists(destination.path_join(file)):
			return {"error": ERR_ALREADY_EXISTS, "message": destination.path_join(file)}
	var moved: PackedStringArray = []
	for file in files:
		var target := destination.path_join(file)
		var error := DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		if error == OK:
			error = DirAccess.rename_absolute(source.path_join(file), target)
		if error != OK:
			return {"error": error, "message": source.path_join(file) + " -> " + target,
				"stranded": _move_back(source, destination, moved)}
		moved.append(file)
	return {"error": OK}


## Puts moved files back and removes the then empty destination; returns those still moved.
static func _move_back(source: String, destination: String, moved: PackedStringArray) -> PackedStringArray:
	var stranded: PackedStringArray = []
	for file in moved:
		if DirAccess.rename_absolute(destination.path_join(file), source.path_join(file)) != OK:
			stranded.append(file)
	DirAccess.remove_absolute(destination)
	return stranded


## Moved scripts and scenes still name their siblings by the old directory; the editor's own
## move rewrites these the same way. Stops at the first file it cannot read or write.
static func _rewrite_paths(source: String, destination: String, files: PackedStringArray) -> Dictionary:
	for file in files:
		if not file.get_extension() in TEXT_EXTENSIONS:
			continue
		var path := destination.path_join(file)
		var input := FileAccess.open(path, FileAccess.READ)
		if input == null:
			return {"error": FileAccess.get_open_error(), "message": "Cannot read " + path}
		var text := input.get_as_text()
		var read_error := input.get_error()
		input.close()
		if read_error != OK and read_error != ERR_FILE_EOF:
			return {"error": read_error, "message": "Cannot read " + path}
		var updated := text.replace(source + "/", destination + "/")
		if updated == text:
			continue
		var result := _replace_text(path, updated)
		if result.error != OK:
			return result
	return {"error": OK}


static func _replace_text(path: String, updated: String) -> Dictionary:
	if FileAccess.get_read_only_attribute(path):
		return {"error": ERR_FILE_CANT_WRITE, "message": "Cannot write " + path}
	var suffix := Crypto.new().generate_random_bytes(16).hex_encode()
	var temporary := path + ".rewrite-" + suffix + ".tmp"
	var backup := path + ".rewrite-" + suffix + ".bak"
	var error := _stage_rewrite(temporary, updated)
	if error != OK:
		return _rewrite_failure(error, path, temporary)
	error = DirAccess.rename_absolute(path, backup)
	if error != OK:
		return _rewrite_failure(error, path, temporary)
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		var restored := DirAccess.rename_absolute(backup, path)
		var detail := "" if restored == OK else "Cannot restore %s (%s); original kept at %s" % [
			path, error_string(restored), backup]
		return _rewrite_failure(error, path, temporary, detail)
	error = DirAccess.remove_absolute(backup)
	return {"error": error, "message": "" if error == OK else "Cannot remove backup " + backup}


static func _stage_rewrite(path: String, updated: String) -> Error:
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		return FileAccess.get_open_error()
	var stored := output.store_string(updated)
	output.flush()
	var error := output.get_error()
	output.close()
	return error if error != OK else (OK if stored else ERR_FILE_CANT_WRITE)


static func _rewrite_failure(error: Error, path: String, temporary: String,
		detail: String = "") -> Dictionary:
	if FileAccess.file_exists(temporary):
		var removed := DirAccess.remove_absolute(temporary)
		if removed != OK:
			detail += "\nCannot remove %s (%s)" % [temporary, error_string(removed)]
	return {"error": error, "message": "Cannot write " + path, "detail": detail}
