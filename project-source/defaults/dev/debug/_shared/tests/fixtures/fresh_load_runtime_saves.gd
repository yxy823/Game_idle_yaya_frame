extends SceneTree
## Run before fresh_load.gd without an editor scan; --invalid adds an ordinary UID-less file.
## Use only a disposable project. The store creates fresh-load/ under dev/debug/.

const Store := preload("res://dev/debug/_shared/preset_store.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const TUNING := "res://dev/debug/_shared/tests/fixtures/sample/game/sample/tuning/feedback/sound.tres"


func _initialize() -> void:
	var store := Store.new()
	var slot := Slot.new()
	var error := slot.configure("fresh-load", "sound", TUNING, store.root)
	if error == OK:
		error = store.save_slot(slot, "runtime").error
	if error == OK:
		error = store.save_combo("fresh-load", "runtime", [slot]).error
	for path: String in [store.preset_path(slot.id, "runtime"),
			store.combo_path("fresh-load", "runtime")]:
		if ResourceLoader.get_resource_uid(path) != ResourceUID.INVALID_ID:
			push_error("Runtime fixture unexpectedly has UID: " + path)
			error = ERR_INVALID_DATA
	if error == OK and "--invalid" in OS.get_cmdline_user_args():
		# A valid preset directory must not exempt an ordinary resource of the wrong type.
		error = ResourceSaver.save(Curve.new(), store.preset_path(slot.id, "ordinary"))
	if error != OK:
		push_error("Cannot prepare fresh-load runtime saves: " + error_string(error))
	quit(0 if error == OK else 1)
