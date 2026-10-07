extends RefCounted
## global has no scene or fixture of its own; it only names itself and its slot list group.

const TITLE := "全局"
const FIXTURES: Dictionary[String, String] = {}
const CATEGORIES: Dictionary[String, String] = {"global": "全局"}


func matches(_scene: Node) -> bool:
	return false
