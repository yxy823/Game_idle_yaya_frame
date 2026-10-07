extends RefCounted
## Names of the sample effect slot and its trial action.

const TITLE := "点击特效"
## Implementations in game/, by UID: name and parameter script.
const CANDIDATES := {
	"uid://cyp5gf4i57642": {"name": "圆环", "params": "uid://8pb4rl38n02h"},
}
const FIELDS := {
	"frame_count": "帧数", "fps": "帧率", "size": "尺寸", "count": "数量", "speed": "速度",
}


func action_names() -> PackedStringArray:
	return ["中央试播一次"]


func run(_action: String, live: Resource, scene: Node) -> Dictionary:
	var feedback := scene.get_node_or_null("Game/%Feedback") if scene != null else null
	if feedback == null or live.candidate == null:
		return {"error": ERR_UNAVAILABLE, "message": "Game or candidate missing",
			"text": "没能试播：游戏画面里没有样例游戏，或没有选候选"}
	var effect := live.candidate.instantiate() as Node2D
	effect.position = Vector2.ONE * 320.0
	feedback.add_child(effect)
	effect.play(live.candidate_params)
	return {"error": OK, "text": "已在中央试播一次"}
