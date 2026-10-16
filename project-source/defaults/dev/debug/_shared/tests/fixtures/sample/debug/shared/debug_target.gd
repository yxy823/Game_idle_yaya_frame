extends RefCounted
## shared has no scene or fixture of its own; it only names itself and its slot list group.

const TITLE := "共享"
const FIXTURES: Dictionary[String, String] = {}
const CATEGORIES: Dictionary[String, String] = {"shared": "共享"}


func matches(_scene: Node) -> bool:
	return false
