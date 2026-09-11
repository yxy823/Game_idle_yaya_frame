# 保留 GdUnit 原有执行，只补充引擎进程内才能可靠取得的发现集合与本次收据。
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
		# Normalize only that delimiter; invocation.json keeps the actual command.
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


	func quit(code: int) -> void:
		# Reporters and diagnostic hooks have completed before the runner quits.
		# Seal their exact bytes in the engine process; filesystem clocks are not provenance.
		if FileAccess.file_exists(report_base_path.path_join("discovery.json")):
			var error := _write_session_receipt(code)
			if error != OK:
				push_error("Cannot persist actual session receipt: %s" % error)
				code = RETURN_ERROR
		await super(code)


	# 收据绑定本次 invocation 和报告字节，时间戳不承担证明新鲜度的职责。
	func _write_session_receipt(code: int) -> Error:
		var reports: Array[String] = []
		for directory: String in DirAccess.get_directories_at(report_base_path):
			var relative := directory.path_join("results.xml")
			if FileAccess.file_exists(report_base_path.path_join(relative)):
				reports.append(relative)
		if reports.size() != 1:
			return ERR_FILE_NOT_FOUND
		var paths: Dictionary[String, String] = {"junit": reports[0], "discovery": "discovery.json",
			"diagnostics": reports[0].get_base_dir().path_join("diagnostics.jsonl")}
		var artifacts: Dictionary = {}
		for artifact_name: String in paths:
			var digest := FileAccess.get_sha256(report_base_path.path_join(paths[artifact_name]))
			if digest.is_empty():
				return ERR_FILE_CANT_READ
			artifacts[artifact_name] = {"path": paths[artifact_name], "sha256": "sha256:" + digest}
		var invocation_path := report_base_path.path_join("invocation.json")
		var invocation: Variant = JSON.parse_string(FileAccess.get_file_as_string(invocation_path))
		if not invocation is Dictionary or not invocation.get("run_id") is String:
			return ERR_INVALID_DATA
		var invocation_hash := FileAccess.get_sha256(invocation_path)
		if invocation_hash.is_empty():
			return ERR_FILE_CANT_READ
		return _write_json("session-receipt.json", {
			"schema_version": 1, "run_id": invocation["run_id"],
			"engine_pid": OS.get_process_id(), "exit_code": code, "artifacts": artifacts,
			"invocation_sha256": "sha256:" + invocation_hash,
		})


	func _write_discovery(discovered: Array[GdUnitTestCase]) -> Error:
		var records: Array[Dictionary] = []
		for test: GdUnitTestCase in discovered:
			var path := test.source_file.trim_prefix("res://")
			records.append({
				"id": "%s::%s" % [path, test.display_name],
				"path": path, "case": test.display_name, "method": test.test_name,
			})
		return _write_json("discovery.json", {
			"schema_version": 1, "engine_pid": OS.get_process_id(), "cases": records,
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
