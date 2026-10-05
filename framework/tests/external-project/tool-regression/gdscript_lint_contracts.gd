# 中立 lint 契约在实际生成项目内执行；字符串夹具故意包含超限或错误结构。
extends SceneTree
## Engine-executed contracts inside the actual generated validation project.

const Analyzer = preload("res://addons/gdscript-linter/analyzer/code-analyzer.gd")
const Config = preload("res://addons/gdscript-linter/analyzer/analysis-config.gd")
const Result = preload("res://addons/gdscript-linter/analyzer/analysis-result.gd")
const Strict = preload("res://addons/gdscript-linter/analyzer/strict-handler.gd")
const Ignore = preload("res://addons/gdscript-linter/analyzer/ignore-handler.gd")

var _failures: Array[String] = []
var _checks: int = 0
var _engine_contract: Dictionary = {}


# 汇总真实分析结果并以退出码报告；不能为得到通过而修改夹具的度量边界。
func _initialize() -> void:
	_declaration_matrix()
	_metrics_and_boundaries()
	_signatures_and_complexity()
	_directive_scopes()
	_unused_scopes()
	_logger_callback_contract()
	_magic_number_boundaries()
	var output := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": _checks, "failures": _failures,
		"engine": Engine.get_version_info(), "logger_contract": _engine_contract}, "  "))
	output.close()
	quit(0 if _failures.is_empty() else 1)


func _analyze(source: String, code_metric: bool = false) -> Dictionary:
	var config := Config.new()
	config.function_line_limit = 2
	config.function_line_critical = 5
	config.max_parameters = 2
	if code_metric and config.get("function_length_metric") != null:
		config.set("function_length_metric", "code")
		config.set("file_length_metric", "code")
	var analyzer := Analyzer.new(config)
	analyzer.result = Result.new()
	var file: GDLintFileResult = analyzer.analyze_content(source, "res://fixture.gd")
	return {"file": file.to_dict(), "functions": file.functions,
		"issues": analyzer.result.to_dict().issues}


func _expect(value: bool, description: String) -> void:
	_checks += 1
	if not value:
		_failures.append(description)


func _declaration_matrix() -> void:
	for prefix: String in ["func ", "static func "]:
		for name: String in ["sample", "_sample"]:
			for multiline: bool in [false, true]:
				_check_declaration(prefix, name, multiline)


func _check_declaration(prefix: String, name: String, multiline: bool) -> void:
	var signature := "(\n\tvalue: int\n)" if multiline else "(value: int)"
	var report := _analyze(prefix + name + signature + " -> int:\n\treturn value\n")
	var label := prefix + name + str(multiline)
	_expect(report.functions.size() == 1, label + " discovered")
	if report.functions.size() != 1:
		return
	var function: Dictionary = report.functions[0]
	_expect(function.name == name, label + " name")
	_expect(function.params == 1, label + " params")
	_expect(function.has_return_type, label + " return type")
	_expect(function.line_count == (4 if multiline else 2), label + " length")
	_expect(_count(report, "long-function") == (1 if multiline else 0), label + " threshold")


func _metrics_and_boundaries() -> void:
	var source := "# explanation\n\nfunc first() -> void:\n\t# required comment\n\tpass\n"
	var base := _analyze(source)
	_expect(base.file.get("physical_lines", -1) == 5, "physical EOF excludes phantom line")
	_expect(base.file.get("code_lines", -1) == 2, "code excludes blank and comment")
	_expect(base.functions[0].line_count == 3, "physical function includes body comment")
	_expect(_analyze(source, true).functions[0].line_count == 2, "explicit code metric")
	_expect(_analyze(source.replace("\n", "\r\n")).file == base.file, "CRLF parity")
	_expect(_analyze(source.trim_suffix("\n")).file == base.file, "EOF newline parity")
	var appended := _analyze(source + "\n# next documentation\nstatic func last() -> void:\n\tpass\n")
	_expect(appended.functions.size() == 2, "normal followed by static separated")
	_expect(appended.functions[0].line_count == 3, "next function docs excluded")
	var member := _analyze("func tiny() -> void:\n\tpass\n\nconst OTHER = 2\n")
	_expect(member.functions[0].line_count == 2, "dedented member excluded")
	_expect(_analyze("").file.get("physical_lines", -1) == 0, "empty file physical")
	var private_report := _analyze("func _private():\n\tpass\n")
	_expect(_count(private_report, "missing-return-type") == 1, "private requires return type")


