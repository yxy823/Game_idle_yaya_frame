# GDScript Linter - Function analysis checker
# https://poplava.itch.io
class_name GDLintFunctionChecker
extends RefCounted

const SourceMap = preload("res://addons/gdscript-linter/analyzer/source-map.gd")

var config
var _naming_checker: GDLintNamingChecker


func _init(p_config, naming_checker: GDLintNamingChecker) -> void:
	config = p_config
	_naming_checker = naming_checker


# Analyzes all functions in a file and returns issues array
# Also populates file_result.functions with function metadata
func analyze_functions(lines: Array, file_result, add_issue_callback: Callable, add_pinned_issue_callback: Callable = Callable()) -> void:
	for function in SourceMap.functions(lines):
		var parameter_contract := _logger_parameter_contract(lines, function)
		if not parameter_contract.is_empty():
			function["parameter_contract"] = parameter_contract
		_finalize_function(function, function.body, file_result, add_issue_callback, add_pinned_issue_callback)


func _logger_parameter_contract(lines: Array, function: Dictionary) -> Dictionary:
	# Only this verified engine-owned callback has a fixed arity exception. Unknown
	# inheritance, nested classes and lookalike signatures retain normal checks.
	if function.name != "_log_error" or function.static or function.params != 8:
		return {}
	if SourceMap.indentation(lines[function.line - 1]) != 0 or function.return_type != "void":
		return {}
	var lexical := SourceMap.lex(lines)
	var direct_logger := false
	var extends_pattern := RegEx.new()
	extends_pattern.compile("^extends\\s+Logger\\s*$")
	for i in range(lines.size()):
		if not lexical.continued[i] and extends_pattern.search(lexical.code[i]) != null:
			direct_logger = true
	var version := Engine.get_version_info()
	if not direct_logger or version.major != 4 or version.minor != 7 or not ClassDB.class_exists("Logger"):
		return {}
	for method: Dictionary in ClassDB.class_get_method_list("Logger", true):
		if method.name != "_log_error" or not (method.flags & METHOD_FLAG_VIRTUAL):
			continue
		if method.args.size() != 8 or not method.default_args.is_empty() or method["return"].type != TYPE_NIL:
			return {}
		var types: Array[String] = []
		for argument: Dictionary in method.args:
			types.append(_engine_parameter_type(argument))
		if types == function.parameter_types:
			return {"owner": "Logger", "method": "_log_error", "authority": "ClassDB",
				"engine_version": version.string, "parameter_types": types,
				"return_type": "void", "metric": "too-many-params", "fixed_arity": 8}
	return {}


func _engine_parameter_type(argument: Dictionary) -> String:
	if argument.type == TYPE_ARRAY and argument.hint == PROPERTY_HINT_ARRAY_TYPE:
		return "Array[" + str(argument.hint_string) + "]"
	return type_string(argument.type)


func _finalize_function(func_data: Dictionary, body_lines: Array, file_result, add_issue_callback: Callable, add_pinned_issue_callback: Callable) -> void:
	var line_count: int = func_data[config.function_length_metric + "_lines"]
	var max_nesting := _calculate_max_nesting(func_data.nesting_body)
	var is_empty := _is_empty_function(body_lines)
	var complexity := _calculate_cyclomatic_complexity(body_lines)

	func_data["line_count"] = line_count
	func_data["max_nesting"] = max_nesting
	func_data["is_empty"] = is_empty
	func_data["complexity"] = complexity
	func_data["length_metric"] = config.function_length_metric
	func_data.erase("body")
	func_data.erase("nesting_body")
	func_data.erase("inline_body")
	file_result.add_function(func_data)

	_check_function_length(func_data, line_count, add_pinned_issue_callback)
	_check_parameter_count(func_data, add_pinned_issue_callback, add_issue_callback)
	_check_nesting_depth(func_data, max_nesting, add_pinned_issue_callback)
	_check_empty_function(func_data, is_empty, add_issue_callback)
	_check_complexity(func_data, complexity, add_pinned_issue_callback)
	_check_return_type(func_data, add_issue_callback)
	_check_naming(func_data, add_issue_callback)


func _check_function_length(func_data: Dictionary, line_count: int, add_pinned_callback: Callable) -> void:
	if not config.check_function_length:
		return
	var func_line: int = func_data.line
	var func_name: String = func_data.name
	var context := "Function '%s' (%s lines)" % [func_name, config.function_length_metric]
	if line_count > config.function_line_critical:
		add_pinned_callback.call(func_line, "critical", "long-function",
			"Function '%s' exceeds %d lines (%d)" % [func_name, config.function_line_critical, line_count],
			line_count, config.function_line_critical, context)
	elif line_count > config.function_line_limit:
		add_pinned_callback.call(func_line, "warning", "long-function",
			"Function '%s' exceeds %d lines (%d)" % [func_name, config.function_line_limit, line_count],
			line_count, config.function_line_limit, context)
	else:
		add_pinned_callback.call(func_line, "within-limit", "long-function", "",
			line_count, config.function_line_limit, context)


