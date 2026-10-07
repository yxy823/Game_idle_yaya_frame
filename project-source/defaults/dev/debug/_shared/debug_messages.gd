extends RefCounted
## Turns results into what the status bar shows: a plain sentence, plus the raw details that
## stay behind the "详情" button. Engine error names, res:// paths and field names only go there.


## Plain reason for an engine error code, written for the person at the debug window.
static func reason(error: int) -> String:
	match error:
		ERR_FILE_NOT_FOUND, ERR_DOES_NOT_EXIST:
			return "要用的文件不存在"
		ERR_CANT_OPEN, ERR_FILE_CANT_OPEN, ERR_FILE_CANT_READ:
			return "文件打不开"
		ERR_FILE_CANT_WRITE, ERR_CANT_CREATE, ERR_FILE_NO_PERMISSION:
			return "文件写不进去，可能正被其他程序占用"
		ERR_ALREADY_EXISTS:
			return "已经有同名的文件"
		ERR_BUSY:
			return "固定局面正在播放"
		ERR_INVALID_PARAMETER:
			return "名称或选择不可用"
		ERR_INVALID_DATA, ERR_PARSE_ERROR, ERR_FILE_CORRUPT:
			return "文件内容和当前参数对不上"
		ERR_UNAVAILABLE:
			return "现在还不能这样做"
	return "出现了意外问题"


## A project file as people read it: "game/shop/tuning/feedback/sound.tres".
static func relative(path: String) -> String:
	return path.trim_prefix("res://")


## The raw text behind "详情": engine error name, message, issues and written files.
static func detail(result: Dictionary) -> String:
	var lines: PackedStringArray = []
	var error: int = result.get("error", OK)
	if error != OK:
		lines.append("错误：%s（%d）" % [error_string(error), error])
	var message := String(result.get("message", ""))
	if not message.is_empty():
		lines.append(message)
	var issues: PackedStringArray = result.get("issues", PackedStringArray())
	for issue in issues:
		lines.append("· " + issue)
	if not String(result.get("detail", "")).is_empty():
		lines.append(String(result.detail))
	return "\n".join(lines)


## Status text for a result: its own "text" on failure, or "<failed>：<reason>。<fix>" on failure and
## `done` on success; partial loads say how many items fell back to the game value.
static func outcome(result: Dictionary, done: String, failed: String, fix: String) -> Dictionary:
	var error: int = result.get("error", OK)
	var issues: PackedStringArray = result.get("issues", PackedStringArray())
	var text := done
	if error != OK and result.has("text"):
		text = String(result.text)
	elif error != OK:
		text = "%s：%s。%s" % [failed, reason(error), fix]
	elif not issues.is_empty():
		text = "%s，其中 %d 项对不上，已改用游戏原值" % [done, issues.size()]
	return {"error": error, "text": text, "detail": detail(result)}


## Disables or enables a control; while disabled its tooltip says why it cannot be used.
static func explain(control: Control, disabled: bool, why: String) -> void:
	if not control.has_meta(&"usable_tooltip"):
		control.set_meta(&"usable_tooltip", control.tooltip_text)
	if control is BaseButton:
		(control as BaseButton).disabled = disabled
	control.tooltip_text = why if disabled and not why.is_empty() \
		else String(control.get_meta(&"usable_tooltip"))


## Sets the tooltip shown while the control can be used.
static func usable_tooltip(control: Control, text: String) -> void:
	control.set_meta(&"usable_tooltip", text)
	control.tooltip_text = text
