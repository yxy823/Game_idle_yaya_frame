# 这是 GdUnit 生命周期扩展，不是 Codex 宿主的 PreToolUse/PostToolUse。
extends GdUnitTestSessionHook

## Observe diagnostic consumption without clearing or replacing GdUnit monitors.
const DiagnosticLogger = preload("res://tools/testing/gdunit_diagnostic_logger.gd")
const ASSERT_IMPLEMENTATION := "res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd"
const SCOPED_METHOD_KINDS: Dictionary[String, String] = {
	"is_push_error": "error", "is_push_warning": "warning", "is_runtime_error": "script_error",
}

var _logger: DiagnosticLogger
var _suite_context: GdUnitExecutionContext
var _case_context: GdUnitExecutionContext
var _suite_monitor: GodotGdErrorMonitor
var _suite_phase: String = "outside_suite"
var _records: Array[Dictionary] = []
var _expected_ids: Dictionary[int, bool] = {}


func _init() -> void:
	super("ProjectDiagnosticEvidence", "Invocation-local native and scoped diagnostic evidence")


# 只在本次 session 连接观察信号和 Logger，shutdown 对称释放这些连接。
func startup(session: GdUnitTestSession) -> GdUnitResult:
	var report_path := ProjectSettings.globalize_path(session.report_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(report_path)
	if directory_error != OK:
		return GdUnitResult.error("Cannot create diagnostic report directory: %s" % directory_error)
	_logger = DiagnosticLogger.new()
	var open_error := _logger.open_log(report_path.path_join("diagnostics.jsonl"))
	if open_error != OK:
		return GdUnitResult.error("Cannot open diagnostic evidence: %s" % open_error)
	_logger.write_event({
		"event": "session_start", "schema_version": 1,
		"report_path": report_path, "engine_pid": OS.get_process_id(),
	})
	_logger.diagnostic_recorded.connect(_on_diagnostic)
	session.test_event.connect(_on_test_event)
	GdUnitSignals.instance().gdunit_set_test_failed.connect(_on_assertion_result)
	OS.add_logger(_logger)
	return GdUnitResult.success()


# 上下文与 monitor 是借用引用；清空本地引用，不清除或替换 GdUnit 的错误记录。
func shutdown(session: GdUnitTestSession) -> GdUnitResult:
	if _logger == null:
		return GdUnitResult.error("Diagnostic evidence did not start")
	OS.remove_logger(_logger)
	if session.test_event.is_connected(_on_test_event):
		session.test_event.disconnect(_on_test_event)
	var assertion_signal := GdUnitSignals.instance().gdunit_set_test_failed
	if assertion_signal.is_connected(_on_assertion_result):
		assertion_signal.disconnect(_on_assertion_result)
	_logger.diagnostic_recorded.disconnect(_on_diagnostic)
	_logger.write_event({"event": "session_end"})
	_logger.close_log()
	_suite_context = null
	_case_context = null
	_suite_monitor = null
	if _logger.failed:
		return GdUnitResult.error("Diagnostic evidence write failed")
	return GdUnitResult.success()


func _on_test_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.TESTSUITE_BEFORE:
			_suite_context = _current_context()
			_case_context = null
			_suite_phase = "suite_before"
			# The public getter initializes the monitor before the user's before().
			# We never call start/stop/clear or replace the runner's monitor.
			_suite_monitor = _suite_context.error_monitor
		GdUnitEvent.TESTCASE_BEFORE:
			_case_context = _current_context()
			_suite_phase = "between_cases"
		GdUnitEvent.TESTCASE_AFTER:
			_case_context = null
			_suite_phase = "suite_after"
		GdUnitEvent.TESTSUITE_AFTER:
			_suite_context = null
			_case_context = null
			_suite_monitor = null
			_suite_phase = "outside_suite"


func _current_context() -> GdUnitExecutionContext:
	return GdUnitThreadManager.get_current_context().get_execution_context()


func _phase_for(context: GdUnitExecutionContext) -> String:
	if context == null:
		return "outside_suite"
	if context == _suite_context:
		return _suite_phase
	if _case_context == null:
		return "between_cases"
	var hook_context := _case_context.last_sub_context()
	if hook_context == null:
		return "case_start"
	var body_context := hook_context.last_sub_context()
	if context == hook_context:
		return "before_test" if body_context == null else "after_test"
	if context == body_context:
		return "test_body"
	return "case_transition"


func _on_diagnostic(record: Dictionary) -> void:
	var context := _current_context()
	record["epoch"] = context.get_instance_id() if context != null else 0
	record["phase"] = _phase_for(context)
	# Keep the same dictionary: the logger assigns its ID before returning from
	# the native callback, prior to any subsequent assertion success signal.
	_records.append(record)


func _on_assertion_result(failed: bool) -> void:
	var matched_kind := _scoped_success_kind()
	if failed or matched_kind.is_empty() or _suite_monitor == null:
		return
	var context := _current_context()
	if context == null:
		return
	var pending := _pending_in_scope(context)
	var counts: Dictionary[String, int] = {}
	for record: Dictionary in pending:
		var key := _record_key(record)
		counts[key] = counts.get(key, 0) + 1
	var remaining := _monitor_counts()
	# A successful scoped matcher removes exactly one type/message occurrence.
	# A body success must never authorize an earlier before_test clear.
	for record: Dictionary in pending:
		if record["kind"] != matched_kind:
			continue
		var key := _record_key(record)
		if counts[key] - remaining.get(key, 0) == 1:
			var identity: int = record["id"]
			_expected_ids[identity] = true
			_logger.write_event({"event": "expected", "id": identity})
			return


func _scoped_success_kind() -> String:
	var reported := false
	for frame: Dictionary in get_stack():
		if frame["source"] != ASSERT_IMPLEMENTATION:
			continue
		if frame["function"] == "_report_success":
			reported = true
		elif reported:
			# Only the immediate matcher consumes an entry. is_success() and
			# outer/nested assertions do not authorize diagnostic exemptions.
			return SCOPED_METHOD_KINDS.get(frame["function"], "")
	return ""


func _pending_in_scope(context: GdUnitExecutionContext) -> Array[Dictionary]:
	var pending: Array[Dictionary] = []
	var epoch := context.get_instance_id()
	var phase := _phase_for(context)
	for record: Dictionary in _records:
		if record["epoch"] != epoch or record["phase"] != phase:
			continue
		if not _expected_ids.has(record["id"]):
			pending.append(record)
	return pending


func _record_key(record: Dictionary) -> String:
	return JSON.stringify([record["kind"], record["monitor_message"]])


func _monitor_counts() -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for entry: ErrorLogEntry in _suite_monitor.log_entries():
		var kind := "script_error"
		if entry._type == ErrorLogEntry.TYPE.PUSH_ERROR:
			kind = "error"
		elif entry._type == ErrorLogEntry.TYPE.PUSH_WARNING:
			kind = "warning"
		var key := JSON.stringify([kind, entry._message])
		counts[key] = counts.get(key, 0) + 1
	return counts
