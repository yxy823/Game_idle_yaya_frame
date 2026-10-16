extends RefCounted
## shared has no scene or fixture of its own; it only names itself and its slot list groups.

const TITLE := "共享"
const FIXTURES: Dictionary[String, String] = {}
const CATEGORIES: Dictionary[String, String] = {
	"shared": "共享",
	"shared/ui": "界面样式",
	"shared/ui/primitives": "原始值",
	"shared/ui/semantic": "语义值",
	"shared/ui/semantic/buttons": "按钮",
	"shared/ui/motion": "动效",
}


func matches(_scene: Node) -> bool:
	return false
