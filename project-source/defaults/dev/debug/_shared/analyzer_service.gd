extends Node
## Owns background jobs for the external analyzer GAA, which summarizes audio files.
## Polls process completion and reads files without blocking the game on subprocess output.

const CONFIG := "res://docs/methodology-config.json"
const JOBS := "res://reports/debug-analysis"
## Per asset type: tool name, config key, module entry, contract major version, result kind,
## the field that carries the payload, and the messages for no interpreter and no payload.
const BACKENDS := {
	"audio": {"name": "GAA", "key": "audio_analyzer_python_executable",
		"module": "game_audio_analyzer", "major": "2", "kind": "audio_summary",
		"payload": "metrics", "unconfigured": "未配置 GAA", "missing": "GAA 摘要缺少指标"},
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
	var run_id := "debug-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var job := {"backend": asset_type, "run_id": run_id, "python": _executable(),
		"output": JOBS.path_join(run_id) + ".result.json", "done": done}
	var error := DirAccess.make_dir_recursive_absolute(JOBS)
	if error != OK:
		return {"error": error, "message": "无法启动分析：分析任务目录或文件写不进去",
			"detail": JOBS}
	var arguments: PackedStringArray = ["-B", "-m", backend.module, "analyze",
		ProjectSettings.globalize_path(source), "--json-only",
		"--result-file", ProjectSettings.globalize_path(job.output),
		"--run-id", run_id, "--parent-pid", str(OS.get_process_id())]
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


## Checks contract major version, kind and run_id, then completion, before the payload.
static func _state(data: Dictionary, job: Dictionary) -> Dictionary:
	var backend: Dictionary = BACKENDS[job.backend]
	if str(data.get("contract_version", "")).get_slice(".", 0) != backend.major:
		return {"status": "failed", "message": backend.name + " 版本不兼容",
			"detail": "contract_version: " + str(data.get("contract_version"))}
	if data.get("kind") != backend.kind or data.get("run_id") != job.run_id:
		return {"status": "failed", "message": backend.name + " 结果与本次分析不符"}
	if data.get("status") != "completed" or data.get("exit_code") != 0:
		return {"status": "failed", "message": backend.name + " 未完成分析",
			"detail": "%s / %s\n%s" % [data.get("status"), data.get("exit_code"),
				JSON.stringify(data.get("error"))]}
	if not data.get(backend.payload) is Dictionary:
		return {"status": "failed", "message": backend.missing}
	return {"status": "success", "message": "", "data": data}
