extends RefCounted
## Adopting a candidate that still lives in dev/ moves its files into game/ first.
## Imported assets (audio, images) and their notes move at once: the moved .import still points
## at the same import cache, and ResourceUID.set_id maps the unchanged UID to the new path.
## Scripts, scenes and text resources contain res:// paths and stay cached under their old
## path while the game runs, so they are queued and move at the next debug start instead.

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Request := preload("res://dev/debug/_shared/adoption_request.gd")
const Writer := preload("res://dev/debug/_shared/default_writer.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")
const LOG := "adoption-log.md"
const QUEUE := "adoption-queue"
const DESCRIPTOR := Slot.DESCRIPTOR
const DEFERRED_EXTENSIONS: Array[String] = ["gd", "tscn", "scn", "tres", "res", "gdshader"]
const TEXT_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "gdshader"]
const LOG_HEADER := "# 待 Agent 收尾的采纳\n\n调试台每次采纳到游戏都在这里追加一行；Agent 按[收尾步骤](_shared/README.md#收尾步骤)收尾并提交后，删除已处理的行。\n\n"


## {} when the slot's live candidate is not a dev candidate of this slot; otherwise what moves
## where and whether the move waits for the next start ("deferred").
static func plan(slot: Slot) -> Dictionary:
	var candidate := slot.live.get("candidate") as Resource if "candidate" in slot.live else null
	var prefix := slot.directory + "/"
	if candidate == null or not candidate.resource_path.begins_with(prefix):
		return {}
	var candidate_id := candidate.resource_path.trim_prefix(prefix).get_slice("/", 0)
	var source := slot.directory.path_join(candidate_id)
	var files := _files(source, "")
	if DESCRIPTOR in files:
		files.remove_at(files.find(DESCRIPTOR))
	var deferred := false
	for file in files:
		deferred = deferred or file.get_extension() in DEFERRED_EXTENSIONS
	var definition := ResourceLoader.load(source.path_join(DESCRIPTOR), "",
		ResourceLoader.CACHE_MODE_IGNORE)
	return {"slot": slot, "candidate_id": candidate_id, "source": source, "files": files,
		"name": definition.display_name if definition != null else candidate_id,
		"destination": adopt_directory(slot, candidate_id), "deferred": deferred,
		"candidate_path": candidate.resource_path}


## Where an adopted candidate's files go: res://game/<target>/<ADOPT_DIRECTORY>/<candidate>.
## slot.gd may declare ADOPT_DIRECTORY; the default is the slot path in snake_case.
static func adopt_directory(slot: Slot, candidate_id: String) -> String:
	var tuning := slot.game_path.trim_suffix(slot.slot_path + ".tres").trim_suffix("/")
	var relative := String(slot.constant("ADOPT_DIRECTORY", slot.slot_path.replace("-", "_")))
	return tuning.get_base_dir().path_join(relative).path_join(candidate_id)


## "把 风铃 · chime 移入游戏，并把按钮音效改为它", with the deferred note when queued.
static func summary(adoption: Dictionary) -> String:
	var slot: Slot = adoption.slot
	var text := "把 %s 移入游戏，并把%s改为它" % [adoption.name, slot.display_name()]
	return text + "（游戏将在下次启动时使用）" if adoption.deferred else text


## Adoption plans of the slots that adopt a dev candidate, by slot id.
static func plans_for(slots: Array[Slot]) -> Dictionary:
	var result: Dictionary = {}
	for slot in slots:
		var adoption := plan(slot)
		if not adoption.is_empty():
			result[slot.id] = adoption
	return result


## The confirmation: what happens to each slot, then the game files that change.
static func confirm_text(slots: Array[Slot], plans: Dictionary) -> String:
	var actions: PackedStringArray = []
	var files: PackedStringArray = []
	for slot in slots:
		if plans.has(slot.id):
			var adoption: Dictionary = plans[slot.id]
			actions.append("· " + summary(adoption))
			files.append("· %s %s/（%s）" % ["下次启动时新增" if adoption.deferred else "新增",
				Messages.relative(adoption.destination), "、".join(_shown_files(adoption.files))])
		elif not _switch_name(slot).is_empty():
			actions.append("· 把%s改回 %s" % [slot.display_name(), _switch_name(slot)])
		else:
			actions.append("· 把%s的当前设定写入游戏" % slot.display_name())
		var replaced := _replaced(slot)
		if replaced != null:
			actions.append("· 原来的 %s 留在 %s/，之后仍可在“实现”里选回" % [
				slot.candidate_title(replaced), Messages.relative(replaced.resource_path.get_base_dir())])
		files.append("· 改写 " + Messages.relative(slot.game_path))
	return "采纳到游戏后，游戏以后默认就用这些设定：
%s

将修改的游戏文件：
%s" % [
		"
".join(actions), "
".join(files)]


