extends Node
## Owns background jobs for the external analyzer GAA, which summarizes audio files.
## Polls process completion and reads files without blocking the game on subprocess output.

const CONFIG := "res://docs/methodology-config.json"
const JOBS := "res://reports/debug-analysis"
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
	if not configured():
		return {"error": ERR_UNCONFIGURED, "message": backend.unconfigured,
			"detail": "%s: %s" % [backend.key, _executable()]}
	var file_name := Crypto.new().generate_random_bytes(16).hex_encode() + ".result.json"
	var job := {"backend": asset_type, "python": _executable(),
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
			continue
		_jobs.erase(job)
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


## Only a completed result with its payload counts; a failed one keeps the tool's error.
static func _state(data: Dictionary, job: Dictionary) -> Dictionary:
	var backend: Dictionary = BACKENDS[job.backend]
	if data.get("status") != "completed" or not data.get(backend.payload) is Dictionary:
		return {"status": "failed", "message": backend.name + " 未完成分析",
			"detail": JSON.stringify(data.get("error"))}
	return {"status": "success", "message": "", "data": data}
