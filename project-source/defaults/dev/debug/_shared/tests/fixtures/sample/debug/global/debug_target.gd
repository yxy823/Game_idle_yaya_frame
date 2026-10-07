extends RefCounted
## global has no scene or fixture of its own; it only names its slot list group.

const FIXTURES: Dictionary[String, String] = {}
const CATEGORIES: Dictionary[String, String] = {"global": "全局"}


func matches(_scene: Node) -> bool:
	return false
