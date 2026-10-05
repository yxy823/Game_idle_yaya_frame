extends Node

signal completed(task_id: int, result: Dictionary)
signal state_changed(task_id: int, state: String)

const Job = preload("res://yaya/asset_workbench/ui/analysis_job.gd")
const Result = preload("res://yaya/asset_workbench/ui/analysis_result.gd")
const Source = preload("res://yaya/asset_workbench/ui/analysis_source.gd")
const Schema = preload("res://yaya/asset_workbench/ui/analysis_schema.gd")
const JOB_DIRECTORY: String = "res://reports/asset-analyzer/jobs"

var executable: String
var worker_path: String = "res://yaya/asset_workbench/analyzer/worker.py"
var timeout_seconds: float = 30.0
var max_concurrent: int = 2
var memory_budget_mib: int = -1  # Use the shared default after successful contract loading.
var _next_id: int = 0
var _queue: Array[int] = []
var _jobs: Dictionary[int, Job] = {}
var _running: Array[int] = []
var _prefix: String = "%s-%s" % [Time.get_ticks_usec(), randi()]


func _ready() -> void:
	if executable.is_empty():
		var config: Variant = JSON.parse_string(
			FileAccess.get_file_as_string("res://docs/methodology-config.json"))
		if config is Dictionary:
			executable = str(config.get("analyzer_python_executable", ""))


func submit(path: String, kind: String, parameters: Dictionary = {}, force: bool = false) -> int:
	_next_id += 1
	var job := Job.new()
	job.request = {"path": ProjectSettings.globalize_path(path), "asset_type": kind,
		"parameters": parameters, "force": force}
	job.request_path = ProjectSettings.globalize_path(JOB_DIRECTORY.path_join(
		"%s-%d.json" % [_prefix, _next_id]))
	job.timeout_seconds = timeout_seconds
	_jobs[_next_id] = job
	_queue.append(_next_id)
	state_changed.emit(_next_id, "queued")
	return _next_id


func cancel(task_id: int) -> void:
	if not _jobs.has(task_id):
		return
	var job: Job = _jobs[task_id]
	job.fail("cancelled", "Analysis cancelled")
	_deliver(task_id, job.poll())


func _process(_delta: float) -> void:
	for task_id: int in _running.duplicate():
		if not _jobs.has(task_id):
			continue  # A completion listener may cancel another task in this snapshot.
		var result: Dictionary = _jobs[task_id].poll()
		if not result.is_empty():
			_deliver(task_id, result)
	if not _queue.is_empty():
		var issue := _initialize_contracts()
		if not issue.is_empty():
			var task_id: int = _queue.front()
			_jobs[task_id].fail("analyzer_config", issue)
			_deliver(task_id, _jobs[task_id].poll())
			return
	while not _queue.is_empty() and _running.size() < clampi(max_concurrent, 1, 4):
		var cost := Source.memory_mib(_jobs[_queue.front()].request.asset_type)
		if not _running.is_empty() and reserved_memory_mib() + cost > memory_budget_mib:
			break
		_start_next()


func _initialize_contracts() -> String:
	var issue := Source.initialize()
	if issue.is_empty():
		issue = Schema.initialize()
	if issue.is_empty() and memory_budget_mib < 0:
		memory_budget_mib = int(Source.capabilities.pool_memory_mib)
	return issue


func reserved_memory_mib() -> int:
	var total: int = 0
	for task: int in _running:
		total += Source.memory_mib(_jobs[task].request.asset_type)
	return total


func _start_next() -> void:
	var task_id: int = _queue.pop_front()
	var job: Job = _jobs[task_id]
	var command := _executable_path()
	var issue := Source.path_issue(job.request.path, job.request.asset_type)
	if not issue.is_empty():
		job.fail(issue.code, issue.message)
	elif Source.memory_mib(job.request.asset_type) > memory_budget_mib:
		job.fail("memory_budget", "Task reservation exceeds the configured analysis pool budget.")
	elif command.is_empty() or (
			command.is_absolute_path() and not FileAccess.file_exists(command)):
		job.fail("process_missing",
			"Set analyzer_python_executable in docs/methodology-config.json to the Analyzer environment's Python")
	elif not FileAccess.file_exists(worker_path):
		job.fail("worker_missing", "Analyzer worker file is missing")
	elif DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(JOB_DIRECTORY)) != OK:
		job.fail("request_write", "Cannot create analysis job directory")
	else:
		job.start(command, ProjectSettings.globalize_path(worker_path))
	_running.append(task_id)
	state_changed.emit(task_id, "running")


func _executable_path() -> String:
	if executable.is_empty() or executable.is_absolute_path():
		return executable
	var local_path := ProjectSettings.globalize_path("res://".path_join(executable))
	var explicit_path := executable.contains("/") or executable.contains("\\") \
		or executable.contains(":")
	if FileAccess.file_exists(local_path) or explicit_path:
		return local_path
	# Only bare command names use the operating system's PATH lookup.
	return executable


func _deliver(task_id: int, data: Dictionary) -> void:
	_queue.erase(task_id)
	_running.erase(task_id)
	_jobs.erase(task_id)
	state_changed.emit(task_id, str(data.status))
	completed.emit(task_id, data)


func _exit_tree() -> void:
	for job: Job in _jobs.values():
		job.cleanup()
	_jobs.clear()
	_queue.clear()
	_running.clear()
