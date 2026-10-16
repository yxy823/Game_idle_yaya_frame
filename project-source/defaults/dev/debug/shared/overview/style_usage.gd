extends RefCounted
## Which interfaces use which styles, read from their scenes with SceneState: the shared theme
## type variations and GameButton, and each interface's own Theme and the variations it defines.
## An interface is a debug target's game/<id>/ directory; scenes it instances count for it too.

enum Kind { SHARED_VARIATION, GAME_BUTTON, OWN_THEME, OWN_VARIATION }

const GAME_BUTTON := preload("res://game/shared/ui/game_button.gd")
const GAME_BUTTON_NAME := "GameButton"
const SHARED_ROOT := "res://game/shared/"


class Entry:
	extends RefCounted
	## A theme type variation, "GameButton", or the resource path of an interface's Theme.
	var name: String
	var kind: Kind
	## The interface that defines an own style; "" for a shared one.
	var owner: String
	var users: PackedStringArray = []

	func _init(entry_name: String, entry_kind: Kind, entry_owner: String) -> void:
		name = entry_name
		kind = entry_kind
		owner = entry_owner

	## A shared variation used by one interface can move back there; an interface's own style
	## used by two or more interfaces can move into shared.
	func hint() -> String:
		if kind == Kind.SHARED_VARIATION and users.size() == 1:
			return "可以移回该界面"
		if (kind == Kind.OWN_THEME or kind == Kind.OWN_VARIATION) and users.size() >= 2:
			return "可以搬进 shared"
		return ""


var shared: Array[Entry] = []
var own: Array[Entry] = []
var _by_name: Dictionary[String, Entry] = {}
## Interface directories by id, to find the owner of a Theme saved inside a scene.
var _directories: Dictionary[String, String] = {}
## Pairs of interface id and style name, counted once every Theme is known.
var _uses: Array[PackedStringArray] = []


## The theme type variations of a Theme, sorted: the project theme's are the shared ones.
static func variations(theme: Theme) -> PackedStringArray:
	var result: PackedStringArray = []
	for type in theme.get_type_list():
		if theme.get_type_variation_base(type) != &"":
			result.append(type)
	result.sort()
	return result


func scan(game_root: String, interfaces: PackedStringArray,
		shared_variations: PackedStringArray) -> void:
	for variation in shared_variations:
		shared.append(_entry(variation, Kind.SHARED_VARIATION, ""))
	shared.append(_entry(GAME_BUTTON_NAME, Kind.GAME_BUTTON, ""))
	var files: Dictionary[String, PackedStringArray] = {}
	for id in interfaces:
		_directories[id] = game_root.path_join(id) + "/"
		files[id] = PackedStringArray()
		_files(game_root.path_join(id), files[id])
		_add_theme_files(files[id], id)
	for id in interfaces:
		var visited: Dictionary[String, bool] = {}
		for path in files[id]:
			if path.get_extension() == "tscn":
				_scan_scene(ResourceLoader.load(path) as PackedScene, id, visited)
	for use in _uses:
		var entry: Entry = _by_name.get(use[1])
		if entry != null and not use[0] in entry.users:
			entry.users.append(use[0])


func _add_theme_files(paths: PackedStringArray, id: String) -> void:
	for path in paths:
		var theme := ResourceLoader.load(path) as Theme if path.get_extension() == "tres" else null
		if theme != null:
			_add_theme(theme, id)


func _entry(entry_name: String, kind: Kind, entry_owner: String) -> Entry:
	var entry := Entry.new(entry_name, kind, entry_owner)
	_by_name[entry_name] = entry
	return entry


## An interface's Theme and its variations; a name already known keeps its first owner.
func _add_theme(theme: Theme, id: String) -> void:
	if _by_name.has(theme.resource_path) or theme.resource_path.begins_with(SHARED_ROOT):
		return
	own.append(_entry(theme.resource_path, Kind.OWN_THEME, id))
	for variation in variations(theme):
		if not _by_name.has(variation):
			own.append(_entry(variation, Kind.OWN_VARIATION, id))


func _scan_scene(scene: PackedScene, id: String, visited: Dictionary[String, bool]) -> void:
	if visited.has(scene.resource_path):
		return
	visited[scene.resource_path] = true
	var state := scene.get_state()
	for node in range(state.get_node_count()):
		var instance := state.get_node_instance(node)
		if instance != null:
			_scan_scene(instance, id, visited)
		for property in range(state.get_node_property_count(node)):
			_use(id, state.get_node_property_name(node, property),
				state.get_node_property_value(node, property))


func _use(id: String, property: StringName, value: Variant) -> void:
	if property == &"theme_type_variation":
		_uses.append(PackedStringArray([id, String(value)]))
	elif property == &"theme" and value is Theme:
		_add_theme(value, _owner(value.resource_path, id))
		_uses.append(PackedStringArray([id, value.resource_path]))
	elif property == &"script" and _is_game_button(value as Script):
		_uses.append(PackedStringArray([id, GAME_BUTTON_NAME]))


## A Theme saved inside a scene belongs to the interface whose directory holds that scene.
func _owner(path: String, fallback: String) -> String:
	for id in _directories:
		if path.begins_with(_directories[id]):
			return id
	return fallback


static func _is_game_button(script: Script) -> bool:
	while script != null:
		if script == GAME_BUTTON:
			return true
		script = script.get_base_script()
	return false


static func _files(directory: String, output: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(directory):
		output.append(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_files(directory.path_join(child), output)