func _check_parameter_count(func_data: Dictionary, add_pinned_callback: Callable, add_issue_callback: Callable) -> void:
	if not config.check_parameters:
		return
	if func_data.has("parameter_contract"):
		if func_data.params > config.max_parameters:
			add_issue_callback.call(func_data.line, "info", "engine-parameter-contract",
				"Logger._log_error keeps %d engine-required parameters; ClassDB contract owns this arity (project max %d)" % [func_data.params, config.max_parameters])
		return
	var context := "Function '%s'" % func_data.name
	var severity := "warning" if func_data.params > config.max_parameters else "within-limit"
	add_pinned_callback.call(func_data.line, severity, "too-many-params",
		"Function '%s' has %d parameters (max %d)" % [func_data.name, func_data.params, config.max_parameters],
		func_data.params, config.max_parameters, context)


func _check_nesting_depth(func_data: Dictionary, max_nesting: int, add_pinned_callback: Callable) -> void:
	if not config.check_nesting:
		return
	var context := "Function '%s'" % func_data.name
	var severity := "warning" if max_nesting > config.max_nesting else "within-limit"
	add_pinned_callback.call(func_data.line, severity, "deep-nesting",
		"Function '%s' has %d nesting levels (max %d)" % [func_data.name, max_nesting, config.max_nesting],
		max_nesting, config.max_nesting, context)


func _check_empty_function(func_data: Dictionary, is_empty: bool, add_issue_callback: Callable) -> void:
	if not config.check_empty_functions or not is_empty:
		return
	add_issue_callback.call(func_data.line, "info", "empty-function",
		"Function '%s' is empty or contains only 'pass'" % func_data.name)


func _check_complexity(func_data: Dictionary, complexity: int, add_pinned_callback: Callable) -> void:
	if not config.check_cyclomatic_complexity:
		return
	var func_line: int = func_data.line
	var func_name: String = func_data.name
	var context := "Function '%s'" % func_name
	if complexity > config.cyclomatic_critical:
		add_pinned_callback.call(func_line, "critical", "high-complexity",
			"Function '%s' has complexity %d (max %d)" % [func_name, complexity, config.cyclomatic_critical],
			complexity, config.cyclomatic_critical, context)
	elif complexity > config.cyclomatic_warning:
		add_pinned_callback.call(func_line, "warning", "high-complexity",
			"Function '%s' has complexity %d (warning at %d)" % [func_name, complexity, config.cyclomatic_warning],
			complexity, config.cyclomatic_warning, context)
	else:
		add_pinned_callback.call(func_line, "within-limit", "high-complexity", "",
			complexity, config.cyclomatic_warning, context)


func _check_return_type(func_data: Dictionary, add_issue_callback: Callable) -> void:
	if not config.check_missing_return_type or func_data.has_return_type:
		return
	# Private methods are not automatically engine overrides.
	if func_data.name not in ["_init", "_ready", "_process", "_physics_process", "_input",
		"_unhandled_input", "_gui_input", "_notification", "_draw", "_enter_tree", "_exit_tree"]:
		add_issue_callback.call(func_data.line, "info", "missing-return-type",
			"Function '%s' has no return type annotation" % func_data.name)


func _check_naming(func_data: Dictionary, add_issue_callback: Callable) -> void:
	if not _naming_checker:
		return
	var naming_issue = _naming_checker.check_function_naming(func_data.name, func_data.line)
	if naming_issue:
		add_issue_callback.call(naming_issue.line, naming_issue.severity, naming_issue.check_id, naming_issue.message)


func _calculate_max_nesting(body_lines: Array) -> int:
	var max_indent := 0
	var base_indent := -1

	for line in body_lines:
		if line.strip_edges() == "":
			continue

		var indent := _get_indent_level(line)
		if base_indent < 0:
			base_indent = indent

		var relative_indent := indent - base_indent
		if relative_indent > max_indent:
			max_indent = relative_indent

	return max_indent


func _is_empty_function(body_lines: Array) -> bool:
	for line in body_lines:
		var trimmed: String = line.strip_edges()
		if trimmed != "" and trimmed != "pass":
			return false
	return true


func _get_indent_level(line: String) -> int:
	var spaces := 0
	for c in line:
		if c == '\t':
			spaces += 4
		elif c == ' ':
			spaces += 1
		else:
			break
	return spaces / 4


# gdlint:ignore-next-line:high-complexity - Complexity calculation is naturally complex
func _calculate_cyclomatic_complexity(body_lines: Array) -> int:
	var complexity := 1  # Base complexity
	var decisions := RegEx.new()
	decisions.compile("\\b(if|elif|for|while|match|and|or)\\b|&&|\\|\\|")
	for line in body_lines:
		complexity += decisions.search_all(line).size()
	return complexity