func _signatures_and_complexity() -> void:
	var source := "static func sample(\n\tdata: Dictionary[String, int],\n"
	source += "\tpoint: Vector2 = Vector2(1, 2),\n\ttext: String = \"x,y)#\"\n) -> int:\n"
	source += "\treturn data.size() if point.x > 0 and text != \"if or for\" else 0\n"
	var report := _analyze(source)
	_expect(report.functions.size() == 1, "nested defaults static discovered")
	if report.functions.size() == 1:
		_expect(report.functions[0].params == 3, "nested commas not parameter separators")
		_expect(report.functions[0].complexity == 3, "ternary counted once; strings excluded")
		_expect(report.functions[0].max_nesting == 0, "signature is not nesting")
	var text := "func text() -> String:\n\treturn \"\"\"\nfunc fake():\n"
	text += "static func fake_too():\n\"\"\"\n"
	var text_report := _analyze(text)
	_expect(text_report.functions.size() == 1, "multiline string cannot declare functions")
	_expect(text_report.functions[0].line_count == 5, "dedented multiline string stays in function")
	var nested := _analyze("class Inner:\n\tstatic func nested() -> int:\n\t\treturn 0\n")
	_expect(nested.functions.size() == 1, "inner class static method discovered")


func _directive_scopes() -> void:
	var lines: Array = ["# gdlint:strict-function:long-function=1", "static func first():",
		"\tpass", "", "func second():", "\tpass"]
	var strict := Strict.new()
	strict.initialize(lines)
	_expect(strict.get_strict_limit(2, "long-function") == 1, "strict attaches static")
	_expect(strict.get_strict_limit(5, "long-function") == -1, "strict does not leak")
	lines[0] = "# gdlint:ignore-function:long-function"
	var ignored := Ignore.new()
	ignored.initialize(lines)
	_expect(ignored.should_ignore(2, "long-function"), "ignore attaches static")
	_expect(not ignored.should_ignore(5, "long-function"), "ignore does not leak")
	var source := "# gdlint:strict-function:long-function=1\nstatic func one() -> void:\n\tpass\n"
	var enforced := _analyze(source)
	_expect(_count(enforced, "strict-limit") == 1, "strict enforced below normal global threshold")


func _unused_scopes() -> void:
	var source := "static func first(\n\tunused_arg: int\n) -> void:\n\tvar local = 1\n\tpass\n"
	source += "func second(unused_arg: int) -> int:\n\treturn unused_arg\n"
	var report := _analyze(source)
	_expect(_count(report, "unused-parameter") == 1, "multiline static parameter checked in own scope")
	_expect(_count(report, "unused-variable") == 1, "static local checked")
	var code := "static func words(value: int) -> String:\n\treturn \"value\" # value\n"
	_expect(_count(_analyze(code), "unused-parameter") == 1, "comments and strings are not usages")
	var one_line := _analyze("func choose(flag: bool) -> int: return 3 if flag else 4\n")
	_expect(_count(one_line, "unused-parameter") == 0, "one-line body uses its parameter")
	if one_line.functions.size() == 1:
		_expect(one_line.functions[0].complexity == 2, "one-line body counts its ternary")
		_expect(not one_line.functions[0].has("inline_body"), "inline body is not exported")


