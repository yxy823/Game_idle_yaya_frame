extends RefCounted
## Copies the sample game's tuning, its ring effect and the sample dev candidates into user://
## with fresh UIDs, so adoption can move them without touching dev/ or game/. Everything a
## copied tuning resource uses is a user:// copy too, because adoption refuses files in dev/.
## Call cleanup() after each test.

const Slot := preload("res://dev/debug/_shared/slot.gd")
const Definition := preload("res://dev/debug/_shared/candidate_definition.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const SoundSlot := preload(
	"res://dev/debug/_shared/tests/fixtures/sample/debug/sample/slots/feedback/sound/slot.gd")
const EffectSlot := preload(
	"res://dev/debug/_shared/tests/fixtures/sample/debug/sample/slots/feedback/effect/slot.gd")
const SAMPLE := "res://dev/debug/_shared/tests/fixtures/sample/"
const SOUNDS := SAMPLE + "debug/sample/slots/feedback/sound/"
const SPARK := SAMPLE + "debug/sample/slots/feedback/effect/spark/"
const RING := SAMPLE + "game/sample/feedback/effect/ring/"
const TUNING := SAMPLE + "game/sample/tuning/feedback/"
const NAMES := {"chime": "风铃 · chime", "click": "咔哒 · click"}

var root: String = "user://tests/adoption-%d" % Time.get_ticks_usec()
var uids: Array[int] = []
## Source UID text -> UID text of its copy, applied to the copied scenes.
var _renamed: Dictionary[String, String] = {}


func dev_root() -> String:
	return root.path_join("dev")


func game_sample() -> String:
	return root.path_join("game/sample")


## The copied ring effect, standing in for an implementation the game adopted earlier.
func ring_directory() -> String:
	return game_sample().path_join("feedback/effect/ring")


## The sound slot: the game has no sound yet; chime and click wait in dev/.
func sound_slot() -> Slot:
	var game_path := game_sample().path_join("tuning/feedback/sound.tres")
	DirAccess.make_dir_recursive_absolute(game_path.get_base_dir())
	ResourceSaver.save(_tuning_script("sound_tuning.gd").new(), game_path)
	for identity: String in NAMES:
		var error := _sound_candidate(identity)
		assert(error == OK, "Invalid sample audio candidate: " + identity)
	var slot := Slot.new()
	slot.configure("sample", "feedback/sound", game_path, dev_root())
	slot.actions = SoundSlot.new()
	slot.refresh_candidates()
	return slot


func _sound_candidate(identity: String) -> Error:
	var source := SOUNDS + identity + "/"
	var definition := ResourceLoader.load(source + "candidate.tres", "",
		ResourceLoader.CACHE_MODE_IGNORE) as Definition
	if Codec.resolve_uid(definition.candidate_uid) != source + identity + ".wav":
		return ERR_INVALID_DATA
	var directory := dev_root().path_join("sample/slots/feedback/sound/" + identity)
	DirAccess.make_dir_recursive_absolute(directory)
	var audio := directory.path_join(identity + ".wav")
	DirAccess.copy_absolute(source + identity + ".wav", audio)
	DirAccess.copy_absolute(source + "README.md", directory.path_join("README.md"))
	var number := _new_uid(audio)
	var config := ConfigFile.new()
	config.load(source + identity + ".wav.import")
	config.set_value("remap", "uid", ResourceUID.id_to_text(number))
	config.save(audio + ".import")
	definition.candidate_uid = ResourceUID.id_to_text(number)
	return ResourceSaver.save(definition, directory.path_join("candidate.tres"))


## The effect slot: the game uses the ring copy; the spark candidate's script preloads its
## parameter script by path.
func effect_slot() -> Slot:
	var ring := _copy_ring()
	var game_path := game_sample().path_join("tuning/feedback/effect.tres")
	DirAccess.make_dir_recursive_absolute(game_path.get_base_dir())
	var tuning: Resource = _tuning_script("effect_tuning.gd").new()
	tuning.candidate = ResourceLoader.load(ring.scene)
	tuning.candidate_params = (ResourceLoader.load(ring.params) as Script).new()
	ResourceSaver.save(tuning, game_path)
	_copy_spark()
	var slot := Slot.new()
	slot.configure("sample", "feedback/effect", game_path, dev_root())
	slot.actions = EffectSlot.new()
	slot.refresh_candidates()
	return slot


