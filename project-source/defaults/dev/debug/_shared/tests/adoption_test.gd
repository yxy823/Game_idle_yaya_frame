extends GdUnitTestSuite
## Adopting dev candidates from user:// copies of the sample; the real dev/ and game/ files stay
## untouched.

const Fixture := preload("res://dev/debug/_shared/tests/fixtures/adoption_fixture.gd")
const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")
const Slot := preload("res://dev/debug/_shared/slot.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")

var _fixture: Fixture


func before_test() -> void:
	_fixture = Fixture.new()


func after_test() -> void:
	_fixture.cleanup()


func test_dev_sound_candidate_moves_into_game_and_plays_at_once() -> void:
	var slot := _fixture.sound_slot()
	assert_int(_fixture.select(slot, "chime")).is_equal(OK)
	var source := slot.directory.path_join("chime")
	var identity := ResourceLoader.get_resource_uid(source.path_join("chime.wav"))
	var plans := Adoption.plans_for([slot])
	var adoption: Dictionary = plans[slot.id]
	var destination := _fixture.game_sample().path_join("feedback/sound/chime")
	assert_bool(adoption.deferred).is_false()
	assert_str(adoption.destination).is_equal(destination)
	var question := Adoption.confirm_text([slot], plans)
	assert_str(question).contains("把 风铃 · chime 移入游戏，并把按钮音效改为它")
	assert_str(question).contains("新增 " + destination.trim_prefix("res://") + "/（README.md、chime.wav）")
	assert_str(question).not_contains("res://")
	var result := Adoption.adopt_all([slot], plans)
	assert_str(result.get("text", "")).is_equal("已采纳：按钮音效改为 风铃 · chime")
	var moved := destination.path_join("chime.wav")
	assert_bool(FileAccess.file_exists(source.path_join("chime.wav"))).is_false()
	assert_bool(FileAccess.file_exists(source.path_join("chime.wav.import"))).is_false()
	assert_bool(FileAccess.file_exists(destination.path_join("README.md"))).is_true()
	assert_int(ResourceLoader.get_resource_uid(moved)).is_equal(identity)
	assert_str(ResourceUID.get_id_path(identity)).is_equal(moved)
	var disk := ResourceLoader.load(slot.game_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_str(disk.candidate.resource_path).is_equal(moved)
	var stream := slot.live.candidate as AudioStream
	assert_str(stream.resource_path).is_equal(moved)
	assert_float(stream.get_length()).is_greater(0.0)
	var player := auto_free(AudioStreamPlayer.new()) as AudioStreamPlayer
	player.stream = stream
	add_child(player)
	player.play()
	assert_bool(player.playing).is_true()
	assert_bool(slot.is_dirty()).is_false()


func test_adopted_sound_is_the_game_entry_and_the_other_candidate_stays() -> void:
	var slot := _fixture.sound_slot()
	_fixture.select(slot, "chime")
	Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	assert_int(slot.refresh_candidates().error).is_equal(OK)
	# Implementations slot.gd names in CANDIDATES (ids "game:…") stay listed after the game entry.
	var ids: Array = slot.candidates.map(func(entry: Dictionary) -> String: return entry.id) \
		.filter(func(id: String) -> bool: return not id.begins_with("game:"))
	assert_array(ids).contains_exactly(["", "click"])
	assert_str(slot.candidate_title(slot.disk_defaults().candidate)).is_equal("风铃 · chime")
	var loser := slot.directory.path_join("click")
	for file: String in ["click.wav", "click.wav.import", "README.md", "candidate.tres"]:
		assert_bool(FileAccess.file_exists(loser.path_join(file))).is_true()
	var record := FileAccess.get_file_as_string(_fixture.dev_root().path_join(Adoption.LOG))
	assert_str(record).contains("sample/feedback/sound（按钮音效） · 候选 chime 已移入")
	assert_str(record).contains("](_shared/README.md#收尾步骤)")
	assert_bool(FileAccess.file_exists(slot.directory.path_join("chime/adopted.tres"))).is_true()
	assert_str(record).contains("写入 " + slot.game_path.trim_prefix("res://"))


func test_script_candidate_is_queued_and_moves_at_the_next_start() -> void:
	var slot := _fixture.effect_slot()
	assert_int(_fixture.select(slot, "spark")).is_equal(OK)
	var source := slot.directory.path_join("spark")
	var scene_uid := ResourceLoader.get_resource_uid(source.path_join("spark_effect.tscn"))
	var plans := Adoption.plans_for([slot])
	var destination := _fixture.game_sample().path_join("feedback/effect/spark")
	assert_bool(plans[slot.id].deferred).is_true()
	assert_str(plans[slot.id].destination).is_equal(destination)
	assert_str(Adoption.confirm_text([slot], plans)).contains("原来的 圆环 留在 %s/，之后仍可在“实现”里选回"
		% Messages.relative(_fixture.ring_directory()))
	var result := Adoption.adopt_all([slot], plans)
	assert_str(result.text).is_equal("已采纳：点击特效改为 火花（游戏将在下次启动时使用）")
	var ring := _fixture.ring_directory().path_join("ring_effect.tscn")
	var disk := ResourceLoader.load(slot.game_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_str(disk.candidate.resource_path).is_equal(ring)
	assert_str(Adoption.queued_candidate(slot)).is_equal("spark")
	assert_bool(FileAccess.file_exists(source.path_join("spark_effect.gd"))).is_true()
	var queued := Adoption.run_queue(_fixture.dev_root())
	assert_int(queued.error).is_equal(OK)
	assert_array(queued.done).contains_exactly(["火花"])
	assert_bool(FileAccess.file_exists(source.path_join("spark_effect.gd"))).is_false()
	assert_str(FileAccess.get_file_as_string(destination.path_join("spark_effect.gd"))).not_contains(source)
	assert_str(Adoption.queued_candidate(slot)).is_empty()
	assert_str(ResourceUID.get_id_path(scene_uid)).is_equal(destination.path_join("spark_effect.tscn"))
	disk = ResourceLoader.load(slot.game_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_str(disk.candidate.resource_path).is_equal(destination.path_join("spark_effect.tscn"))
	assert_str(disk.candidate_params.get_script().resource_path).is_equal(
		destination.path_join("spark_params.gd"))
	var effect := auto_free(disk.candidate.instantiate()) as Node2D
	assert_str(effect.get_script().resource_path).is_equal(destination.path_join("spark_effect.gd"))
	_assert_ring_selectable(slot, ring)


## The replaced ring stays in game/ and can be chosen again.
func _assert_ring_selectable(slot: Slot, ring: String) -> void:
	var restarted := Slot.new()
	restarted.configure(slot.target_id, slot.slot_path, slot.game_path, slot.debug_root)
	restarted.actions = slot.actions
	restarted.refresh_candidates()
	var names: Array = restarted.candidates.map(func(entry: Dictionary) -> String:
		return entry.name)
	assert_array(names).contains(["圆环"])
	assert_int(restarted.select_candidate(names.find("圆环")).error).is_equal(OK)
	assert_str(restarted.live.candidate.resource_path).is_equal(ring)
	assert_str(restarted.live.candidate_params.get_script().resource_path).is_equal(
		_fixture.ring_directory().path_join("ring_params.gd"))
	var slots: Array[Slot] = [restarted]
	var plans := Adoption.plans_for(slots)
	assert_str(Adoption.confirm_text(slots, plans)).contains("· 把点击特效改回 圆环")
	assert_str(Adoption.adopt_all(slots, plans).text).is_equal("已采纳：点击特效改回 圆环")


func test_rule_slot_confirmation_reminds_to_write_the_rule_into_the_gdd() -> void:
	var slot := _fixture.sound_slot()
	var slots: Array[Slot] = [slot]
	assert_str(Adoption.confirm_text(slots, {})).not_contains(Adoption.LOGIC_REMINDER)
	var rule := GDScript.new()
	rule.source_code = "extends RefCounted
const TITLE := \"消除规则\"
const LOGIC := true
"
	assert_int(rule.reload()).is_equal(OK)
	slot.actions = rule.new()
	assert_str(Adoption.confirm_text(slots, {})).contains(
		"· 把消除规则的当前设定写入游戏
· 这是规则变化：采纳前先让 Agent 把规则写进 GDD")


func test_adopting_a_game_value_cancels_a_queued_move() -> void:
	var slot := _fixture.effect_slot()
	_fixture.select(slot, "spark")
	Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	assert_int(slot.select_candidate(0).error).is_equal(OK)
	var result := Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	assert_str(result.text).is_equal("已采纳：点击特效的当前设定已写入游戏")
	assert_str(Adoption.queued_candidate(slot)).is_empty()
	assert_bool(FileAccess.file_exists(slot.directory.path_join("spark/spark_effect.gd"))).is_true()


func test_adopted_candidates_keep_working_over_two_restarts_before_the_agent_finishes() -> void:
	var sound := _fixture.sound_slot()
	var effect := _fixture.effect_slot()
	var stale: Dictionary = {}
	for number in _fixture.uids:
		stale[number] = ResourceUID.get_id_path(number)
	_fixture.select(sound, "click")
	_fixture.select(effect, "spark")
	var slots: Array[Slot] = [sound, effect]
	assert_int(Adoption.adopt_all(slots, Adoption.plans_for(slots)).error).is_equal(OK)
	for _session in range(2):
		# A new session starts from the editor's UID cache, which still names dev/ paths.
		for number: int in stale:
			ResourceUID.set_id(number, stale[number])
		var restarted := _restart(sound)
		assert_int(restarted.refresh_candidates().error).is_equal(OK)
		assert_int(restarted.candidates.size()).is_greater(1)
		assert_int(Uids.repair(_fixture.root.path_join("game"))).is_greater(0)
		assert_int(Adoption.run_queue(_fixture.dev_root()).error).is_equal(OK)
		restarted = _restart(sound)
		var result := restarted.refresh_candidates()
		assert_dict(result).is_equal({"error": OK})
		assert_str(restarted.live.candidate.resource_path).is_equal(
			_fixture.game_sample().path_join("feedback/sound/click/click.wav"))
		var tuning := ResourceLoader.load(effect.game_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		var shown := auto_free(tuning.candidate.instantiate()) as Node2D
		assert_str(shown.get_script().resource_path).is_equal(
			_fixture.game_sample().path_join("feedback/effect/spark/spark_effect.gd"))


func test_a_file_that_cannot_move_puts_the_moved_files_back_and_says_so() -> void:
	var slot := _fixture.sound_slot()
	_fixture.select(slot, "chime")
	var plans := Adoption.plans_for([slot])
	var source := slot.directory.path_join("chime")
	var destination: String = plans[slot.id].destination
	# An open file cannot be renamed on Windows: README.md moves first, chime.wav fails.
	var held := FileAccess.open(source.path_join("chime.wav"), FileAccess.READ)
	var result := Adoption.adopt_all([slot], plans)
	held.close()
	assert_int(result.error).is_not_equal(OK)
	assert_str(result.text).is_equal("没能把 风铃 · chime 移入游戏：出现了意外问题；它的文件都还在原处。"
		+ "游戏的调参文件没有写入。关掉占用这些文件的程序后再采纳一次")
	for file: String in ["README.md", "chime.wav", "chime.wav.import", "candidate.tres"]:
		assert_bool(FileAccess.file_exists(source.path_join(file))).is_true()
	assert_bool(DirAccess.dir_exists_absolute(destination)).is_false()
	assert_str(Adoption.adopt_all([slot], Adoption.plans_for([slot])).text).is_equal(
		"已采纳：按钮音效改为 风铃 · chime")


func test_a_candidate_that_does_not_load_after_moving_goes_back() -> void:
	var slot := _fixture.sound_slot()
	_fixture.select(slot, "chime")
	var adoption: Dictionary = Adoption.plans_for([slot])[slot.id]
	var source: String = adoption.source
	# Stands in for a moved candidate the engine cannot load: the loaded path does not exist.
	adoption.candidate_path = source.path_join("missing.wav")
	var result := Adoption.move(adoption)
	assert_int(result.error).is_equal(ERR_CANT_OPEN)
	assert_str(result.text).is_equal("没能采纳“风铃 · chime”：移入游戏后读不出来，文件已放回 %s/"
		% Messages.relative(source))
	for file: String in ["README.md", "chime.wav", "chime.wav.import", "candidate.tres"]:
		assert_bool(FileAccess.file_exists(source.path_join(file))).is_true()
	assert_bool(DirAccess.dir_exists_absolute(adoption.destination)).is_false()
	var identity := ResourceLoader.get_resource_uid(source.path_join("chime.wav"))
	assert_str(ResourceUID.get_id_path(identity)).is_equal(source.path_join("chime.wav"))


func test_a_failed_path_rewrite_keeps_the_request_queued_until_it_succeeds() -> void:
	var slot := _fixture.effect_slot()
	_fixture.select(slot, "spark")
	Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	var moved := _fixture.game_sample().path_join("feedback/effect/spark/spark_effect.gd")
	var script := slot.directory.path_join("spark/spark_effect.gd")
	assert_int(FileAccess.set_read_only_attribute(script, true)).is_equal(OK)
	var failed := Adoption.run_queue(_fixture.dev_root())
	assert_int(FileAccess.set_read_only_attribute(moved, false)).is_equal(OK)
	assert_int(failed.error).is_not_equal(OK)
	assert_str(failed.text).starts_with("上次排队采纳的 火花 没能移入游戏")
	assert_str(failed.detail).contains("Cannot write " + moved)
	assert_str(Adoption.queued_candidate(slot)).is_equal("spark")
	var disk := ResourceLoader.load(slot.game_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_str(disk.candidate.resource_path).is_equal(_fixture.ring_directory().path_join("ring_effect.tscn"))
	var retried := Adoption.run_queue(_fixture.dev_root())
	assert_int(retried.error).is_equal(OK)
	assert_array(retried.done).contains_exactly(["火花"])
	assert_str(FileAccess.get_file_as_string(moved)).not_contains(slot.directory)


func test_a_queued_move_that_cannot_be_withdrawn_is_reported() -> void:
	var slot := _fixture.effect_slot()
	_fixture.select(slot, "spark")
	Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	var queue := Adoption.queue_path(slot)
	assert_int(FileAccess.set_read_only_attribute(queue, true)).is_equal(OK)
	slot.select_candidate(0)
	var result := Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	assert_int(result.error).is_not_equal(OK)
	assert_str(result.text).starts_with("已采纳：点击特效的当前设定已写入游戏。但排队的 spark 没能撤回")
	assert_str(Adoption.queued_candidate(slot)).is_equal("spark")
	# A queue entry that the next start ran but could not remove is reported too.
	var queued := Adoption.run_queue(_fixture.dev_root())
	assert_int(FileAccess.set_read_only_attribute(queue, false)).is_equal(OK)
	assert_int(queued.error).is_not_equal(OK)
	assert_array(queued.done).contains_exactly(["火花"])
	assert_str(queued.text).contains("火花 的排队记录没能删除")


func test_an_unwritable_log_is_reported_with_the_lines_to_add() -> void:
	var slot := _fixture.sound_slot()
	var log_path := _fixture.dev_root().path_join(Adoption.LOG)
	assert_int(Adoption.append_log(_fixture.dev_root(), "earlier")).is_equal(OK)
	assert_int(FileAccess.set_read_only_attribute(log_path, true)).is_equal(OK)
	_fixture.select(slot, "chime")
	var result := Adoption.adopt_all([slot], Adoption.plans_for([slot]))
	assert_int(FileAccess.set_read_only_attribute(log_path, false)).is_equal(OK)
	assert_int(result.error).is_not_equal(OK)
	assert_str(result.text).is_equal("已采纳：按钮音效改为 风铃 · chime。但待收尾记录没能写进 "
		+ "adoption-log.md：请让 Agent 按详情补记")
	assert_str(result.detail).contains("sample/feedback/sound（按钮音效） · 候选 chime 已移入")
	assert_str(FileAccess.get_file_as_string(log_path)).not_contains("候选 chime")


func test_editor_check_finds_only_this_projects_windowed_editor() -> void:
	# Command lines as Windows reports them (Get-CimInstance Win32_Process).
	var project := "D:/Games/Match/"
	var exe := "\"E:\\Godot\\Godot_v4.7.1-stable_win64.exe\""
	for editor: String in [exe + " -e --path D:/Games/Match ",
			"E:\\Godot\\Godot_v4.7.1-stable_win64.exe --path D:/Games/Match --editor",
			exe + " \"d:\\games\\match\\project.godot\" "]:
		assert_bool(Uids.editor_running("%s\r\n%s\r\n" % [exe, editor], project)).is_true()
	var others := "\n".join([exe + " -e --path D:/Games/Match_walkthrough",
		exe + " --path \"D:/Games/Other Game\" --editor"])
	assert_bool(Uids.editor_running(others, project)).is_false()
	var games := "\n".join([exe + " --path D:/Games/Match res://dev/debug/debug_main.tscn",
		exe + " --path D:/Games/Match --remote-debug tcp://127.0.0.1:6007 --editor-pid 4120",
		exe + " --headless --path D:/Games/Match/ --import",
		exe + " --headless --editor --path D:/Games/Match --script res://resave.gd"])
	assert_bool(Uids.editor_running(games, project)).is_false()


func _restart(slot: Slot) -> Slot:
	var fresh := Slot.new()
	ResourceLoader.load(slot.game_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).take_over_path(
		slot.game_path)
	fresh.configure(slot.target_id, slot.slot_path, slot.game_path, slot.debug_root)
	return fresh
