extends RefCounted

## Two in-memory alternatives and one explicit existing project resource to author.

var target_path: String = ""
var active_index: int = 0
var drafts: Array[FeedbackCue] = []
var saved: FeedbackCue

var _disk_text: String = ""


func open(path: String) -> String:
	if not path.begins_with("res://") or not path.ends_with(".tres"):
		return "Choose an existing project .tres cue."
	if not FileAccess.file_exists(path):
		return "Cue file is missing: %s" % path
	var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as FeedbackCue
	if resource == null:
		return "The target is not a FeedbackCue."
	var issue := resource.validation_error()
	if not issue.is_empty():
		return issue
	target_path = path
	_disk_text = FileAccess.get_file_as_string(path)
	saved = resource
	drafts = [saved.trial_copy(), saved.trial_copy()]
	active_index = 0
	return ""


func current() -> FeedbackCue:
	return drafts[active_index]


func is_dirty() -> bool:
	return not current().same_values(saved)


func reset_current() -> void:
	drafts[active_index] = saved.trial_copy()


func copy_to_other() -> void:
	drafts[1 - active_index] = current().trial_copy()


func save_current() -> String:
	if not OS.has_feature("editor"):
		return "Saving project resources is available only from the Godot editor binary."
	var issue := current().validation_error()
	if not issue.is_empty():
		return issue
	if FileAccess.get_file_as_string(target_path) != _disk_text:
		return "File changed on disk. Reload before saving; trial edits are still available."
	var error := ResourceSaver.save(current().trial_copy(), target_path)
	if error != OK:
		return "Save failed: %s. Trial edits were retained." % error_string(error)
	var reloaded := ResourceLoader.load(
		target_path, "", ResourceLoader.CACHE_MODE_IGNORE
	) as FeedbackCue
	if reloaded == null or not current().same_values(reloaded):
		return "Save could not be verified. Keep trial edits and inspect the target file."
	saved = reloaded
	_disk_text = FileAccess.get_file_as_string(target_path)
	return ""
