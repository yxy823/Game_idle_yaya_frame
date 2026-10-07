extends SceneTree
## Runs queued candidate adoptions without opening the debug window; see the follow-up steps in README.md.

const Adoption := preload("res://dev/debug/_shared/candidate_adoption.gd")
const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")


func _initialize() -> void:
	Uids.repair()
	var result := Adoption.run_queue("res://dev/debug")
	# What moved is logged in dev/debug/adoption-log.md; only failures are written here.
	if result.error != OK:
		printerr(result.text)
		printerr(result.detail)
	quit(0 if result.error == OK else 1)
