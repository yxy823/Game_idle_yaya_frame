extends RefCounted
## Adopting a candidate that still lives in dev/ moves its files into game/ first.
## Imported assets (audio, images) and their notes move at once: the moved .import still points
## at the same import cache, and ResourceUID.set_id maps the unchanged UID to the new path.
## Scripts, scenes and text resources contain res:// paths and stay cached under their old
## path while the game runs, so they are queued and move at the next debug start instead.
## This file plans the adoption, builds the confirmation and status texts and writes the game
## files; adoption_files.gd moves, queues and logs.

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Files := preload("res://dev/debug/_shared/adoption_files.gd")
const Writer := preload("res://dev/debug/_shared/default_writer.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")
const Parameters := preload("res://dev/debug/_shared/adoption_parameters.gd")
const DESCRIPTOR := Slot.DESCRIPTOR
const DEFERRED_EXTENSIONS: Array[String] = ["gd", "tscn", "scn", "tres", "res", "gdshader"]
## Shown after each rule slot: a chosen rule goes into the GDD before it is adopted.
const LOGIC_REMINDER := "· 这是规则变化：采纳前先让 Agent 把规则写进 GDD"


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
		actions.append_array(Parameters.changes(slot))
		if slot.constant("LOGIC", false):
			actions.append(LOGIC_REMINDER)
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
	var moves := _move_immediate(plans)
	if moves.error != OK:
		return moves
	var deferred: PackedStringArray = moves.deferred
	# One import covers all moves; a running import gets one follow-up.
	var note := Uids.refresh_cache(moves.destination)
	var written := Writer.write_all(slots, deferred)
	var failure := written
	var failed_action := "没能写入游戏文件"
	var queued: PackedStringArray = []
	if written.error == OK:
		for identity in deferred:
			var result := Files.enqueue(plans[identity])
			if result.error != OK:
				failure = result
				failed_action = "没能把 %s 排进下次启动的移动" % plans[identity].name
				break
			queued.append(identity)
	var paths: PackedStringArray = written.get("written", PackedStringArray())
	var recorded := _record_written(slots, paths, plans, deferred, queued)
	var problems: PackedStringArray = recorded.problems
	var unlogged: PackedStringArray = recorded.unlogged
	var recording_failed := not problems.is_empty()
	if not note.is_empty():
		problems.append(note)
	if failure.error != OK:
		return _write_failure(failure, failed_action, paths, problems, unlogged)
	var text := "已采纳：" + _adopted_text(slots, plans, switched)
	if not recording_failed:
		return {"error": OK, "text": text + ("。" + note if not note.is_empty() else "")}
	return {"error": ERR_FILE_CANT_WRITE, "text": text + "。但" + "；".join(problems),
		"detail": "\n".join(unlogged)}


static func _move_immediate(plans: Dictionary) -> Dictionary:
	var deferred: PackedStringArray = []
	var moved_names: PackedStringArray = []
	var moved_to := ""
	for identity: String in plans:
		var adoption: Dictionary = plans[identity]
		if adoption.deferred:
			deferred.append(identity)
			continue
		var moved := Files.move(adoption)
		if moved.error != OK:
			var failed := _move_failed(moved, adoption, moved_names)
			var move_note := Uids.refresh_cache(moved_to)
			failed.text += "。" + move_note if not move_note.is_empty() else ""
			return failed
		moved_names.append(adoption.name)
		moved_to = adoption.destination
	return {"error": OK, "deferred": deferred, "destination": moved_to}


static func _write_failure(failure: Dictionary, failed_action: String, paths: PackedStringArray,
		problems: PackedStringArray, unlogged: PackedStringArray) -> Dictionary:
	var names: PackedStringArray = []
	for path in paths:
		names.append(path.get_file())
	var progress := "没有写入游戏文件" if paths.is_empty() else "已写入：" + "、".join(names)
	var result := Messages.outcome(failure, "", failed_action,
		progress + "。本次采纳没有全部完成，请让 Agent 查看详情后重试")
	result.text += "。" + "；".join(problems) if not problems.is_empty() else ""
	result.detail += "\n" + "\n".join(paths) + "\n" + "\n".join(unlogged)
	result.written = paths
	return result