## Slots that switch back to another implementation in game/: slot id -> its name.
static func _switches(slots: Array[Slot], plans: Dictionary) -> Dictionary:
	var switched: Dictionary = {}
	for slot in slots:
		if not plans.has(slot.id) and not _switch_name(slot).is_empty():
			switched[slot.id] = _switch_name(slot)
	return switched


## The name of another implementation in game/ the slot switches back to, "" when it keeps
## the game's one or adopts a dev candidate.
static func _switch_name(slot: Slot) -> String:
	if _replaced(slot) == null or not plan(slot).is_empty():
		return ""
	return slot.candidate_title(slot.live.get("candidate"))


## The implementation the game uses now when the slot switches to another one, else null.
static func _replaced(slot: Slot) -> Resource:
	if not "candidate" in slot.live:
		return null
	var defaults := slot.disk_defaults()
	var current := defaults.get("candidate") as Resource if defaults != null else null
	var chosen := slot.live.get("candidate") as Resource
	if current == null or chosen == null or chosen.resource_path == current.resource_path:
		return null
	return current


## Files people recognize; .import and .uid move along without being listed.
static func _shown_files(files: PackedStringArray) -> PackedStringArray:
	var shown: PackedStringArray = []
	for file in files:
		if not file.get_extension() in ["import", "uid"]:
			shown.append(file)
	return shown


## Moves immediate candidates, writes every slot, queues deferred moves and logs each slot
## for the Agent. Returns the status text: "已采纳：按钮音效改为 风铃 · chime".
static func adopt_all(slots: Array[Slot], plans: Dictionary) -> Dictionary:
	var switched := _switches(slots, plans)
	var deferred: PackedStringArray = []
	var moved_to := ""
	for identity: String in plans:
		var adoption: Dictionary = plans[identity]
		if adoption.deferred:
			deferred.append(identity)
			continue
		var moved := move(adoption)
		if moved.error != OK:
			return Messages.outcome(moved, "", "没能把 %s 移入游戏" % adoption.name,
				"游戏文件没有改动。请让 Agent 查看详情")
		moved_to = adoption.destination
	# One import covers every move; two at once would write the same .godot cache.
	var note := Uids.refresh_cache(moved_to)
	var written := Writer.write_all(slots, deferred)
	if written.error != OK:
		return Messages.outcome(written, "", "没能写入游戏文件",
			"已写入 %d 个文件，其余没有写入。关掉占用游戏文件的程序后再采纳一次" % written.get(
				"written", []).size())
	for identity in deferred:
		var queued := enqueue(plans[identity])
		if queued.error != OK:
			return Messages.outcome(queued, "", "没能把 %s 排进下次启动的移动" % plans[identity].name,
				"其他设定已写入游戏。请让 Agent 查看详情")
	for slot in slots:
		append_log(slot.debug_root, log_line(slot, plans.get(slot.id, {})))
		if not plans.has(slot.id):
			cancel(slot)
		# The game file now holds these values, so the slot shows "游戏原值" again.
		slot.preset_name = ""
		slot.mark_saved()
	return {"error": OK, "text": "已采纳：" + _adopted_text(slots, plans, switched)
		+ ("。" + note if not note.is_empty() else "")}


## "按钮音效改为 风铃 · chime；点击特效改回 圆环；界面音量的当前设定已写入游戏".
static func _adopted_text(slots: Array[Slot], plans: Dictionary, switched: Dictionary) -> String:
	var parts: PackedStringArray = []
	var plain: PackedStringArray = []
	for slot in slots:
		if switched.has(slot.id):
			parts.append("%s改回 %s" % [slot.display_name(), switched[slot.id]])
			continue
		if not plans.has(slot.id):
			plain.append(slot.display_name())
			continue
		var adoption: Dictionary = plans[slot.id]
		parts.append("%s改为 %s%s" % [slot.display_name(), adoption.name,
			"（游戏将在下次启动时使用）" if adoption.deferred else ""])
	if plain.size() > 3:
		parts.append("其余 %d 个插槽的当前设定已写入游戏" % plain.size())
	elif not plain.is_empty():
		parts.append("%s的当前设定已写入游戏" % "、".join(plain))
	return "；".join(parts)


static func move(adoption: Dictionary) -> Dictionary:
	var moved := _move_files(adoption.source, adoption.destination, adoption.files)
	if moved.error != OK:
		return moved
	Uids.remap(adoption.destination, adoption.files)
	_retire_descriptor(adoption.source)
	var slot: Slot = adoption.slot
	var path := String(adoption.destination) + String(adoption.candidate_path).trim_prefix(adoption.source)
	var fresh := ResourceLoader.load(path)
	if fresh == null:
		return {"error": ERR_CANT_OPEN, "message": path, "text": "没能采纳“%s”：移入游戏后读不出来。请让 Agent 检查 %s" % [
			adoption.name, Messages.relative(adoption.destination)]}
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
static func cancel(slot: Slot) -> void:
	if FileAccess.file_exists(queue_path(slot)):
		DirAccess.remove_absolute(queue_path(slot))


