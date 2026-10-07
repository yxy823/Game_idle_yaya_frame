extends RefCounted
## Project hook of the debug entry: debug_main.gd calls use_debug_save once, before the window
## opens and before the game's main scene loads. Rewrite it for this project's save system.


## Points the game's save at a debug-only location and returns that path; fixture playback
## writes its starting state there. "" leaves the game on its real save, and the debug window
## says so in its status bar.
func use_debug_save(_tree: SceneTree) -> String:
	return ""
