# 保留 GdUnit 原有执行，只补充引擎进程内才能可靠取得的发现集合。
extends SceneTree

## GdUnit adapter: preserve its execution while recording actual expanded discovery.
var _cli_runner: GdUnitTestCIRunner


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	_cli_runner = EvidenceCli.new()
	root.add_child(_cli_runner)


func _finalize() -> void:
	queue_delete(_cli_runner)


class EvidenceCli extends GdUnitTestCIRunner:
	func get_cmdline_args() -> PackedStringArray:
		var arguments := super.get_cmdline_args()
		# gdUnit's public parser expects its original script-name delimiter.
		# Normalize only that delimiter; result.json keeps the actual command.
		for index in range(1, arguments.size()):
			if arguments[index - 1] in ["--script", "-s"]:
				if arguments[index].replace("\\", "/").get_file() == "gdunit_evidence_runner.gd":
					arguments[index] = "GdUnitCmdTool.gd"
					break
		return arguments


	# 记录 super 实际展开的参数化用例，不能把源码扫描结果冒充运行发现结果。
	func discover_tests() -> Array[GdUnitTestCase]:
		var discovered := super.discover_tests()
		var error := _write_discovery(discovered)
		if error != OK:
			push_error("Cannot persist actual test discovery: %s" % error)
		return discovered


	func _write_discovery(discovered: Array[GdUnitTestCase]) -> Error:
		var records: Array[Dictionary] = []
		for test: GdUnitTestCase in discovered:
			var path := test.source_file.trim_prefix("res://")
			records.append({
				"id": "%s::%s" % [path, test.display_name],
				"path": path, "case": test.display_name, "method": test.test_name,
			})
		return _write_json("discovery.json", {
			"schema_version": 1, "run_id": report_base_path.replace("\\", "/").trim_suffix("/").get_file(),
			"engine_pid": OS.get_process_id(), "cases": records,
		})


	func _write_json(filename: String, data: Dictionary) -> Error:
		var output := FileAccess.open(report_base_path.path_join(filename), FileAccess.WRITE)
		if output == null:
			return FileAccess.get_open_error()
		output.store_string(JSON.stringify(data, "\t", true) + "\n")
		output.flush()
		var error := output.get_error()
		output.close()
		return error