## Runs at the debug start before any game resource is loaded; failed requests stay queued.
static func run_queue(debug_root: String) -> Dictionary:
	var directory := debug_root.path_join(QUEUE)
	var done: PackedStringArray = []
	var failed: PackedStringArray = []
	var details: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return {"error": OK, "done": done}
	for file in DirAccess.get_files_at(directory):
		var path := directory.path_join(file)
		var request := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Request
		var result := {"error": ERR_INVALID_DATA, "message": path} if request == null \
			else _run(request, debug_root)
		if result.error != OK:
			failed.append(request.candidate_name if request != null else file)
			details.append(Messages.detail(result))
			continue
		DirAccess.remove_absolute(path)
		done.append(request.candidate_name)
	DirAccess.remove_absolute(directory)
	var note := Uids.refresh_cache(debug_root) if not done.is_empty() else ""
	if not failed.is_empty():
		return {"error": ERR_CANT_CREATE, "done": done, "detail": "\n".join(details),
			"text": "上次排队采纳的 %s 没能移入游戏：文件移动或写入失败。请让 Agent 查看详情" % "、".join(failed)}
	return {"error": OK, "done": done, "note": note}


static func _run(request: Request, debug_root: String) -> Dictionary:
	var remaining: PackedStringArray = []
	for file in request.files:
		if FileAccess.file_exists(request.source.path_join(file)):
			remaining.append(file)
	var moved := _move_files(request.source, request.destination, remaining)
	if moved.error != OK:
		return moved
	_rewrite_paths(request.source, request.destination, request.files)
	Uids.remap(request.destination, request.files)
	var slot := Slot.new()
	var error := slot.configure(request.target_id, request.slot_path, request.game_path, debug_root)
	if error != OK:
		return {"error": error, "message": request.game_path}
	var checked := slot.apply_values(request.fields)
	if "candidate" in checked.issues:
		return {"error": ERR_INVALID_DATA, "message": "Candidate did not resolve after the move",
			"issues": checked.issues}
	error = Writer.write_resource(slot.live, slot.game_path)
	if error != OK:
		return {"error": error, "message": slot.game_path}
	_retire_descriptor(request.source)
	append_log(debug_root, "%s（%s）· 排队的 %s 已移入 %s，写入 %s" % [request.slot_id,
		slot.display_name(), request.candidate_name, Messages.relative(request.destination),
		Messages.relative(slot.game_path)])
	return {"error": OK}


## One line per adoption, for the Agent's follow-up; the file only lists unfinished work.
static func append_log(debug_root: String, line: String) -> Error:
	var path := debug_root.path_join(LOG)
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if exists:
		file.seek_end()
	else:
		file.store_string(LOG_HEADER)
	file.store_string("- %s · %s\n" % [Time.get_datetime_string_from_system(false, true), line])
	file.close()
	return OK


## The log line for one adopted slot: which candidate moved where and which file was written.
static func log_line(slot: Slot, adoption: Dictionary) -> String:
	var line := "%s（%s）" % [slot.id, slot.display_name()]
	if not adoption.is_empty():
		var verb := "排队移入（下次启动调试入口时执行）" if adoption.deferred else "已移入"
		line += " · 候选 %s %s %s：%s" % [adoption.candidate_id, verb,
			Messages.relative(adoption.destination), "、".join(adoption.files)]
	return line + " · 写入 " + Messages.relative(slot.game_path)


## The descriptor stays as adopted.tres: it no longer lists a candidate but still names it.
static func _retire_descriptor(source: String) -> void:
	DirAccess.rename_absolute(source.path_join(DESCRIPTOR), source.path_join(Slot.ADOPTED))


static func _files(directory: String, prefix: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for file in DirAccess.get_files_at(directory):
		result.append(prefix + file)
	for child in DirAccess.get_directories_at(directory):
		result.append_array(_files(directory.path_join(child), prefix + child + "/"))
	return result


static func _move_files(source: String, destination: String, files: PackedStringArray) -> Dictionary:
	if DirAccess.dir_exists_absolute(destination) and files.size() > 0 \
			and FileAccess.file_exists(destination.path_join(files[0])):
		return {"error": ERR_ALREADY_EXISTS, "message": destination}
	for file in files:
		var target := destination.path_join(file)
		var error := DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		if error == OK:
			error = DirAccess.rename_absolute(source.path_join(file), target)
		if error != OK:
			return {"error": error, "message": source.path_join(file) + " -> " + target}
	return {"error": OK}


## Moved scripts and scenes still name their siblings by the old directory; the editor's own
## move rewrites these the same way.
static func _rewrite_paths(source: String, destination: String, files: PackedStringArray) -> void:
	for file in files:
		if not file.get_extension() in TEXT_EXTENSIONS:
			continue
		var path := destination.path_join(file)
		var text := FileAccess.get_file_as_string(path)
		var updated := text.replace(source + "/", destination + "/")
		if updated != text:
			var output := FileAccess.open(path, FileAccess.WRITE)
			output.store_string(updated)
			output.close()
