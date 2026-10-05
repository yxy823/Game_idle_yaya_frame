# GDScript Linter - Unused variable/parameter checker
# https://poplava.itch.io
class_name GDLintUnusedChecker
extends RefCounted

const SourceMap = preload("res://addons/gdscript-linter/analyzer/source-map.gd")

var config
var _declarations: Array = []


func _init(p_config) -> void:
	config = p_config


# Check for unused variables and parameters, calls add_issue_callback for each finding
func check_unused(lines: Array, add_issue_callback: Callable) -> void:
	if not config.check_unused_variables and not config.check_unused_parameters:
		return

	var code: Array = SourceMap.lex(lines).code
	for function in SourceMap.functions(lines):
		_declarations.clear()
		if config.check_unused_parameters:
			for name: String in function.parameter_names:
				if not (config.ignore_underscore_prefix and name.begins_with("_")):
					_declarations.append({"name": name, "line": function.line,
						"type": "parameter", "used": false})
		for i in range(function.signature_end, function.end_line):
			if config.check_unused_variables:
				_extract_variable_declaration(code[i], i + 1)
				_extract_for_loop_variable(code[i], i + 1)
		_find_scoped_usages(code, function.signature_end, function.end_line, function.inline_body)
		_report_unused(add_issue_callback)


func _find_scoped_usages(code: Array, start: int, end: int, inline_body: String = "") -> void:
	for declaration in _declarations:
		var usage := RegEx.new()
		usage.compile("\\b" + str(declaration.name) + "\\b")
		if usage.search(inline_body) != null:
			declaration.used = true
			continue
		for i in range(start, end):
			if i + 1 != declaration.line and usage.search(code[i]) != null:
				declaration.used = true
				break




func _extract_variable_declaration(line: String, line_num: int) -> void:
	# Skip @export variables (used by editor)
	if "@export" in line:
		return

	var var_regex := RegEx.new()
	var_regex.compile("^\\s*(?:@onready\\s+)?var\\s+(\\w+)")

	var match_result := var_regex.search(line)
	if match_result:
		var var_name := match_result.get_string(1)

		# Skip underscore-prefixed if configured
		if config.ignore_underscore_prefix and var_name.begins_with("_"):
			return

		_declarations.append({
			"name": var_name,
			"line": line_num,
			"type": "variable",
			"used": false
		})


func _extract_for_loop_variable(line: String, line_num: int) -> void:
	var for_regex := RegEx.new()
	for_regex.compile("^\\s*for\\s+(\\w+)(?:\\s*:\\s*[A-Za-z_]\\w*)?\\s+in\\s+")

	var match_result := for_regex.search(line)
	if match_result:
		var var_name := match_result.get_string(1)

		# Skip underscore-prefixed if configured
		if config.ignore_underscore_prefix and var_name.begins_with("_"):
			return

		_declarations.append({
			"name": var_name,
			"line": line_num,
			"type": "for_loop",
			"used": false
		})




func _report_unused(add_issue_callback: Callable) -> void:
	for decl in _declarations:
		if decl.used:
			continue

		var decl_type: String = decl.type
		var decl_name: String = decl.name
		var decl_line: int = decl.line

		match decl_type:
			"variable":
				if config.check_unused_variables:
					add_issue_callback.call(decl_line, "warning", "unused-variable",
						"Variable '%s' is declared but never used" % decl_name)
			"parameter":
				if config.check_unused_parameters:
					add_issue_callback.call(decl_line, "info", "unused-parameter",
						"Parameter '%s' is declared but never used" % decl_name)
			"for_loop":
				if config.check_unused_variables:
					add_issue_callback.call(decl_line, "warning", "unused-variable",
						"Loop variable '%s' is declared but never used" % decl_name)
