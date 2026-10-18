extends RefCounted
## The A/B comparison of a debug session: the live resources show a saved combo or the game
## values while the current edits wait in a draft. The session owns this object, so it holds
## the session weakly.

## A switch deferred to the next playback pass reports its result here.
signal reported(result: Dictionary)

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")

## The comparison: "" for the game values, otherwise a saved combo of the active target.
var combo: String = ""
## The comparison's values are loaded into the live resources; edits wait in _draft.
var showing: bool = false
## A switch that takes effect at the start of the next playback pass.
var pending: bool = false
var session: RefCounted:
	get:
		return _owner.get_ref()
var _owner: WeakRef
var _reload: bool = false
var _draft: Dictionary = {}
var _draft_contents: Dictionary = {}
var _key: String = "!"
var _checked: Dictionary = {}
var _contents: Dictionary = {}


func _init(owner: RefCounted) -> void:
	_owner = weakref(owner)


## "游戏原值" when no combo is chosen as the comparison.
func name() -> String:
	return "游戏原值" if combo.is_empty() else "组合 " + combo


## Picks the comparison: "" for the game values or a saved combo. While the comparison is
## shown it reloads now, or at the next pass while playback is locked.
func choose(value: String, locked: bool) -> Dictionary:
	combo = value
	invalidate()
	var loaded := {"error": OK, "text": "对比对象改为" + name()}
	if showing and not pending:
		if locked:
			_reload = true
		else:
			var shown := _load()
			if shown.error != OK or not shown.issues.is_empty():
				loaded = shown
	session.changed.emit()
	return loaded


## Switches between the current edits and the comparison. With nothing to compare it only
## hints; while playback is locked the switch waits for the next pass.
func toggle(deferred: bool) -> Dictionary:
	if not showing and not pending and differences() == 0:
		var checked := _result()
		if checked.error != OK:
			return _unreadable(checked)
		var same := "还没有改动可对比" if combo.is_empty() \
			else "当前设定和%s完全相同" % name()
		return {"error": OK, "issues": checked.issues, "text": same + _fallback_note(checked)}
	pending = not pending
	session.changed.emit()
	if not deferred:
		return _apply()
	if not pending:
		return {"error": OK, "text": "已取消下一遍的切换"}
	return {"error": OK, "text": "下一遍开头切到" + next_side()}


## The side a pending switch shows: the comparison, or the current edits when it is shown.
func next_side() -> String:
	return "当前改动" if showing else name()


func _apply() -> Dictionary:
	if _reload and showing and not pending:
		_reload = false
		return _load()
	if not pending:
		return {"error": OK}
	pending = false
	_reload = false
	if showing:
		leave()
		session.changed.emit()
		return {"error": OK, "text": "正在显示：当前改动"}
	_draft.clear()
	_draft_contents.clear()
	for slot in session.slots:
		_draft[slot.id] = slot.snapshot()
	showing = true
	return _load()


## Puts the current edits back when the comparison is shown and drops any pending switch.
func leave() -> void:
	if showing:
		for slot in session.slots:
			if _draft.has(slot.id):
				slot.restore(_draft[slot.id])
	showing = false
	pending = false
	_reload = false
	_draft.clear()
	_draft_contents.clear()


## Shows the comparison as loading would: unreadable items show the game values and are named;
## when it cannot be read at all, the current edits stay shown.
func _load() -> Dictionary:
	invalidate()
	var checked := _result()
	if checked.error != OK:
		leave()
		session.changed.emit()
		return _unreadable(checked)
	for slot in session.slots:
		Codec.apply_fields(slot.live, checked.values[slot.id])
	session.changed.emit()
	return {"error": OK, "issues": checked.issues, "text": "正在显示：" + name()
		+ "（只读，按 ` 回到当前改动）" + _fallback_note(checked)}


func _unreadable(checked: Dictionary) -> Dictionary:
	return {"error": checked.error, "message": checked.get("message", ""),
		"text": "没能显示%s：有插槽的游戏调参文件读不出来，仍是当前改动。请让 Agent 查看详情" % name()}


## "；其中 2 项读不出来，按游戏原值比较" when items of the comparison fell back.
static func _fallback_note(checked: Dictionary) -> String:
	var issues: PackedStringArray = checked.get("issues", PackedStringArray())
	return "" if issues.is_empty() else "；其中 %d 项读不出来，按游戏原值比较" % issues.size()


func apply_pending() -> void:
	if pending or _reload:
		reported.emit(_apply())


## Fields that differ between the current edits and the comparison; the current edits are
## the saved draft while the comparison is shown.
func differences() -> int:
	_result()
	var count := 0
	for slot in session.slots:
		var current: Variant = slot.current_content()
		if showing and _draft.has(slot.id):
			current = _draft_content(slot.id)
		if _contents.has(slot.id) and current is Dictionary:
			count += Slot.differences(current, _contents[slot.id]).size()
	return count


func _draft_content(identity: String) -> Variant:
	if not _draft_contents.has(identity):
		_draft_contents[identity] = Codec.content(_draft[identity].fields)
	return _draft_contents[identity]


## Unsaved edits of a slot, taken from the draft while the comparison is shown.
func slot_dirty(slot: Slot) -> bool:
	return _draft[slot.id].dirty if showing and _draft.has(slot.id) else slot.is_dirty()


## Call after presets, combos or game files change on disk.
func invalidate() -> void:
	_key = "!"
	_draft_contents.clear()


## Whether the comparison could be read; items that fell back still count as readable.
func readable() -> bool:
	return _result().error == OK


## The comparison checked the way loading a combo checks it (game values for ""), with the
## content of each slot for counting differences; cached until invalidate().
func _result() -> Dictionary:
	if _key == combo:
		return _checked
	_key = combo
	_contents.clear()
	_checked = session.store.check_combo(session.active.id if session.active != null else "", combo, session.slots)
	if _checked.error != OK:
		return _checked
	for slot in session.slots:
		var packed := Codec.pack_values(_checked.values[slot.id])
		if packed.error == OK:
			_contents[slot.id] = Codec.content(packed.value)
	return _checked
