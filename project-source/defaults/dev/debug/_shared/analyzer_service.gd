extends Node
## Runs one analyzer worker per request in the background and polls for its exit.
## Results stay in files; the worker never writes to a pipe the game would have to drain.

const CONFIG := "res://docs/methodology-config.json"
const WORKER := "res://yaya/tools/analyzer/worker.py"
const JOBS := "res://reports/asset-analyzer/jobs/debug"

var python: String = ""
## Replaceable in tests: (path, arguments, open_console) -> pid, and pid -> running.
var launch: Callable = OS.create_process
var running: Callable = OS.is_process_running
var _jobs: Array[Dictionary] = []


func _ready() -> void:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if config is Dictionary:
		python = String(config.get("analyzer_python_executable", ""))


func configured() -> bool:
	return not python.is_empty() and FileAccess.file_exists(python)


static func request(source: String, asset_type: String, modules: Array) -> Dictionary:
	return {"path": ProjectSettings.globalize_path(source), "asset_type": asset_type,
		"modules": modules, "parameters": {}, "force": false}


## Calls done with {"status", "message", "data"} after the worker exits; the status is
## the result's own success, partial or failed, or failed when no result file appeared.
func analyze(source: String, asset_type: String, modules: Array, done: Callable) -> Dictionary:
	if not configured():
		return {"error": ERR_UNCONFIGURED, "message": "未配置 analyzer，分析不可用；其他功能照常",
			"detail": "analyzer_python_executable: " + python}
	var stem := JOBS.path_join("%s-%d" % [source.get_file().get_basename(), Time.get_ticks_usec()])
	var job := {"request": stem + ".request.json", "output": stem + ".result.json", "done": done}
	var error := DirAccess.make_dir_recursive_absolute(JOBS)
	var file := FileAccess.open(job.request, FileAccess.WRITE) if error == OK else null
	if file == null:
		return {"error": FileAccess.get_open_error() if error == OK else error,
			"message": "无法启动 analyzer：分析任务文件写不进去。关掉占用 reports 文件夹的程序后再试",
			"detail": job.request}
	file.store_string(JSON.stringify(request(source, asset_type, modules)))
	file.close()
	var arguments: PackedStringArray = ["-B", ProjectSettings.globalize_path(WORKER),
		"--request", ProjectSettings.globalize_path(job.request),
		"--output", ProjectSettings.globalize_path(job.output),
		"--parent-pid", str(OS.get_process_id())]
	job.pid = launch.call(python, arguments, false)
	if job.pid <= 0:
		DirAccess.remove_absolute(job.request)
		return {"error": ERR_CANT_FORK, "message": "无法启动 analyzer：它的 Python 打不开。请让 Agent 检查环境配置",
			"detail": python}
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
			data = JSON.parse_string(FileAccess.get_file_as_string(job.output))
			DirAccess.remove_absolute(job.output)
		DirAccess.remove_absolute(job.request)
		if not data is Dictionary:
			job.done.call({"status": "failed", "message": "analyzer 已退出，但没有写出结果",
				"detail": job.output})
			continue
		var messages: PackedStringArray = []
		for item: Dictionary in data.get("errors", []):
			messages.append("%s: %s" % [item.get("code", ""), item.get("message", "")])
		job.done.call({"status": String(data.get("status", "failed")),
			"message": "; ".join(messages), "detail": "; ".join(messages), "data": data})