## The ring keeps an adopted.tres beside the slot, as an implementation just moved into game/.
func _copy_ring() -> Dictionary:
	var directory := ring_directory()
	DirAccess.make_dir_recursive_absolute(directory)
	var params := _copy_script(RING, directory, "ring_params.gd")
	_copy_script(RING, directory, "ring_effect.gd")
	var scene := _copy_scene(RING, directory, "ring_effect.tscn")
	var descriptor := dev_root().path_join("sample/slots/feedback/effect/ring")
	DirAccess.make_dir_recursive_absolute(descriptor)
	var params_path := directory.path_join("ring_params.gd")
	var definition := Definition.new()
	definition.display_name = "圆环"
	definition.candidate_uid = ResourceUID.id_to_text(scene)
	definition.default_params = {"script_uid": ResourceUID.id_to_text(params),
		"fields": Codec.pack_fields((ResourceLoader.load(params_path) as Script).new()).value}
	ResourceSaver.save(definition, descriptor.path_join(Slot.ADOPTED))
	return {"scene": directory.path_join("ring_effect.tscn"), "params": params_path}


func _copy_spark() -> void:
	var directory := dev_root().path_join("sample/slots/feedback/effect/spark")
	DirAccess.make_dir_recursive_absolute(directory)
	var params := _copy_script(SPARK, directory, "spark_params.gd")
	_copy_script(SPARK, directory, "spark_effect.gd")
	var scene := _copy_scene(SPARK, directory, "spark_effect.tscn")
	var definition := ResourceLoader.load(SPARK + "candidate.tres", "",
		ResourceLoader.CACHE_MODE_IGNORE) as Definition
	definition.candidate_uid = ResourceUID.id_to_text(scene)
	definition.default_params.script_uid = ResourceUID.id_to_text(params)
	ResourceSaver.save(definition, directory.path_join("candidate.tres"))


func _tuning_script(file: String) -> Script:
	var directory := game_sample().path_join("tuning/feedback")
	DirAccess.make_dir_recursive_absolute(directory)
	_copy_script(TUNING, directory, file)
	return ResourceLoader.load(directory.path_join(file)) as Script


func _copy_script(source: String, directory: String, file: String) -> int:
	var path := directory.path_join(file)
	_write(path, FileAccess.get_file_as_string(source + file).replace(source, directory + "/"))
	var number := _new_uid(path)
	_write(path + ".uid", ResourceUID.id_to_text(number) + "\n")
	var old := FileAccess.get_file_as_string(source + file + ".uid").strip_edges()
	_renamed[old] = ResourceUID.id_to_text(number)
	return number


## The copied scene names the copied scripts by their new paths and UIDs and has its own UID.
func _copy_scene(source: String, directory: String, file: String) -> int:
	var path := directory.path_join(file)
	var number := _new_uid(path)
	var old := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(source + file))
	_renamed[old] = ResourceUID.id_to_text(number)
	var text := FileAccess.get_file_as_string(source + file).replace(source, directory + "/")
	for identity: String in _renamed:
		text = text.replace("\"%s\"" % identity, "\"%s\"" % _renamed[identity])
	_write(path, text)
	return number


func _new_uid(path: String) -> int:
	var number := ResourceUID.create_id()
	ResourceUID.add_id(number, path)
	uids.append(number)
	return number


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func select(slot: Slot, candidate_id: String) -> Error:
	for index in range(slot.candidates.size()):
		if slot.candidates[index].id == candidate_id:
			return slot.select_candidate(index).error
	return ERR_DOES_NOT_EXIST


func cleanup() -> void:
	for number in uids:
		if ResourceUID.has_id(number):
			ResourceUID.remove_id(number)
	_remove(root)


static func _remove(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for child in DirAccess.get_directories_at(directory):
		_remove(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
