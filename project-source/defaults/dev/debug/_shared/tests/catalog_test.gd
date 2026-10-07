extends GdUnitTestSuite

const Target := preload("res://dev/debug/_shared/debug_target.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Params := preload("res://dev/debug/_shared/tests/fixtures/params.gd")
const Codec := preload("res://dev/debug/_shared/preset_codec.gd")
const Controls := preload("res://dev/debug/_shared/property_controls.gd")
const FIXTURE_ROOT := "res://dev/debug/_shared/tests/fixtures/catalog"
const SAMPLE_GAME := "res://dev/debug/_shared/tests/fixtures/sample/game"
const SAMPLE_DEV := "res://dev/debug/_shared/tests/fixtures/sample/debug"
const EFFECT := SAMPLE_GAME + "/sample/tuning/feedback/effect.tres"
## A path, not a preload: a test-script constant holding a script that cached tuning resources
## instantiate leaks at exit.
const RING_PARAMS := SAMPLE_GAME + "/sample/feedback/effect/ring/ring_params.gd"

var _directory: String


func before_test() -> void:
	_directory = "user://tests/debug-catalog-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_directory)


func after_test() -> void:
	_remove(_directory)


func test_sample_catalog_discovers_categories_and_global_shared_instances() -> void:
	var targets := Target.discover(SAMPLE_GAME, SAMPLE_DEV)
	assert_int(targets.size()).is_equal(2)
	assert_str(targets[0].id).is_equal("global")
	var sample: RefCounted = targets[1]
	assert_str(sample.id).is_equal("sample")
	assert_int(sample.paths.size()).is_equal(3)
	assert_bool(sample.slots.is_empty()).is_true()
	assert_str(sample.category_title("sample/feedback")).is_equal("反馈")
	assert_int(sample.activate(SAMPLE_DEV).error).is_equal(OK)
	for slot: Slot in sample.slots:
		assert_bool(slot.live == ResourceLoader.load(slot.game_path)).is_true()
		assert_str(slot.id).starts_with("sample/")


func test_hundreds_of_slots_and_multiple_targets_are_catalogued_before_activation() -> void:
	for target: String in ["board", "talent-tree", "shop", "global"]:
		var tuning := _directory.path_join(target + "/tuning/category/deeper")
		DirAccess.make_dir_recursive_absolute(tuning)
		for index in range(125):
			assert_int(ResourceSaver.save(Params.new(), tuning.path_join("slot-%03d.tres" % index))).is_equal(OK)
	var targets := Target.discover(_directory, _directory.path_join("debug"))
	assert_int(targets.size()).is_equal(4)
	for target: RefCounted in targets:
		assert_int(target.paths.size()).is_equal(125)
		assert_bool(target.slots.is_empty()).is_true()
		assert_bool(target.paths.has("category/deeper/slot-124")).is_true()


func test_candidate_discovery_is_lazy_skips_presets_and_applies_only_candidate_pair() -> void:
	var path := _directory.path_join("effect.tres")
	var defaults := ResourceLoader.load(EFFECT, "",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	ResourceSaver.save(defaults, path)
	var slot := Slot.new()
	slot.configure("sample", "feedback/effect", path, FIXTURE_ROOT)
	assert_int(slot.refresh_candidates().error).is_equal(OK)
	assert_int(slot.candidates.size()).is_equal(2)
	var live := slot.live
	var adopted_size: float = slot.live.candidate_params.size
	assert_int(slot.select_candidate(1).error).is_equal(OK)
	assert_bool(slot.live == live).is_true()
	assert_float(slot.live.candidate_params.size).is_equal(160.0)
	assert_float(slot.disk_defaults().candidate_params.size).is_equal(adopted_size)
	assert_int(slot.select_candidate(0).error).is_equal(OK)
	assert_float(slot.live.candidate_params.size).is_equal(adopted_size)


func test_optional_presets_and_unregistered_directories_are_not_candidates() -> void:
	var path := _directory.path_join("effect.tres")
	ResourceSaver.save(ResourceLoader.load(EFFECT), path)
	var slot := Slot.new()
	slot.configure("sample", "feedback/effect", path, _directory)
	DirAccess.make_dir_recursive_absolute(slot.directory.path_join("presets"))
	DirAccess.make_dir_recursive_absolute(slot.directory.path_join("unregistered/assets"))
	var descriptor := FIXTURE_ROOT + "/sample/slots/feedback/effect/large/candidate.tres"
	DirAccess.copy_absolute(descriptor, slot.directory.path_join("presets/candidate.tres"))
	DirAccess.copy_absolute(descriptor, slot.directory.path_join("unregistered/assets/candidate.tres"))
	assert_int(slot.refresh_candidates().error).is_equal(OK)
	assert_int(slot.candidates.size()).is_equal(1)
	assert_bool("frame_count" in slot.search_text()).is_true()


func test_preset_cannot_replace_the_parameter_class_for_an_adopted_candidate() -> void:
	var path := _directory.path_join("effect.tres")
	ResourceSaver.save(ResourceLoader.load(EFFECT), path)
	var slot := Slot.new()
	slot.configure("sample", "feedback/effect", path, _directory)
	var defaults := slot.disk_defaults()
	var checked := {"values": {"candidate": defaults.candidate,
		"candidate_params": Params.new()}, "issues": PackedStringArray()}
	slot.check_candidate_pair(checked, defaults)
	assert_array(checked.issues).contains_exactly(["candidate_params"])
	assert_str(checked.values.candidate_params.get_script().resource_path).is_equal(RING_PARAMS)


func test_candidate_parameter_is_reported_and_reverted_by_field() -> void:
	var path := _directory.path_join("effect.tres")
	ResourceSaver.save(ResourceLoader.load(EFFECT, "",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP), path)
	var slot := Slot.new()
	slot.configure("sample", "feedback/effect", path, FIXTURE_ROOT)
	var adopted: float = slot.live.candidate_params.size
	slot.live.candidate_params.size = adopted + 20.0
	assert_array(slot.modified_fields()).contains_exactly(["candidate_params/size"])
	assert_float(slot.saved_value("candidate_params/size")).is_equal(adopted)
	assert_int(slot.revert_field("candidate_params/size").error).is_equal(OK)
	assert_float(slot.live.candidate_params.size).is_equal(adopted)
	assert_array(slot.modified_fields()).is_empty()
	assert_int(slot.revert_field("candidate").error).is_equal(ERR_INVALID_PARAMETER)


## The project's own slots, then the sample's, so the check also runs where game/ is empty.
func test_every_slot_and_parameter_has_a_chinese_name() -> void:
	_assert_named(Target.discover(), "res://dev/debug")
	_assert_named(Target.discover(SAMPLE_GAME, SAMPLE_DEV), SAMPLE_DEV)


func _assert_named(targets: Array, debug_root: String) -> void:
	var missing: PackedStringArray = []
	var adopted: PackedStringArray = []
	for target: RefCounted in targets:
		assert_int(target.activate(debug_root).error).is_equal(OK)
		for slot: Slot in target.slots:
			if slot.display_name() == slot.slot_path.get_file().capitalize():
				missing.append(slot.id + " (TITLE)")
			var candidate := slot.disk_defaults().get("candidate") as Resource
			# Whichever candidate is adopted, it is named, not shown by its file name.
			var file_name := candidate.resource_path.get_file().get_basename() if candidate != null else ""
			if candidate != null and slot.candidate_title(candidate) == file_name:
				adopted.append(slot.id)
			missing.append_array(_unnamed_parameters(slot))
	assert_array(adopted).is_empty()
	assert_array(missing).is_empty()


func _unnamed_parameters(slot: Slot) -> PackedStringArray:
	assert_int(slot.refresh_candidates().error).is_equal(OK)
	var missing: PackedStringArray = []
	for field_name in _parameter_names(slot):
		if slot.field_caption(field_name, "").is_empty():
			missing.append(slot.id + ":" + field_name)
	return missing


func _parameter_names(slot: Slot) -> PackedStringArray:
	var resources: Array[Resource] = [slot.live]
	var adopted := slot.disk_defaults().get("candidate_params") as Resource
	if adopted != null:
		resources.append(adopted)
	for entry in slot.candidates:
		if entry.has("path"):
			var definition := ResourceLoader.load(entry.path)
			var script_path := Codec.resolve_uid(definition.default_params.get("script_uid", ""))
			if not script_path.is_empty():
				resources.append((load(script_path) as Script).new())
	var result: PackedStringArray = []
	for resource in resources:
		for property in Controls.fields(resource):
			if not String(property.name) in ["candidate", "candidate_params"]:
				result.append(String(property.name))
			if property.hint == PROPERTY_HINT_ENUM and slot.constant("VALUES", {}).get(property.name, {}).size() \
					!= String(property.hint_string).split(",").size():
				result.append(String(property.name) + " (enum values)")
	return result


func _remove(directory: String) -> void:
	for child in DirAccess.get_directories_at(directory):
		_remove(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
