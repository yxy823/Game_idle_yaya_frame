extends Node
## Owns background jobs for GAA audio summaries and the image Analyzer worker.
## Polls process completion and reads files without blocking the game on subprocess output.

const CONFIG := "res://docs/methodology-config.json"
const WORKER := "res://yaya/tools/analyzer/worker.py"
const JOBS := "res://reports/asset-analyzer/jobs/debug"

var python: String = ""
var audio_python: String = ""
## Replaceable in tests: (path, arguments, open_console) -> pid, and pid -> running.
var launch: Callable = OS.create_process
var running: Callable = OS.is_process_running
var _jobs: Array[Dictionary] = []


func _ready() -> void:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if config is Dictionary:
		python = String(config.get("analyzer_python_executable", ""))
		audio_python = String(config.get("audio_analyzer_python_executable", ""))


func configured(asset_type: String = "image") -> bool:
	if asset_type == "audio":
		return audio_python.is_absolute_path() and FileAccess.file_exists(audio_python)
	return not python.is_empty() and FileAccess.file_exists(python)


static func request(source: String, asset_type: String, modules: Array) -> Dictionary:
	return {"path": ProjectSettings.globalize_path(source), "asset_type": asset_type,
		"modules": modules, "parameters": {}, "force": false}


## Calls done after exit. The outer status is success/partial/failed; data keeps the
## backend's original fields. Audio ignores modules and uses the fixed GAA summary.
func analyze(source: String, asset_type: String, modules: Array, done: Callable) -> Dictionary:
	var audio := asset_type == "audio"
	var executable := audio_python if audio else python
	if not configured(asset_type):
		return {"error": ERR_UNCONFIGURED, "message": "未配置 GAA" if audio
			else "未配置 analyzer，分析不可用；其他功能照常",
			"detail": ("audio_analyzer_python_executable: " if audio
				else "analyzer_python_executable: ") + executable}
	var run_id := "debug-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var stem := JOBS.path_join(run_id)
	var job := {"backend": asset_type, "run_id": run_id, "python": executable,
		"output": stem + ".result.json", "done": done}
	var error := DirAccess.make_dir_recursive_absolute(JOBS)
	if error == OK and not audio:
		job.request = stem + ".request.json"
		error = _write_request(job.request, request(source, asset_type, modules))
	if error != OK:
		return {"error": error, "message": "无法启动分析：分析任务目录或文件写不进去",
			"detail": stem}
	job.pid = _launch_backend(source, job)
	if job.pid <= 0:
		_clean_job(job)
		return {"error": ERR_CANT_FORK,
			"message": "无法启动 GAA" if audio else "无法启动 analyzer",
			"detail": executable}
	_jobs.append(job)
	return {"error": OK}


static func _write_request(path: String, data: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.close()
	return OK


func _launch_backend(source: String, job: Dictionary) -> int:
	var arguments: PackedStringArray
	if job.backend == "audio":
		arguments = ["-B", "-m", "game_audio_analyzer", "analyze",
			ProjectSettings.globalize_path(source), "--json-only",
			"--result-file", ProjectSettings.globalize_path(job.output),
			"--run-id", job.run_id, "--parent-pid", str(OS.get_process_id())]
	else:
		arguments = ["-B", ProjectSettings.globalize_path(WORKER),
			"--request", ProjectSettings.globalize_path(job.request),
			"--output", ProjectSettings.globalize_path(job.output),
			"--parent-pid", str(OS.get_process_id())]
	return int(launch.call(job.python, arguments, false))


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
		_clean_job(job)
		if not data is Dictionary:
			job.done.call({"status": "failed", "message": "GAA 已退出，但没有可读结果"
				if job.backend == "audio" else "analyzer 已退出，但没有写出结果",
				"detail": "%s\n%s" % [job.python, ProjectSettings.globalize_path(job.output)]})
			continue
		job.done.call(_gaa_state(data, job) if job.backend == "audio" else _image_state(data))


static func _clean_job(job: Dictionary) -> void:
	for key: String in ["request", "output"]:
		if job.has(key) and FileAccess.file_exists(job[key]):
			DirAccess.remove_absolute(job[key])


static func _gaa_state(data: Dictionary, job: Dictionary) -> Dictionary:
	if str(data.get("contract_version", "")).get_slice(".", 0) != "2":
		return {"status": "failed", "message": "GAA 版本不兼容",
			"detail": "contract_version: " + str(data.get("contract_version"))}
	if data.get("kind") != "audio_summary" or data.get("run_id") != job.run_id:
		return {"status": "failed", "message": "GAA 结果与本次分析不符"}
	if data.get("status") != "completed" or data.get("exit_code") != 0:
		return {"status": "failed", "message": "GAA 未完成分析",
			"detail": "%s / %s\n%s" % [data.get("status"), data.get("exit_code"),
				JSON.stringify(data.get("error"))]}
	if not data.get("metrics") is Dictionary:
		return {"status": "failed", "message": "GAA 摘要缺少指标"}
	return {"status": "success", "message": "", "data": data}


static func _image_state(data: Dictionary) -> Dictionary:
	var messages: PackedStringArray = []
	for item: Dictionary in data.get("errors", []):
		messages.append("%s: %s" % [item.get("code", ""), item.get("message", "")])
	return {"status": String(data.get("status", "failed")),
		"message": "; ".join(messages), "detail": "; ".join(messages), "data": data}