static func _record_written(slots: Array[Slot], paths: PackedStringArray, plans: Dictionary,
		deferred: PackedStringArray, queued: PackedStringArray) -> Dictionary:
	var problems: PackedStringArray = []
	var unlogged: PackedStringArray = []
	for slot in slots:
		if not slot.game_path in paths:
			continue
		var adoption: Dictionary = plans.get(slot.id, {})
		var unqueued := slot.id in deferred and not slot.id in queued
		var line := _written_line(slot, adoption, slot.id in deferred, unqueued)
		if Files.append_log(slot.debug_root, line) != OK:
			unlogged.append(line)
		if not slot.id in deferred and Files.cancel(slot) != OK:
			problems.append("排队的 %s 没能撤回，下次启动仍会把它移入游戏并改写%s：关掉占用 %s 的程序后再采纳一次"
				% [Files.queued_candidate(slot), slot.display_name(), Messages.relative(Files.queue_path(slot))])
		# The game file now holds these values, so the slot shows "游戏原值" again.
		if not unqueued:
			slot.preset_name = ""
			slot.mark_saved()
	if not unlogged.is_empty():
		problems.append("待收尾记录没能写进 %s：请让 Agent 按详情补记" % Files.LOG)
	return {"problems": problems, "unlogged": unlogged}


static func _written_line(slot: Slot, adoption: Dictionary, deferred: bool, unqueued: bool) -> String:
	var line := log_line(slot, {} if unqueued else adoption)
	if deferred:
		line += " · 本次仅写入通用参数"
	if unqueued:
		line += "，候选 %s 未排队" % adoption.candidate_id
	return line


## The move of one candidate failed: says which files stayed where and which candidates of
## this adoption already moved; the game's tuning files are not written yet.
static func _move_failed(moved: Dictionary, adoption: Dictionary,
		moved_names: PackedStringArray) -> Dictionary:
	var stranded: PackedStringArray = moved.get("stranded", PackedStringArray())
	var parts: PackedStringArray = [String(moved.text) if moved.has("text") else "没能把 %s 移入游戏：%s" % [
		adoption.name, Messages.reason(moved.error)]]
	if not stranded.is_empty():
		parts.append("%s 已移到 %s/，没能放回" % ["、".join(stranded),
			Messages.relative(adoption.destination)])
	elif not moved.has("text"):
		parts.append("它的文件都还在原处")
	if not moved_names.is_empty():
		parts.append("这次采纳中 %s 已移入游戏" % "、".join(moved_names))
	var retry: bool = stranded.is_empty() and not moved.has("text") and moved.error != ERR_ALREADY_EXISTS
	var fix := "关掉占用这些文件的程序后再采纳一次" if retry else "请让 Agent 查看详情"
	return {"error": moved.error, "message": moved.get("message", ""),
		"text": "；".join(parts) + "。游戏的调参文件没有写入。" + fix}


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


## The log line for one adopted slot: which candidate moved where and which file was written.
static func log_line(slot: Slot, adoption: Dictionary) -> String:
	var line := "%s（%s）" % [slot.id, slot.display_name()]
	if not adoption.is_empty():
		var verb := "排队移入（下次启动调试入口时执行）" if adoption.deferred else "已移入"
		line += " · 候选 %s %s %s：%s" % [adoption.candidate_id, verb,
			Messages.relative(adoption.destination), "、".join(adoption.files)]
	return line + " · 写入 " + Messages.relative(slot.game_path)


static func _files(directory: String, prefix: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for file in DirAccess.get_files_at(directory):
		result.append(prefix + file)
	for child in DirAccess.get_directories_at(directory):
		result.append_array(_files(directory.path_join(child), prefix + child + "/"))
	return result


