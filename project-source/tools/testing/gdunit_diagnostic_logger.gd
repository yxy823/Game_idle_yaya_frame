# 引擎侧原始诊断输出；不修改 GdUnit 主监视器，也不负责判定 Feature 完成。
extends Logger

## Persist native diagnostics independently of the primary monitor's mutable log.
signal diagnostic_recorded(record: Dictionary)

var failed: bool = false

var _output: FileAccess
var _next_id: int = 0
var _write_lock: Mutex = Mutex.new()


# 这是 Godot Logger 的正式回调签名，不能为 lint 参数数量度量而删减参数。
func _log_error(
	function: String,
	file: String,
	line: int,
	message: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
) -> void:
	var record: Dictionary = {
		"event": "diagnostic",
		"kind": _diagnostic_kind(error_type),
		"message": rationale if not rationale.is_empty() else message,
		"monitor_message": message,
		"file": file,
		"line": line,
		"function": function,
		"epoch": 0,
		"phase": "external_thread",
	}
	# Only the main thread may inspect the runner's execution contexts.
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		diagnostic_recorded.emit(record)
	_write_lock.lock()
	_next_id += 1
	record["id"] = _next_id
	_write_event_locked(record)
	_write_lock.unlock()


func open_log(path: String) -> Error:
	_output = FileAccess.open(path, FileAccess.WRITE)
	if _output == null:
		return FileAccess.get_open_error()
	return OK


func write_event(event: Dictionary) -> void:
	_write_lock.lock()
	_write_event_locked(event)
	_write_lock.unlock()


func close_log() -> void:
	_write_lock.lock()
	if _output != null:
		_output.close()
		_output = null
	_write_lock.unlock()


# 调用者持有写锁；每条记录立即 flush，保留诊断顺序和可报告的写入失败。
func _write_event_locked(event: Dictionary) -> void:
	if _output == null:
		failed = true
		return
	_output.store_line(JSON.stringify(event))
	_output.flush()
	if _output.get_error() != OK:
		failed = true


func _diagnostic_kind(error_type: int) -> String:
	match error_type:
		ErrorType.ERROR_TYPE_WARNING:
			return "warning"
		ErrorType.ERROR_TYPE_SCRIPT:
			return "script_error"
		ErrorType.ERROR_TYPE_SHADER:
			return "shader_error"
	return "error"
