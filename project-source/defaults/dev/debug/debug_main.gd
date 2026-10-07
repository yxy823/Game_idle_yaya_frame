extends Node

const WINDOW := preload("res://dev/debug/_shared/debug_window.tscn")
const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")
const Project := preload("res://dev/debug/debug_project.gd")


func _ready() -> void:
	# Root is still adding its initial children during ready; defer the whole boot.
	_boot.call_deferred()


func _boot() -> void:
	# Before the window or the game loads any tuning resource: moved files get their UIDs back
	# even when the editor's UID cache still names dev/, then queued moves run.
	Uids.repair()
	var queued := Adoption.run_queue("res://dev/debug")
	var save_path := Project.new().use_debug_save(get_tree())
	var window := WINDOW.instantiate() as Window
	window.force_native = true
	get_tree().root.add_child(window)
	window.configure(save_path)
	window.show()
	window.place_beside(get_tree().root)
	if queued.error != OK:
		window.report(queued)
	elif not queued.done.is_empty():
		window.report({"error": OK,
			"text": "上次采纳的 %s 已移入游戏，现在开始使用" % "、".join(queued.done)
				+ ("。" + queued.note if not queued.note.is_empty() else "")})
	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	var error := get_tree().change_scene_to_file(main_scene)
	if error != OK:
		window.report({"error": error, "message": "Cannot start " + main_scene,
			"text": "没能打开游戏主场景：项目设置里的主场景读不出来。请让 Agent 检查"})
