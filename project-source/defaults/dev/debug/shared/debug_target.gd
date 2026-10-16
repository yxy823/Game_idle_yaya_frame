extends RefCounted
## shared has no fixture; its main scene is the style overview, opened when shared is picked.

const TITLE := "共享"
const MAIN_SCENE := "res://dev/debug/shared/overview/style_overview.tscn"
const FIXTURES: Dictionary[String, String] = {}
const CATEGORIES: Dictionary[String, String] = {
	"shared": "共享",
	"shared/ui": "界面样式",
	"shared/ui/primitives": "原始值",
	"shared/ui/semantic": "语义值",
	"shared/ui/semantic/buttons": "按钮",
	"shared/ui/motion": "动效",
}


func matches(scene: Node) -> bool:
	return scene != null and scene.scene_file_path == MAIN_SCENE
