extends RefCounted
## Catalog paths first; activate resources only for the selected target and global.

const Slot := preload("res://dev/debug/_shared/slot.gd")

var id: String = ""
var paths: Dictionary[String, String] = {}
var slots: Array[Slot] = []
var adapter: RefCounted


static func discover(game_root: String = "res://game",
		debug_root: String = "res://dev/debug") -> Array:
	var targets: Array = []
	for directory in DirAccess.get_directories_at(game_root):
		var tuning := game_root.path_join(directory + "/tuning")
		if not DirAccess.dir_exists_absolute(tuning):
			continue
		var target := new()
		target.id = directory
		_catalog(tuning, "", target.paths)
		var script_path := debug_root.path_join(directory + "/debug_target.gd")
		if ResourceLoader.exists(script_path):
			var script := ResourceLoader.load(script_path) as Script
			target.adapter = script.new()
		targets.append(target)
	return targets


static func _catalog(directory: String, prefix: String, output: Dictionary) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() == "tres":
			output[prefix + file.trim_suffix(".tres")] = directory.path_join(file)
	for child in DirAccess.get_directories_at(directory):
		_catalog(directory.path_join(child), prefix + child + "/", output)


## The adapter may declare TITLE "商店" for the target dropdown; the id when it names none.
func title() -> String:
	var shown := String(_constant("TITLE", ""))
	return shown if not shown.is_empty() else id


## The adapter may declare CATEGORIES {"shop/feedback": "反馈"}; "" when it names none.
func category_title(path: String) -> String:
	return String(_constant("CATEGORIES", {}).get(path, ""))


func _constant(constant_name: String, fallback: Variant) -> Variant:
	var script := adapter.get_script() as Script if adapter != null else null
	return script.get_script_constant_map().get(constant_name, fallback) if script != null \
		else fallback


func activate(debug_root: String = "res://dev/debug") -> Dictionary:
	if not slots.is_empty():
		return {"error": OK}
	var activated: Array[Slot] = []
	for relative: String in paths:
		var slot := Slot.new()
		var error := slot.configure(id, relative, paths[relative], debug_root)
		if error != OK:
			return {"error": error, "message": paths[relative]}
		var action_path := slot.directory.path_join("slot.gd")
		if ResourceLoader.exists(action_path):
			var script := ResourceLoader.load(action_path) as Script
			slot.actions = script.new()
		activated.append(slot)
	slots = activated
	return {"error": OK}
