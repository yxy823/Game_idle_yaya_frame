extends RefCounted
## Names of the sample sound slot and an analysis action that uses the measured peak.

const TITLE := "按钮音效"
## Implementations in game/, by UID: name and parameter script.
const CANDIDATES := {
	"uid://da0gfd213jcjc": {"name": "嘟声 · beep"},
}
const FIELDS := {
	"volume_db": "音量", "pitch_mode": "音高方式",
}
## Enum values in Chinese, by stored value.
const VALUES := {
	"pitch_mode": {0: "固定", 1: "逐轮升高"},
}


func action_names() -> PackedStringArray:
	return []


## The analysis section shows `action` in its header and `notes` below the metrics.
func analysis_extras(live: Resource, metrics: Dictionary) -> Dictionary:
	var peak: Dictionary = metrics.get("peak_dbfs", {})
	var usable: bool = peak.get("status") in ["ok", "estimate"] and peak.get("value") != null
	var reason := "" if usable else "没有算出峰值"
	var notes: PackedStringArray = []
	if reason.is_empty():
		notes.append("归一后音量 %.1f dB" % -float(peak.value))
	return {"action": "峰值归一", "icon": "arrow-bar-to-down",
		"tooltip": "按分析出的峰值设置音量，让峰值落在 0 dBFS", "reason": reason, "notes": notes,
		"apply": func() -> String:
			live.volume_db = -float(peak.value)
			return "已按峰值设置音量 %.1f dB" % live.volume_db}
