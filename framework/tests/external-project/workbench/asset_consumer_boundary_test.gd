extends GdUnitTestSuite

## E7: consumers own cold-created nodes and declare their saved resources without editor tools.

const ObjectView = preload("res://components/feedback/feedback_object.gd")
const Game = preload("res://asset_workbench/examples/single/example_reward_game.gd")
const Session = preload("res://asset_workbench/ui/preview_session.gd")
const CONSUMERS: Array[PackedScene] = [
	preload("res://asset_workbench/examples/single/example_game.tscn"),
	preload("res://asset_workbench/examples/composition/example_composition.tscn"),
	preload("res://asset_workbench/examples/shader_composition/example_composition.tscn"),
	preload("res://asset_workbench/examples/effects_composition/example_consumer.tscn"),
]
const EXPECTED_CUES: Array = [
	["single/example_feedback.tres"],
	["composition/example_composition_trophy.tres", "composition/example_composition_star.tres",
		"composition/example_composition_bonus.tres"],
	["shader_composition/example_outline_cue.tres", "shader_composition/example_dissolve_cue.tres",
		"shader_composition/example_noise_cue.tres"],
	["effects_composition/example_cluster_core_cue.tres", "effects_composition/example_cluster_local_cue.tres",
		"effects_composition/example_cluster_world_cue.tres"],
]
const DIRECTORY: String = "res://tests/features/asset_consumer_boundary/"

var _owned: Array[String] = []


func before_test() -> void:
	assert_int(DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(DIRECTORY))).is_equal(OK)


func after_test() -> void:
	for path: String in _owned:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_owned.clear()


func test_cold_script_construction_releases_all_internal_nodes() -> void:
	for consumer_script: GDScript in [ObjectView, Game]:
		var baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var consumer: Node = consumer_script.new()
		assert_bool(consumer.is_inside_tree()).is_false()
		consumer.free()
		assert_int(int(Performance.get_monitor(
			Performance.OBJECT_ORPHAN_NODE_COUNT))).is_equal(baseline)


func test_cold_consumer_scenes_release_all_internal_nodes() -> void:
	for packed: PackedScene in CONSUMERS:
		var baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		for _cycle: int in 3:
			var consumer := packed.instantiate()
			assert_bool(consumer.is_inside_tree()).is_false()
			consumer.free()
		assert_int(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))) \
			.override_failure_message(packed.resource_path).is_equal(baseline)


func test_consumer_resource_dependencies_include_every_cue_without_workbench_tools() -> void:
	for index: int in CONSUMERS.size():
		var dependencies := _dependencies(CONSUMERS[index].resource_path, false)
		for cue: String in EXPECTED_CUES[index]:
			assert_array(dependencies).contains(["res://asset_workbench/examples/" + cue])
		for path: String in _dependencies(CONSUMERS[index].resource_path, true):
			assert_bool(path.begins_with("res://tools/")
				or path.begins_with("res://asset_workbench/ui/")
				or path.begins_with("res://asset_workbench/analyzer/")) \
				.override_failure_message("Consumer requires editor tool: " + path).is_false()


func test_cached_object_scene_reads_newly_saved_values_without_mutating_binding() -> void:
	_assert_cached_scene_reads_save(ObjectView, "object")


func test_cached_single_scene_reads_newly_saved_values_without_mutating_binding() -> void:
	_assert_cached_scene_reads_save(Game, "single")


func test_empty_or_unsaved_object_binding_is_safe_and_explained() -> void:
	for binding: FeedbackCue in [null, FeedbackCue.new()]:
		var consumer: ObjectView = auto_free(ObjectView.new())
		consumer.cue_resource = binding
		add_child(consumer)
		assert_object(consumer.cue).is_null()
		assert_str(consumer.cue_path).is_empty()
		assert_str(consumer.tooltip_text).contains("Cue binding")
		assert_int(consumer.presenter.active_effect_count()).is_zero()


