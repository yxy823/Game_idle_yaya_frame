extends GdUnitTestSuite
## Session-owned import serialization uses an OS substitute; real import runs at finalization.

const Uids := preload("res://dev/debug/_shared/adoption_uids.gd")


func test_import_requests_merge_into_one_followup_without_overlap() -> void:
	var uids := _import_process_fake()
	assert_str(uids.refresh_cache("res://game/first")).is_empty()
	for index in 3:
		assert_str(uids.refresh_cache("res://game/next-%d" % index)).contains("随后更新")
	assert_int(uids.Processes.starts).is_equal(1)
	assert_str(uids.poll_refresh()).is_empty()
	uids.Processes.active = false
	assert_str(uids.poll_refresh()).is_empty()
	assert_int(uids.Processes.starts).is_equal(2)
	assert_bool(uids.Processes.overlapped).is_false()
	uids.Processes.active = false
	assert_str(uids.poll_refresh()).is_empty()
	assert_int(uids.Processes.starts).is_equal(2)


func test_import_start_failure_returns_a_message() -> void:
	var uids := _import_process_fake()
	uids.Processes.fail_start = true
	assert_str(uids.refresh_cache("res://game/moved")).contains("没能启动文件登记更新")
	assert_int(uids._import_pid).is_equal(-1)


func _import_process_fake() -> GDScript:
	var source: Script = Uids
	var script := GDScript.new()
	script.source_code = source.source_code.replace("OS.", "Processes.") + '''
class Processes:
	static var starts: int = 0
	static var active: bool = false
	static var overlapped: bool = false
	static var fail_start: bool = false
	static func execute(_program: String, _args: Array, _output: Array) -> int:
		return 0
	static func get_executable_path() -> String:
		return "godot.exe"
	static func is_process_running(_pid: int) -> bool:
		return active
	static func get_process_exit_code(_pid: int) -> int:
		return 0
	static func create_process(_program: String, _args: Array) -> int:
		starts += 1
		overlapped = overlapped or active
		active = not fail_start
		return -1 if fail_start else starts
'''
	assert_int(script.reload()).is_equal(OK)
	return script
