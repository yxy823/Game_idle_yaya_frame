# gdlint:ignore-file:file-length=407
# 保留原因：预设与组合的载入、保存、删除及确认对话放在一处读；可移出的载入问题措辞会让通用消息模块依赖插槽。用户同意于 2026-10-08。
extends RefCounted
## The debug window's combo and slot-preset commands: load, save and delete, each reported in
## plain words. Saving only writes dev/ drafts; the game files stay as they are. Loading over
## unsaved edits, saving a combo over unsaved slots and overwriting a preset used by combos
## all ask first, and so does a typed name that already exists. Saving several slots at once
## never overwrites a preset another combo uses: it saves a new preset beside it and says so.

const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Store := preload("res://dev/debug/_shared/preset_store.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Dialogs := preload("res://dev/debug/_shared/debug_dialogs.gd")
const BAD_NAME := "名称不能为空，也不能含 / \\ : * ? \" < > | # 或首尾空格。换一个名称再保存"
## A parameter the preset lacks or has under an old name; names stay in 详情.
const FIELDS_DIFFER := "%s 有 %d 项参数和预设对不上（预设里缺少，或是已改名的旧参数），" 	+ "这些参数用游戏原值"
const BUSY := "文件可能正被其他程序占用，稍后再试"
const LOAD_QUESTION := "有 %d 个插槽的改动还没保存（%s），载入%s后会丢失。\n\n" \
	+ "“保存”把改动存成预设（还没有预设的插槽存成“载入前-日期时间”），游戏文件不变。"
const CLOSE_QUESTION := "有 %d 个插槽的改动还没保存，关闭后会丢失。\n\n" \
	+ "“保存”把改动存成预设（还没有预设的插槽存成“关闭前-日期时间”），游戏文件不变。"
const COMBO_QUESTION := "组合只记录每个插槽用哪个预设，有未保存改动的插槽要先存成预设。" \
	+ "“一并保存”会：\n%s\n\n然后保存组合“%s”。游戏文件不变。"

var _session: Session
var _dialogs: Dialogs
var _report: Callable
var _rebind: Callable


## `report` shows a result; `rebind` rebuilds the inspector after values changed.
func _init(session: Session, dialogs: Dialogs, report: Callable, rebind: Callable) -> void:
	_session = session
	_dialogs = dialogs
	_report = report
	_rebind = rebind


func load_combo(value: String) -> void:
	var shown := "组合 " + value if not value.is_empty() else "游戏原值"
	_ask_before_loading(_session.slots, _quoted("组合", value), func(saved: PackedStringArray) -> void:
		_report_load(_session.load_combo(value), shown, saved,
			"组合文件可能已被删除，重新选择一个组合"))


func load_preset(slot: Slot, preset: String) -> void:
	var shown := "预设 " + preset if not preset.is_empty() else "游戏原值"
	_ask_before_loading([slot], _quoted("预设", preset), func(saved: PackedStringArray) -> void:
		_report_load(_session.store.load_slot(slot, preset), shown, saved,
			"预设文件可能已被删除，重新选择一个预设"))


## Unsaved edits of `slots` would be replaced: save them, drop them, or keep everything.
## `shown` names what is loaded; `apply` receives what was saved first, for the status text.
func _ask_before_loading(slots: Array[Slot], shown: String, apply: Callable) -> void:
	var dirty := _dirty(slots)
	if dirty.is_empty():
		apply.call(PackedStringArray())
		return
	_dialogs.ask(LOAD_QUESTION % [dirty.size(), _names(dirty), shown], [
		["保存", Dialogs.PRIMARY, func() -> void:
			var saved := save_dirty(dirty, "载入前", _session.combo_name)
			if saved.ok:
				apply.call(saved.notes)],
		["不保存载入", Dialogs.DANGER, apply.bind(PackedStringArray())]])
	_rebind.call()


## "已把 点击特效 的改动存进预设 火花；已载入组合 明亮；点击特效用的实现…，这一项改用游戏原值".
func _report_load(result: Dictionary, shown: String, saved: PackedStringArray, fix: String) -> void:
	var parts := saved.duplicate()
	if result.get("error", OK) != OK:
		parts.append(Messages.outcome(result, "", "没能载入" + shown, fix).text)
		_report.call({"error": result.error, "text": "；".join(parts),
			"detail": Messages.detail(result)})
	else:
		parts.append("已载入" + shown)
		parts.append_array(_issue_texts(result.get("issues", PackedStringArray())))
		_report.call({"error": OK, "text": "；".join(parts), "detail": Messages.detail(result)
			if not result.get("issues", PackedStringArray()).is_empty() else ""})
	_rebind.call()


## Each slot is saved into its loaded preset, or "<prefix>-<date time>" when it has none. A
## preset that a combo other than `own_combo` uses is never overwritten: the edits go to a new
## preset beside it. Returns {"ok", "notes"}; the first failure is reported and stops.
func save_dirty(slots: Array[Slot], prefix: String, own_combo: String = "") -> Dictionary:
	var stamp := Time.get_datetime_string_from_system().replace("-", "").replace(":", "")
	var fresh := prefix + "-" + stamp.replace("T", "-")
	var named := func(_unnamed: Slot) -> String: return fresh
	return _save_plan(_plan(slots, named, own_combo,
		own_combo if not own_combo.is_empty() else prefix))


## Where each slot's edits go: its loaded preset, or `new_name(slot)` when it has none. A preset
## that a combo other than `own_combo` uses keeps its values; the edits go to a free
## "<preset>-<suffix>" beside it. {"error", "entries"}: {"slot", "kept", "users", "preset"}.
func _plan(slots: Array[Slot], new_name: Callable, own_combo: String,
		suffix: String) -> Dictionary:
	var plan: Array[Dictionary] = []
	for slot in slots:
		var kept: String = slot.preset_name if not slot.preset_name.is_empty() \
			else new_name.call(slot)
		var users := _other_combos(slot.id, kept, own_combo)
		if users.error != OK:
			return users
		plan.append({"slot": slot, "kept": kept, "users": users.names, "preset": kept
			if users.names.is_empty() else _free_name(slot.id, kept + "-" + suffix)})
	return {"error": OK, "entries": plan}


func _save_plan(plan: Dictionary) -> Dictionary:
	var notes: PackedStringArray = []
	if plan.error != OK:
		_report_unchecked(plan)
		return {"ok": false, "notes": notes}
	for entry: Dictionary in plan.entries:
		var slot: Slot = entry.slot
		var result := _session.store.save_slot(slot, entry.preset)
		if result.error != OK:
			_report.call(Messages.outcome(result, "", "没能保存%s的预设" % slot.display_name(), BUSY))
			return {"ok": false, "notes": notes}
		if entry.users.is_empty():
			notes.append("已把 %s 的改动存进预设 %s" % [slot.display_name(), entry.preset])
		else:
			notes.append("预设 %s 被组合 %s 使用，已把 %s 的改动另存为 %s" % [entry.kept,
				"、".join(entry.users), slot.display_name(), entry.preset])
	_session.invalidate_compare()
	return {"ok": true, "notes": notes}


## One line of the "一并保存" question: where this slot's edits go.
static func _plan_line(entry: Dictionary) -> String:
	var slot: Slot = entry.slot
	if not entry.users.is_empty():
		return "· %s：预设“%s”被组合%s使用，改存为新预设“%s”" % [slot.display_name(),
			entry.kept, _quoted_list(entry.users), entry.preset]
	if slot.preset_name.is_empty():
		return "· %s：新建预设“%s”" % [slot.display_name(), entry.preset]
	return "· %s：存进预设“%s”" % [slot.display_name(), entry.preset]


## Combos other than `own_combo` of the active target that use the preset: {"error", "names"}.
func _other_combos(slot_id: String, preset: String, own_combo: String) -> Dictionary:
	var names: PackedStringArray = []
	var own := _session.store.combo_path(_session.active.id, own_combo)
	var used := _session.store.references(slot_id, preset)
	for path: String in used.get("paths", []):
		if path != own:
			names.append(path.get_file().get_basename())
	used.names = names
	return used


## A combo file that cannot be read stops saving or deleting before anything changes.
func _report_unchecked(result: Dictionary) -> void:
	_report.call(Messages.outcome(result, "", "没能检查哪些组合用到这个预设",
		"有组合文件读不出来，预设和当前改动都没有变。请让 Agent 检查"))


func _free_name(slot_id: String, base: String) -> String:
	return _free(base, func(value: String) -> String:
		return _session.store.preset_path(slot_id, value))


func _free_combo_name(base: String) -> String:
	return _free(base, func(value: String) -> String:
		return _session.store.combo_path(_session.active.id, value))


## `base`, or "<base>-2", "<base>-3"… when a file of that name exists; empty stays empty.
static func _free(base: String, path_of: Callable) -> String:
	if base.is_empty():
		return base
	var free := base
	var number := 2
	while FileAccess.file_exists(path_of.call(free)):
		free = "%s-%d" % [base, number]
		number += 1
	return free


## Load issues in plain words, one sentence per slot and kind; parameters are only counted,
## their names stay in 详情.
func _issue_texts(issues: PackedStringArray) -> PackedStringArray:
	var texts: PackedStringArray = []
	var fields: Dictionary[Slot, int] = {}
	for issue in issues:
		# Combo issues read "<slot id>: <item>"; a slot's own issues are just the item.
		var slot_id := issue.get_slice(": ", 0) if "/" in issue.get_slice(": ", 0) else ""
		var slot := _slot(slot_id) if not slot_id.is_empty() else _session.selected
		var text := _issue_text(slot, issue.trim_prefix(slot_id + ": "))
		if text.is_empty():
			fields[slot] = fields.get(slot, 0) + 1
		elif not text in texts:
			texts.append(text)
	for slot: Slot in fields:
		texts.append(FIELDS_DIFFER % [slot.display_name(), fields[slot]])
	return texts


func _issue_text(slot: Slot, what: String) -> String:
	var shown := slot.display_name() if slot != null else "一个已不存在的插槽"
	if what.begins_with("candidate"):
		return "%s用的实现已不在游戏和候选目录里，这一项改用游戏原值" % shown
	if what.begins_with("Missing preset") or what.begins_with("Invalid slot preset"):
		return "%s用的预设已被删除或读不出来，改用游戏原值" % shown
	if what == "Invalid combo item" or what == "Unknown slot" or slot == null:
		return "组合里关于%s的记录读不出来，这一项改用游戏原值" % shown
	return ""


func _slot(identity: String) -> Slot:
	for slot in _session.slots:
		if slot.id == identity:
			return slot
	return null


## "保存组合" overwrites the current combo; without one, and for "另存组合", it asks a name
## first. A combo only records which preset each slot uses, so unsaved slots are saved with it,
## after one confirmation that lists the preset each slot goes to.
func save_combo(action: String) -> void:
	if action == "保存组合" and not _session.combo_name.is_empty():
		_confirm_combo(_session.combo_name)
	else:
		_name_combo(_session.combo_name)


func _name_combo(base: String) -> void:
	_dialogs.ask_name(_free_combo_name(base), _combo_named, "保存组合")


## A typed name that already exists is an overwrite: ask before replacing that combo.
func _combo_named(value: String) -> void:
	if not Store.valid_name(value) \
			or not FileAccess.file_exists(_session.store.combo_path(_session.active.id, value)):
		_confirm_combo(value)
		return
	_dialogs.ask("组合“%s”已存在，保存会覆盖它。" % value, [
		["覆盖", Dialogs.DANGER, _confirm_combo.bind(value)],
		["换个名字", Dialogs.PLAIN, _name_combo.bind(value)]])


## Unsaved slots without a preset get one named after the combo.
func _confirm_combo(value: String) -> void:
	if not Store.valid_name(value):
		_report.call({"error": ERR_INVALID_PARAMETER, "text": "没能保存组合：" + BAD_NAME})
		return
	var named := func(slot: Slot) -> String: return _free_name(slot.id, value)
	var plan := _plan(_dirty(_session.slots), named, value, value)
	if plan.error != OK:
		_report_unchecked(plan)
		return
	if plan.entries.is_empty():
		_save_combo(value, plan)
		return
	var lines: PackedStringArray = []
	for entry: Dictionary in plan.entries:
		lines.append(_plan_line(entry))
	_dialogs.confirm(COMBO_QUESTION % ["\n".join(lines), value], _save_combo.bind(value, plan),
		"一并保存", "保存组合")


func _save_combo(value: String, plan: Dictionary) -> void:
	var saved := _save_plan(plan)
	if not saved.ok:
		return
	var outcome := Messages.outcome(_session.save_combo(value),
		"已保存组合 " + value + "，游戏文件不变", "没能保存组合 " + value, BUSY)
	var parts: PackedStringArray = [outcome.text]
	for note: String in saved.notes:
		if note.begins_with("预设 "):
			parts.append(note)
	_report.call({"error": outcome.error, "text": "；".join(parts), "detail": outcome.detail})
	_rebind.call()


func confirm_delete_combo() -> void:
	_dialogs.confirm("删除组合“%s”？各插槽的预设不会被删除。" % _session.combo_name,
		_delete_combo, "删除", "请确认", Dialogs.DANGER)


func _delete_combo() -> void:
	var deleted := _session.combo_name
	var error := _session.store.delete_combo(_session.active.id, deleted)
	_report.call(Messages.outcome({"error": error}, "已删除组合 " + deleted,
		"没能删除组合 " + deleted, BUSY))
	if error != OK:
		return
	_session.forget_combo()
	if _session.compare_combo == deleted:
		_session.choose_compare("", false)
	_rebind.call()


func revert(slot: Slot) -> void:
	_report.call(Messages.outcome(_session.store.load_slot(slot, slot.preset_name),
		"已撤销%s的改动" % slot.display_name(), "没能撤销改动", "请让 Agent 检查这个插槽"))


## "保存" overwrites the loaded preset after checking which combos use it; without one, and
## for "另存", it asks a name.
func save_preset(slot: Slot, action: String) -> void:
	if action != "保存" or slot.preset_name.is_empty():
		_ask_preset_name(slot)
		return
	var used := _session.store.references(slot.id, slot.preset_name)
	if used.error != OK:
		_report_unchecked(used)
		return
	var combos: PackedStringArray = used.paths
	if combos.is_empty():
		_save_preset(slot.preset_name, slot)
		return
	var names: PackedStringArray = []
	for path in combos:
		names.append(path.get_file().get_basename())
	_dialogs.ask("预设“%s”被 %d 个组合使用（%s），覆盖后它们也会变。" % [slot.preset_name,
		combos.size(), _quoted_list(names)], [
		["另存为新预设", Dialogs.PRIMARY, _ask_preset_name.bind(slot)],
		["覆盖", Dialogs.DANGER, _save_preset.bind(slot.preset_name, slot)]])


func _ask_preset_name(slot: Slot, base: String = "") -> void:
	_dialogs.ask_name(_free_name(slot.id, base if not base.is_empty() else slot.preset_name),
		_preset_named.bind(slot), "保存 %s 的预设" % slot.display_name())


## A typed name that already exists is an overwrite: ask first and name the combos using it.
func _preset_named(value: String, slot: Slot) -> void:
	if not Store.valid_name(value) or not FileAccess.file_exists(_session.store.preset_path(slot.id,
			value)):
		_save_preset(value, slot)
		return
	var used := _session.store.references(slot.id, value)
	if used.error != OK:
		_report_unchecked(used)
		return
	var names: PackedStringArray = []
	for path: String in used.paths:
		names.append(path.get_file().get_basename())
	var uses := "" if names.is_empty() \
		else "它被 %d 个组合使用（%s），覆盖后它们也会变。" % [names.size(), _quoted_list(names)]
	_dialogs.ask("预设“%s”已存在，保存会覆盖它。%s" % [value, uses], [
		["覆盖", Dialogs.DANGER, _save_preset.bind(value, slot)],
		["换个名字", Dialogs.PLAIN, _ask_preset_name.bind(slot, value)]])


func _save_preset(value: String, slot: Slot) -> void:
	if not Store.valid_name(value):
		_report.call({"error": ERR_INVALID_PARAMETER, "text": "没能保存预设：" + BAD_NAME})
		return
	_report.call(Messages.outcome(_session.store.save_slot(slot, value),
		"已保存预设 " + value + "，游戏文件不变", "没能保存预设 " + value, BUSY))
	_session.invalidate_compare()
	_rebind.call()


## Lists the combos that use the preset before deleting it.
func confirm_delete_preset(slot: Slot) -> void:
	if slot.preset_name.is_empty():
		return
	var result := _session.store.references(slot.id, slot.preset_name)
	if result.error != OK:
		_report_unchecked(result)
		return
	var names: PackedStringArray = []
	for path: String in result.paths:
		names.append(path.get_file().get_basename())
	var uses := "没有组合用到它。" if names.is_empty() \
		else "用到它的组合会改用游戏原值：%s。" % _quoted_list(names)
	_dialogs.confirm("删除预设“%s”？%s" % [slot.preset_name, uses], _delete_preset.bind(slot),
		"删除", "请确认", Dialogs.DANGER)


func _delete_preset(slot: Slot) -> void:
	var deleted := slot.preset_name
	var result := _session.store.delete_slot(slot.id, deleted)
	var kept: PackedStringArray = []
	for path: String in result.get("unrestored", []):
		kept.append(path.get_file().get_basename())
	_report.call(Messages.outcome(result, "已删除预设 " + deleted, "没能删除预设 " + deleted,
		"预设和用到它的组合都没有变。" + BUSY if kept.is_empty()
			else "组合%s已改用游戏原值，没能改回。请让 Agent 查看详情" % _quoted_list(kept)))
	if result.error != OK:
		return
	_session.store.load_slot(slot, "")
	_session.preset_deleted(slot.id, deleted)
	_rebind.call()


## Runs `quit` at once when no opened target has unsaved edits; else asks: save, quit or cancel.
func ask_before_closing(quit: Callable) -> void:
	var dirty := _dirty(_session.opened_slots())
	if dirty.is_empty():
		quit.call()
		return
	_dialogs.ask(CLOSE_QUESTION % dirty.size(), [
		["保存", Dialogs.PRIMARY, func() -> void:
			if _session.comparing:
				_session.toggle_compare(false)
			if save_dirty(dirty, "关闭前", _session.combo_name).ok:
				quit.call()],
		["不保存直接关闭", Dialogs.DANGER, quit]])


func _dirty(slots: Array[Slot]) -> Array[Slot]:
	var result: Array[Slot] = []
	for slot in slots:
		if _session.slot_dirty(slot):
			result.append(slot)
	return result


## Names in confirmations sit in “…”, so a long name moves to the next line as a whole.
static func _quoted(kind: String, value: String) -> String:
	return "%s“%s”" % [kind, value] if not value.is_empty() else "游戏原值"


static func _quoted_list(names: PackedStringArray) -> String:
	var quoted: PackedStringArray = []
	for value in names:
		quoted.append("“%s”" % value)
	return "、".join(quoted)


static func _names(slots: Array[Slot]) -> String:
	var names: PackedStringArray = []
	for slot in slots:
		names.append(slot.display_name())
	return _quoted_list(names)