func test_empty_or_unsaved_single_binding_disables_activation_and_explains_issue() -> void:
	for binding: FeedbackCue in [null, FeedbackCue.new()]:
		var consumer: Game = auto_free(Game.new())
		consumer.cue_resource = binding
		add_child(consumer)
		assert_object(consumer.cue).is_null()
		var button: Button = consumer.get("_button")
		assert_bool(button.disabled).is_true()
		assert_str(consumer.get("_count").text).contains("Missing or invalid")
		consumer.activate_example()
		assert_int(consumer.reward_count).is_zero()


func test_single_white_background_labels_and_native_button_focus_remain_readable() -> void:
	var consumer: Game = auto_free(CONSUMERS[0].instantiate())
	add_child(consumer)
	for node: Node in consumer.find_children("*", "Label", true, false):
		assert_bool((node as Label).get_theme_color("font_color") == Color.BLACK).is_true()
	var button: Button = consumer.get("_button")
	var native_theme := ThemeDB.get_default_theme()
	assert_object(button.get_theme_stylebox("normal")) \
		.is_same(native_theme.get_stylebox("normal", "Button"))
	assert_object(button.get_theme_stylebox("focus")) \
		.is_same(native_theme.get_stylebox("focus", "Button"))
	assert_bool(button.get_theme_color("font_color") == native_theme.get_color(
		"font_color", "Button")).is_true()


func _assert_cached_scene_reads_save(consumer_script: GDScript, stem: String) -> void:
	var cue_path := DIRECTORY + stem + "-cue.tres"
	var scene_path := DIRECTORY + stem + "-consumer.tscn"
	_owned.append_array([scene_path, cue_path])
	assert_int(ResourceSaver.save(FeedbackCue.new(), cue_path)).is_equal(OK)
	var binding := load(cue_path) as FeedbackCue
	var prototype: Node = consumer_script.new()
	prototype.set("cue_resource", binding)
	var packed := PackedScene.new()
	assert_int(packed.pack(prototype)).is_equal(OK)
	prototype.free()
	assert_int(ResourceSaver.save(packed, scene_path)).is_equal(OK)
	var cached_scene := load(scene_path) as PackedScene
	var session := Session.new()
	assert_str(session.open(cue_path)).is_empty()
	session.current().gain_db = -27.0
	assert_str(session.save_current()).is_empty()
	assert_object(load(scene_path)).is_same(cached_scene)
	var consumer: Node = auto_free(cached_scene.instantiate())
	var cached_binding: FeedbackCue = consumer.get("cue_resource")
	assert_object(cached_binding).is_same(binding)
	assert_float(cached_binding.gain_db).is_equal(-12.0)
	add_child(consumer)
	var current: FeedbackCue = consumer.get("cue")
	assert_float(current.gain_db).is_equal(-27.0)
	assert_object(current).is_not_same(cached_binding)
	assert_float(cached_binding.gain_db).is_equal(-12.0)
	if consumer is ObjectView:
		var object := consumer as ObjectView
		var trial := current.trial_copy()
		trial.gain_db = -31.0
		object.preview(trial)
		assert_str(object.cue_path).is_equal(cue_path)
		assert_object(object.cue_resource).is_same(binding)
		assert_float(binding.gain_db).is_equal(-12.0)


func _dependencies(root_path: String, include_script_references: bool) -> Array[String]:
	var visited: Array[String] = []
	var pending: Array[String] = [root_path]
	var source_paths := RegEx.new()
	assert_int(source_paths.compile("res://[A-Za-z0-9_./-]+")).is_equal(OK)
	while not pending.is_empty():
		var path: String = pending.pop_back()
		if path in visited:
			continue
		visited.append(path)
		if path.get_extension() == "gd" and include_script_references:
			# Godot reports no GDScript preload dependencies; inspect those source references too.
			for match: RegExMatch in source_paths.search_all(FileAccess.get_file_as_string(path)):
				pending.append(match.get_string())
		elif path.get_extension() in ["tscn", "tres"]:
			for dependency: String in ResourceLoader.get_dependencies(path):
				# A dependency may include UID and type prefixes before its fallback resource path.
				pending.append(dependency.get_slice("::", dependency.get_slice_count("::") - 1))
	return visited
