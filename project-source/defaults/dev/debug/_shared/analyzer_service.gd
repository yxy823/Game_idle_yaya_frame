extends Node
## Owns background jobs for the external analyzer GAA, which summarizes audio files.
## Polls process completion and reads files without blocking the game on subprocess output.

const CONFIG := "res://docs/methodology-config.json"
const JOBS := "res://reports/debug-analysis"
## GAA allows 30 s probing and 120 s decoding; 150 s remains for startup and analysis.
const AUDIO_TIMEOUT_MSEC := 300_000
const STOP_TIMEOUT_MSEC := 5000
## Per asset type: tool name, config key, module entry, the field that carries the payload,
## and the message for no interpreter.
const BACKENDS := {
	"audio": {"name": "GAA", "key": "audio_analyzer_python_executable", "module": "gaa",
		"payload": "metrics", "unconfigured": "未配置 GAA"},
}

var audio_python: String = ""
## Replaceable in tests: (path, arguments, open_console) -> pid, and pid -> running.
var launch: Callable = OS.create_process
var running: Callable = OS.is_process_running
var _jobs: Array[Dictionary] = []


func _ready() -> void:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if config is Dictionary:
		audio_python = String(config.get(BACKENDS.audio.key, ""))


func _executable() -> String:
	return audio_python


func configured() -> bool:
	var path := _executable()
	return path.is_absolute_path() and FileAccess.file_exists(path)


## Calls done after exit with status success or failed; data keeps the tool's original fields.
func analyze(source: String, asset_type: String, done: Callable) -> Dictionary:
	var backend: Dictionary = BACKENDS[asset_type]
	for pending in _jobs:
		if pending.source == source and pending.timed_out:
			return {"error": ERR_BUSY, "message": "上次分析进程还未结束，请让 Agent 查看详情",
				"detail": "PID %d" % pending.pid}
	if not configured():
		return {"error": ERR_UNCONFIGURED, "message": backend.unconfigured,
			"detail": "%s: %s" % [backend.key, _executable()]}
	var file_name := Crypto.new().generate_random_bytes(16).hex_encode() + ".result.json"
	var job := {"backend": asset_type, "python": _executable(),
		"source": source, "started_ms": Time.get_ticks_msec(), "timed_out": false,
		"output": JOBS.path_join(file_name), "done": done}
	var arguments: PackedStringArray = ["-B", "-m", backend.module, "analyze",
		ProjectSettings.globalize_path(source),
		"--result-file", ProjectSettings.globalize_path(job.output)]
	job.pid = int(launch.call(job.python, arguments, false))
	if job.pid <= 0:
		return {"error": ERR_CANT_FORK, "message": "无法启动 " + backend.name,
			"detail": job.python}
	_jobs.append(job)
	return {"error": OK}


func _process(_delta: float) -> void:
	poll()


func poll() -> void:
	for job in _jobs.duplicate():
		if running.call(job.pid):
			_check_timeout(job)
			continue
		_jobs.erase(job)
		if job.timed_out:
			var removed := _remove_output(job)
			if removed != OK:
				push_error("Cannot remove analyzer result: " + job.output)
			continue
		var data: Variant = null
		if FileAccess.file_exists(job.output):
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(job.output)) == OK:
				data = json.data
			DirAccess.remove_absolute(job.output)
		if not data is Dictionary:
			job.done.call({"status": "failed",
				"message": "%s 已退出，但没有可读结果" % BACKENDS[job.backend].name,
				"detail": "%s\n%s" % [job.python, ProjectSettings.globalize_path(job.output)]})
			continue
		job.done.call(_state(data, job))


func _check_timeout(job: Dictionary) -> void:
	if job.timed_out or Time.get_ticks_msec() - job.started_ms < AUDIO_TIMEOUT_MSEC:
		return
	job.timed_out = true
	var stopped := _stop_owned_job(job)
	if not running.call(job.pid):
		_jobs.erase(job)
	job.done.call({"status": "failed", "message": "GAA 分析超过 300 秒，已停止等待",
		"detail": stopped.detail})


func _exit_tree() -> void:
	for job in _jobs:
		var stopped := _stop_owned_job(job)
		if stopped.error != OK:
			push_error(stopped.detail)
	_jobs.clear()


func _stop_owned_job(job: Dictionary) -> Dictionary:
	if running.call(job.pid):
		var output: Array = []
		var code := OS.execute("taskkill.exe", ["/PID", str(job.pid), "/T", "/F"], output, true)
		var deadline := Time.get_ticks_msec() + STOP_TIMEOUT_MSEC
		while running.call(job.pid) and Time.get_ticks_msec() < deadline:
			OS.delay_msec(10)
		# A job can exit between the first probe and taskkill (which then returns 128).
		# The owned process handle decides whether cleanup still needs intervention.
		if running.call(job.pid):
			return {"error": ERR_CANT_ACQUIRE_RESOURCE,
				"detail": "Cannot stop analyzer tree PID %d (taskkill %d): %s" % [job.pid, code, "".join(output)]}
	var error := _remove_output(job)
	return {"error": error, "detail": "" if error == OK else "Cannot remove analyzer result: " + job.output}


func _remove_output(job: Dictionary) -> Error:
	return DirAccess.remove_absolute(job.output) if FileAccess.file_exists(job.output) else OK


## Only a completed result with its payload counts; a failed one keeps the tool's error.
static func _state(data: Dictionary, job: Dictionary) -> Dictionary:
	var backend: Dictionary = BACKENDS[job.backend]
	if data.get("status") != "completed" or not data.get(backend.payload) is Dictionary:
		return {"status": "failed", "message": backend.name + " 未完成分析",
			"detail": JSON.stringify(data.get("error"))}
	return {"status": "success", "message": "", "data": data}
