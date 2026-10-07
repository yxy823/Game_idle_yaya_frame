extends RefCounted
## Names shown by the debug window and the hold time in milliseconds; no trial actions.

const TITLE := "动画时序"
const FIELDS := {
	"hold": "停留时长", "motion_curve": "运动曲线",
}


## The value box shows the hold time as "300 ms"; other fields keep the default format.
func value_text(field_name: String, value: Variant) -> String:
	return "%d ms" % roundi(float(value) * 1000.0) if field_name == "hold" else ""
