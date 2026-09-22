class_name FeedbackTimelineClip
extends Resource

## A target's playback window, relative to the composition root, in seconds.
## The target supplies its current Cue; this resource never changes that Cue.

@export var target: NodePath
@export_range(0.0, 120.0, 0.01) var start_seconds: float = 0.0
@export_range(0.01, 120.0, 0.01) var duration_seconds: float = 1.0
@export var priority: int = 0


func end_seconds() -> float:
	return start_seconds + duration_seconds


func validation_error() -> String:
	if not is_finite(start_seconds) or start_seconds < 0.0:
		return "Clip start must be finite and non-negative."
	if not is_finite(duration_seconds) or duration_seconds <= 0.0:
		return "Clip duration must be finite and positive."
	return _path_error()


func _path_error() -> String:
	if target.is_empty() or target.is_absolute() or target.get_subname_count() != 0:
		return "Clip target must be a relative object node path."
	for index: int in target.get_name_count():
		var part := String(target.get_name(index))
		if part in ["..", "."] or part.begins_with("%"):
			return "Clip target must stay below the composition root."
	return ""
