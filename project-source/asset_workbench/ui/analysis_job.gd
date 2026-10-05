extends RefCounted

## Own one process and its files. The worker starts no descendants.

const Result = preload("res://yaya/asset_workbench/ui/analysis_result.gd")
const MAX_OUTPUT: int = 2097152

var request: Dictionary
var request_path: String
var process: Dictionary = {}
var timeout_seconds: float = 30.0
var _started: int
var _stdout: PackedByteArray = []
var _stderr: PackedByteArray = []
var _terminal: Dictionary = {}


func start(executable: String, worker: String) -> void:
	var file := FileAccess.open(request_path, FileAccess.WRITE)
	if file == null:
		fail("request_write", "Cannot create analysis request")
		return
	file.store_string(JSON.stringify(request))
	file.close()
	process = OS.execute_with_pipe(executable,
		["-B", "-u", worker, "--parent-pid", str(OS.get_process_id()),
			"--request", request_path], false)
	_started = Time.get_ticks_msec()
	if process.is_empty():
		fail("process_missing", "Cannot start configured Python executable")


func poll() -> Dictionary:
	if not _terminal.is_empty():
		return _terminal
	var received := _read_output()
	if _stdout.size() > MAX_OUTPUT or _stderr.size() > MAX_OUTPUT:
		fail("output_limit", "Analyzer output exceeded 2 MiB")
	elif float(Time.get_ticks_msec() - _started) / 1000.0 > timeout_seconds:
		fail("timeout", "Analysis exceeded %.1f seconds" % timeout_seconds)
	elif not OS.is_process_running(process.pid) and not received:
		_finish()
	return _terminal


func _read_output() -> bool:
	# Nonblocking reads with a per-frame bound keep rendering and audition responsive.
	var output := (process.stdio as FileAccess).get_buffer(65536)
	var errors := (process.stderr as FileAccess).get_buffer(65536)
	_stdout.append_array(output)
	_stderr.append_array(errors)
	return not output.is_empty() or not errors.is_empty()


func _finish() -> void:
	var exit_code := OS.get_process_exit_code(process.pid)
	if exit_code != 0:
		fail("process_exit", "Analyzer exit %d: %s" % [
			exit_code, _stderr.get_string_from_utf8().left(2000)])
		return
	var parser := JSON.new()
	if parser.parse(_stdout.get_string_from_utf8()) != OK:
		fail("invalid_result", "Analyzer returned invalid JSON: " + parser.get_error_message())
		return
	var parsed: Variant = parser.data
	if not Result.is_valid(parsed):
		fail("invalid_result", "Analyzer returned no valid schema v1 JSON")
		return
	if parsed.asset.path.replace("\\", "/") != str(request.path).replace("\\", "/"):
		fail("invalid_result", "Analyzer returned another asset")
		return
	if parsed.asset.type != request.asset_type:
		fail("invalid_result", "Analyzer returned another asset type")
		return
	_terminal = parsed
	cleanup()


func fail(code: String, message: String) -> void:
	_terminal = Result.failure(request.path, request.asset_type, code, message)
	cleanup()


func cleanup() -> void:
	if not process.is_empty():
		if OS.is_process_running(process.pid):
			var kill_error := OS.kill(process.pid)
			if kill_error != OK:
				push_warning("Analyzer process %d could not be stopped: %s" % [process.pid, error_string(kill_error)])
		(process.stdio as FileAccess).close()
		(process.stderr as FileAccess).close()
		process.clear()
	for path: String in [request_path, request_path.get_basename() + ".cache.tmp"]:
		if FileAccess.file_exists(path):
			var remove_error := DirAccess.remove_absolute(path)
			if remove_error != OK:
				push_warning("Analyzer temporary file was not removed: %s (%s)" % [path, error_string(remove_error)])