# Exercise the analyzer path, including its existing multiline lexer.
func _magic_number_boundaries() -> void:
	for source: String in [
		"func get_sha256() -> int:\n\treturn 0\n",
		"var digest256 = get_sha256()\n",
		"var name = \"invocation_sha256\"\n",
		"var name = 'checksum 256' # count 37\n",
		"var text = \"\"\"first 256\nsecond 37\n\"\"\"\n",
		"var text = \"escaped \\\"256\\\" value\"\n",
		"const SIZE = 256\n",
		"var value = 0\n"]:
		_expect(_count(_analyze(source), "magic-number") == 0, "nonliteral/allowed number: " + source)
	for value: String in ["256", "37.5", "-37"]:
		var report := _analyze("func sample() -> float:\n\treturn " + value + "\n")
		_expect(_count(report, "magic-number") == 1, "real numeric literal remains checked: " + value)
		for issue: Dictionary in report.issues:
			if issue.check_id == "magic-number":
				_expect(issue.line == 2 and value in issue.message, "numeric diagnostic keeps value and line")


func _count(report: Dictionary, check_id: String) -> int:
	var count := 0
	for issue: Dictionary in report.issues:
		if issue.check_id == check_id:
			count += 1
	return count


func _logger_callback_contract() -> void:
	for method: Dictionary in ClassDB.class_get_method_list("Logger", true):
		if method.name == "_log_error":
			_engine_contract = method
	_expect(not _engine_contract.is_empty(), "target engine exposes Logger._log_error")
	if _engine_contract.is_empty():
		return
	_expect(_engine_contract.args.size() == 8, "target Logger callback has eight arguments")
	_expect((_engine_contract.flags & METHOD_FLAG_VIRTUAL) != 0, "Logger callback is virtual")
	_expect(_engine_contract["return"].type == TYPE_NIL, "Logger callback returns void")
	_expect(_engine_contract.args[-1].hint_string == "ScriptBacktrace",
		"Logger callback retains typed ScriptBacktrace array")
	var source := "extends Logger\n\n" + _logger_method()
	var native_script := GDScript.new()
	native_script.source_code = source
	_expect(native_script.reload() == OK, "target compiler accepts the fixed Logger signature")
	var valid := _analyze(source)
	_expect(_count(valid, "too-many-params") == 0, "native Logger signature owns arity")
	_expect(valid.functions[0].params == 8, "Logger physical parameter metric remains eight")
	_expect(not valid.functions[0].get("parameter_contract", {}).is_empty(),
		"Logger arity treatment has traceable engine contract")
	_expect(_count(valid, "engine-parameter-contract") == 1, "Logger arity emits explanatory Info")
	_expect(_count(valid, "long-function") == 1, "Logger exemption does not hide length")
	var documented := source.replace("extends Logger", "extends  Logger # engine interface")
	_expect(_count(_analyze(documented), "too-many-params") == 0,
		"inheritance whitespace and comments retain native identity")
	for candidate: String in [source.replace("extends Logger", "extends RefCounted"),
		source.replace("_log_error", "ordinary"), source.replace("func ", "static func "),
		source.replace("line: int", "line: String"), source.replace("-> void", "-> int"),
		source.replace("Array[ScriptBacktrace]", "Array[Resource]"),
		source.replace("_editor_notify: bool", "_editor_notify")]:
		_expect(_count(_analyze(candidate), "too-many-params") == 1,
			"ordinary or mismatched eight-parameter method stays checked")
	var inner := "extends Logger\nclass Inner extends RefCounted:\n"
	inner += "\t" + _logger_method().replace("\n", "\n\t")
	_expect(_count(_analyze(inner), "too-many-params") == 1,
		"outer Logger inheritance does not exempt unrelated inner class")


func _logger_method() -> String:
	return "func _log_error(\n\tfunction: String,\n\tfile: String,\n\tline: int,\n" \
		+ "\tmessage: String,\n\trationale: String,\n\t_editor_notify: bool,\n" \
		+ "\terror_type: int,\n\t_script_backtraces: Array[ScriptBacktrace]\n) -> void:\n\tpass\n"
