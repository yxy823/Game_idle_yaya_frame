extends RefCounted
## Owns selection and preset references; tuning values remain owned by live resources.

signal changed()
signal reported(result: Dictionary)

const Target := preload("res://dev/debug/_shared/debug_target.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Store := preload("res://dev/debug/_shared/preset_store.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")

## Pinned slot ids, a per-machine convenience kept outside the project; tests point it elsewhere.
static var pins_path: String = "user://debug/pinned-slots.json"
## Where targets are discovered: game tuning resources and their debug directories; tests
## point them at the sample game in _shared/tests/fixtures/sample/.
static var game_root: String = "res://game"
static var debug_root: String = "res://dev/debug"

var targets: Array = []
var active: RefCounted
var slots: Array[Slot] = []
var selected: Slot
var store := Store.new()
var combo_name: String = ""
## The comparison: "" for the game values, otherwise a saved combo of the active target.
var compare_combo: String = ""
## The comparison's values are loaded into the live resources; edits wait in _draft.
var comparing: bool = false
## A switch that takes effect at the start of the next playback pass.
var pending_compare: bool = false
var _reload_compare: bool = false
var _draft: Dictionary = {}
var _draft_contents: Dictionary = {}
var _combo_baseline: Dictionary = {}
var _pins: PackedStringArray = []
var _compare_key: String = "!"
var _compare_checked: Dictionary = {}
var _compare_contents: Dictionary = {}


func discover() -> void:
	targets = Target.discover(game_root, debug_root)


func select_target(identity: String) -> Dictionary:
	var target := _target(identity)
	var shared_target := _target("shared")
	if target == null:
		return {"error": ERR_DOES_NOT_EXIST, "message": identity,
			"text": "找不到调试对象 %s：游戏里没有它的调参文件" % identity}
	# The previous target's slots keep their unsaved edits; a shown comparison gives them back.
	_leave_compare()
	var activated: Dictionary = target.activate(debug_root)
	if activated.error != OK:
		return activated
	active = target
	slots.assign(target.slots)
	if shared_target != null and shared_target != target:
		activated = shared_target.activate(debug_root)
		if activated.error != OK:
			return activated
		slots.append_array(shared_target.slots)
	var pins: Variant = JSON.parse_string(FileAccess.get_file_as_string(pins_path)) 		if FileAccess.file_exists(pins_path) else []
	for slot in slots:
		slot.pinned = pins is Array and slot.id in pins
		if not slot.changed.is_connected(_slot_changed):
			slot.changed.connect(_slot_changed)
	_pins = _pinned_ids()
	selected = null
	combo_name = ""
	compare_combo = ""
	_combo_baseline = references()
	invalidate_compare()
	changed.emit()
	return {"error": OK}


## Group title for a category path of the listed slots; the path itself when none is named.
func category_title(path: String) -> String:
	for target: RefCounted in [active, _target("shared")]:
		var title: String = target.category_title(path) if target != null else ""
		if not title.is_empty():
			return title
	return path


func _target(identity: String) -> RefCounted:
	for item: RefCounted in targets:
		if item.id == identity:
			return item
	return null


func select_slot(slot: Slot) -> Dictionary:
	selected = slot
	var result := slot.refresh_candidates()
	changed.emit()
	return result


func references() -> Dictionary:
	var result: Dictionary = {}
	for slot in slots:
		result[slot.id] = slot.preset_name
	return result


func combo_dirty() -> bool:
	if references() != _combo_baseline:
		return true
	for slot in slots:
		if slot_dirty(slot):
			return true
	return false


func load_combo(value: String) -> Dictionary:
	var checked := store.check_combo(active.id, value, slots)
	if checked.error != OK:
		return checked
	store.apply_combo(checked, slots)
	combo_name = value
	_combo_baseline = references()
	changed.emit()
	return checked


func save_combo(value: String) -> Dictionary:
	var result := store.save_combo(active.id, value, slots)
	if result.error == OK:
		combo_name = value
		_combo_baseline = references()
		invalidate_compare()
		changed.emit()
	return result


func forget_combo() -> void:
	combo_name = ""
	_combo_baseline.clear()
	for slot in slots:
		_combo_baseline[slot.id] = ""
	invalidate_compare()
	changed.emit()


func preset_deleted(slot_id: String, preset_name: String) -> void:
	if _combo_baseline.get(slot_id) == preset_name:
		_combo_baseline[slot_id] = ""
	invalidate_compare()
	changed.emit()


## "游戏原值" when no combo is chosen as the comparison.
func compare_name() -> String:
	return "游戏原值" if compare_combo.is_empty() else "组合 " + compare_combo


## Picks the comparison: "" for the game values or a saved combo. While the comparison is
## shown it reloads now, or at the next pass while playback is locked.
func choose_compare(value: String, locked: bool) -> Dictionary:
	compare_combo = value
	invalidate_compare()
	var loaded := {"error": OK, "text": "对比对象改为" + compare_name()}
	if comparing and not pending_compare:
		if locked:
			_reload_compare = true
		else:
			var shown := _load_compare()
			if shown.error != OK or not shown.issues.is_empty():
				loaded = shown
	changed.emit()
	return loaded


## Switches between the current edits and the comparison. With nothing to compare it only
## hints; while playback is locked the switch waits for the next pass.
func toggle_compare(deferred: bool) -> Dictionary:
	if not comparing and not pending_compare and compare_differences() == 0:
		var checked := _compare_result()
		if checked.error != OK:
			return _unreadable(checked)
		var same := "还没有改动可对比" if compare_combo.is_empty() \
			else "当前设定和%s完全相同" % compare_name()
		return {"error": OK, "issues": checked.issues, "text": same + _fallback_note(checked)}
	pending_compare = not pending_compare
	changed.emit()
	if not deferred:
		return _apply_compare()
	if not pending_compare:
		return {"error": OK, "text": "已取消下一遍的切换"}
	return {"error": OK, "text": "下一遍开头切到" + next_side()}


## The side a pending switch shows: the comparison, or the current edits when it is shown.
func next_side() -> String:
	return "当前改动" if comparing else compare_name()


func _apply_compare() -> Dictionary:
	if _reload_compare and comparing and not pending_compare:
		_reload_compare = false
		return _load_compare()
	if not pending_compare:
		return {"error": OK}
	pending_compare = false
	_reload_compare = false
	if comparing:
		_leave_compare()
		changed.emit()
		return {"error": OK, "text": "正在显示：当前改动"}
	_draft.clear()
	_draft_contents.clear()
	for slot in slots:
		_draft[slot.id] = slot.snapshot()
	comparing = true
	return _load_compare()


## Puts the current edits back when the comparison is shown and drops any pending switch.
func _leave_compare() -> void:
	if comparing:
		for slot in slots:
			if _draft.has(slot.id):
				slot.restore(_draft[slot.id])
	comparing = false
	pending_compare = false
	_reload_compare = false
	_draft.clear()
	_draft_contents.clear()


## Slots of every target opened in this session, each once: unsaved edits stay in the live
## resources after switching targets, so closing checks all of them.
func opened_slots() -> Array[Slot]:
	var result: Array[Slot] = []
	for target: RefCounted in targets:
		result.append_array(target.slots)
	for slot in slots:
		if not slot in result:
			result.append(slot)
	return result


## Shows the comparison as loading would: unreadable items show the game values and are named;
## when it cannot be read at all, the current edits stay shown.
func _load_compare() -> Dictionary:
	invalidate_compare()
	var checked := _compare_result()
	if checked.error != OK:
		_leave_compare()
		changed.emit()
		return _unreadable(checked)
	for slot in slots:
		Codec.apply_fields(slot.live, checked.values[slot.id])
	changed.emit()
	return {"error": OK, "issues": checked.issues, "text": "正在显示：" + compare_name()
		+ "（只读，按 ` 回到当前改动）" + _fallback_note(checked)}


func _unreadable(checked: Dictionary) -> Dictionary:
	return {"error": checked.error, "message": checked.get("message", ""),
		"text": "没能显示%s：有插槽的游戏调参文件读不出来，仍是当前改动。请让 Agent 查看详情" % compare_name()}


## "；其中 2 项读不出来，按游戏原值比较" when items of the comparison fell back.
static func _fallback_note(checked: Dictionary) -> String:
	var issues: PackedStringArray = checked.get("issues", PackedStringArray())
	return "" if issues.is_empty() else "；其中 %d 项读不出来，按游戏原值比较" % issues.size()


func apply_pending_compare() -> void:
	if pending_compare or _reload_compare:
		reported.emit(_apply_compare())


## Fields that differ between the current edits and the comparison; the current edits are
## the saved draft while the comparison is shown.
func compare_differences() -> int:
	_compare_result()
	var count := 0
	for slot in slots:
		var current: Variant = slot.current_content()
		if comparing and _draft.has(slot.id):
			current = _draft_content(slot.id)
		if _compare_contents.has(slot.id) and current is Dictionary:
			count += Slot.differences(current, _compare_contents[slot.id]).size()
	return count


func _draft_content(identity: String) -> Variant:
	if not _draft_contents.has(identity):
		_draft_contents[identity] = Codec.content(_draft[identity].fields)
	return _draft_contents[identity]


## Unsaved edits of a slot, taken from the draft while the comparison is shown.
func slot_dirty(slot: Slot) -> bool:
	return _draft[slot.id].dirty if comparing and _draft.has(slot.id) else slot.is_dirty()


func dirty_count() -> int:
	var count := 0
	for slot in slots:
		count += 1 if slot_dirty(slot) else 0
	return count


## Call after presets, combos or game files change on disk.
func invalidate_compare() -> void:
	_compare_key = "!"
	_draft_contents.clear()


## Whether the comparison could be read; items that fell back still count as readable.
func compare_readable() -> bool:
	return _compare_result().error == OK


## The comparison checked the way loading a combo checks it (game values for ""), with the
## content of each slot for counting differences; cached until invalidate_compare().
func _compare_result() -> Dictionary:
	if _compare_key == compare_combo:
		return _compare_checked
	_compare_key = compare_combo
	_compare_contents.clear()
	_compare_checked = store.check_combo(active.id if active != null else "", compare_combo, slots)
	if _compare_checked.error != OK:
		return _compare_checked
	for slot in slots:
		var packed := Codec.pack_values(_compare_checked.values[slot.id])
		if packed.error == OK:
			_compare_contents[slot.id] = Codec.content(packed.value)
	return _compare_checked


func _slot_changed() -> void:
	var pins := _pinned_ids()
	if pins != _pins:
		_pins = pins
		_save_pins()
	changed.emit()


func _pinned_ids() -> PackedStringArray:
	var result: PackedStringArray = []
	for slot in slots:
		if slot.pinned:
			result.append(slot.id)
	return result


## Pins of other targets in the file are kept.
func _save_pins() -> void:
	var stored: Variant = JSON.parse_string(FileAccess.get_file_as_string(pins_path)) 		if FileAccess.file_exists(pins_path) else []
	var pins: PackedStringArray = []
	for identity: Variant in (stored if stored is Array else []):
		if not slots.any(func(slot: Slot) -> bool: return slot.id == identity):
			pins.append(String(identity))
	pins.append_array(_pins)
	DirAccess.make_dir_recursive_absolute(pins_path.get_base_dir())
	var file := FileAccess.open(pins_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(pins))
		file.close()
