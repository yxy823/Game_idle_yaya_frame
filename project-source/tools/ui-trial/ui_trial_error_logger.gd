## ui_trial_driver.gd 的引擎日志接收器：引擎报出的错误（含脚本运行错误、push_error）都让试用失败退出；
## 警告只记录。on_error(是否警告, 文字) 由驱动基类设置。
extends Logger

var on_error: Callable


# 这是 Godot Logger 的正式回调签名，不能为 lint 参数数量度量而删减参数。
func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
) -> void:
	var text := rationale if not rationale.is_empty() else code
	var where := "%s:%d %s" % [file, line, function]
	var report := on_error.bind(error_type == ERROR_TYPE_WARNING, "%s (%s)" % [text, where])
	# 主线程上立即结束，避免出错的协程返回后被当成正常完成。
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		report.call()
	else:
		report.call_deferred()
