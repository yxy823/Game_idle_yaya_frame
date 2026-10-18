extends RefCounted
## Owns selection and preset references; tuning values remain owned by live resources.

signal changed()

const Target := preload("res://dev/debug/_shared/debug_target.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Store := preload("res://dev/debug/_shared/preset_store.gd")
const Compare := preload("res://dev/debug/_shared/session_compare.gd")

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
var compare := Compare.new(self)
var _combo_baseline: Dictionary = {}
var _pins: PackedStringArray = []


func discover() -> void:
	targets = Target.discover(game_root, debug_root)


func select_target(identity: String) -> Dictionary:
	var target := _target(identity)
	var shared_target := _target("shared")
	if target == null:
		return {"error": ERR_DOES_NOT_EXIST, "message": identity,
			"text": "找不到调试对象 %s：游戏里没有它的调参文件" % identity}
	# The previous target's slots keep their unsaved edits; a shown comparison gives them back.
	compare.leave()
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
	compare.combo = ""
	_combo_baseline = references()
	compare.invalidate()
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
		compare.invalidate()
		changed.emit()
	return result


func forget_combo() -> void:
	combo_name = ""
	_combo_baseline.clear()
	for slot in slots:
		_combo_baseline[slot.id] = ""
	compare.invalidate()
	changed.emit()


func preset_deleted(slot_id: String, preset_name: String) -> void:
	if _combo_baseline.get(slot_id) == preset_name:
		_combo_baseline[slot_id] = ""
	compare.invalidate()
	changed.emit()


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


## Unsaved edits of a slot, taken from the draft while the comparison is shown.
func slot_dirty(slot: Slot) -> bool:
	return compare.slot_dirty(slot)


func dirty_count() -> int:
	var count := 0
	for slot in slots:
		count += 1 if slot_dirty(slot) else 0
	return count


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
