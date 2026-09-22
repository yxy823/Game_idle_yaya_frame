class_name FeedbackTimeline
extends Resource

## Saved finite orchestration; transform animation remains in native Animation clips.

@export_range(0.01, 120.0, 0.01) var length_seconds: float = 4.0
@export var clips: Array[FeedbackTimelineClip] = []


func validation_error() -> String:
	if not is_finite(length_seconds) or length_seconds <= 0.0 or length_seconds > 120.0:
		return "Timeline length must be above zero and at most 120 seconds."
	if clips.is_empty() or clips.size() > 128:
		return "Timeline requires between 1 and 128 clips."
	for index: int in clips.size():
		var issue := _clip_error(index)
		if not issue.is_empty():
			return "Clip %d: %s" % [index + 1, issue]
	return ""


func playback_copy() -> FeedbackTimeline:
	# Copy mutable containers and clip values; no playback state is stored in definitions.
	var result := FeedbackTimeline.new()
	result.length_seconds = length_seconds
	for clip: FeedbackTimelineClip in clips:
		result.clips.append(clip.duplicate(false) as FeedbackTimelineClip)
	return result


func _clip_error(index: int) -> String:
	var clip := clips[index]
	if clip == null:
		return "Timeline contains an empty clip."
	var issue := clip.validation_error()
	if not issue.is_empty():
		return issue
	if clip.end_seconds() > length_seconds:
		return "Clip ends after the timeline."
	for previous: int in index:
		var other := clips[previous]
		if clip.target == other.target and clip.start_seconds < other.end_seconds() \
				and other.start_seconds < clip.end_seconds():
			return "Overlapping clips cannot own the same target: %s" % clip.target
	return ""
