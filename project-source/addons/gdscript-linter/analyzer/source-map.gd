# Yaya-owned integration patch; see ../YAYA_PATCH.md. Upstream remains MIT.
extends RefCounted
## Lexical source positions shared by metrics, strict/ignore scopes and unused checks.
## This is a source metric scanner, not a replacement for the Godot parser.


static func source_lines(content: String) -> Array[String]:
	var lines: Array[String] = []
	if content.is_empty():
		return lines
	lines.assign(content.replace("\r\n", "\n").split("\n"))
	if lines[-1].is_empty():
		lines.pop_back()
	return lines


static func lex(lines: Array) -> Dictionary:
	var masked: Array[String] = []
	var continued: Array[bool] = []
	var quote := ""
	var depth := 0
	var escaped := false
	var continuation := false
	for raw: String in lines:
		continued.append(not quote.is_empty() or depth > 0 or continuation)
		var code := ""
		var i := 0
		while i < raw.length():
			var character := raw[i]
			if not quote.is_empty():
				if not escaped and raw.substr(i, quote.length()) == quote:
					code += "~".repeat(quote.length())
					i += quote.length()
					quote = ""
					continue
				code += "~" if character not in [" ", "\t"] else character
				escaped = character == "\\" and not escaped
			elif character == "#":
				break
			elif character in ["\"", "'"]:
				quote = character.repeat(3) if raw.substr(i, 3) == character.repeat(3) else character
				code += "~".repeat(quote.length())
				i += quote.length()
				escaped = false
				continue
			else:
				code += character
				if character in ["(", "[", "{"]:
					depth += 1
				elif character in [")", "]", "}"]:
					depth -= 1
			i += 1
		masked.append(code)
		continuation = quote.is_empty() and code.strip_edges().ends_with("\\")
		escaped = false
	return {"code": masked, "continued": continued}


static func functions(lines: Array) -> Array[Dictionary]:
	var lexical := lex(lines)
	var code: Array = lexical.code
	var declarations: Array[Dictionary] = []
	var pattern := RegEx.new()
	pattern.compile("^\\s*(static\\s+)?func\\s+([A-Za-z_]\\w*)\\s*\\(")
	for i in range(code.size()):
		if lexical.continued[i]:
			continue
		var found := pattern.search(code[i])
		if found == null:
			continue
		var signature := _signature(code, i)
		var ending: int = signature.end
		var base := indentation(lines[i])
		for j in range(ending + 1, lines.size()):
			if not code[j].strip_edges().is_empty():
				if not lexical.continued[j] and indentation(lines[j]) <= base:
					break
				ending = j
			elif not str(lines[j]).strip_edges().is_empty() and indentation(lines[j]) > base:
				ending = j
		var body: Array[String] = []
		var nesting_body: Array[String] = []
		if not str(signature.inline).is_empty():
			body.append(signature.inline)
		for j in range(signature.end + 1, ending + 1):
			# Continued expressions and string payload indentation are not control nesting.
			body.append(code[j])
			nesting_body.append("" if lexical.continued[j] else code[j])
		declarations.append({
			"name": found.get_string(2), "line": i + 1, "end_line": ending + 1,
			"signature_end": signature.end + 1, "static": not found.get_string(1).is_empty(),
			"params": signature.parameters.size(), "parameter_names": signature.parameters,
			"parameter_types": signature.parameter_types, "return_type": signature.return_type,
			"has_return_type": signature.has_return_type, "body": body, "nesting_body": nesting_body,
			"inline_body": signature.inline,
			"physical_lines": ending - i + 1, "code_lines": count_code(code.slice(i, ending + 1))
		})
	return declarations


static func range_after(lines: Array, directive_index: int) -> Dictionary:
	var lexical := lex(lines)
	var next_code := directive_index + 1
	while next_code < lines.size() and str(lexical.code[next_code]).strip_edges().is_empty():
		next_code += 1
	for declaration in functions(lines):
		if declaration.line == next_code + 1:
			return {"start": declaration.line, "end": declaration.end_line}
	return {"start": -1, "end": -1}


static func count_code(lines: Array) -> int:
	var count := 0
	for line: String in lines:
		if not line.strip_edges().is_empty():
			count += 1
	return count


static func indentation(line: String) -> int:
	var count := 0
	for character in line:
		if character == "\t":
			count += 4
		elif character == " ":
			count += 1
		else:
			break
	return count


static func _signature(code: Array, start: int) -> Dictionary:
	var depth := 0
	var current := ""
	var parameters: Array[String] = []
	var parameter_types: Array[String] = []
	for i in range(start, code.size()):
		var line: String = code[i]
		var offset := line.find("(") if i == start else 0
		for j in range(offset, line.length()):
			var character := line[j]
			if character in ["(", "[", "{"]:
				depth += 1
				if depth == 1:
					continue
			elif character in [")", "]", "}"]:
				depth -= 1
				if depth == 0:
					_append_parameter(parameters, parameter_types, current)
					var tail := line.substr(j + 1).strip_edges()
					var return_type := tail.trim_prefix("->").split(":")[0].strip_edges() if tail.begins_with("->") else ""
					# Code after the signature colon is the body of a one-line function.
					var colon := tail.find(":")
					var inline := tail.substr(colon + 1).strip_edges() if colon >= 0 else ""
					return {"end": i, "parameters": parameters, "parameter_types": parameter_types,
						"has_return_type": "->" in tail, "return_type": return_type, "inline": inline}
			if character == "," and depth == 1:
				_append_parameter(parameters, parameter_types, current)
				current = ""
			else:
				current += character
		current += " "
	# Invalid syntax is rejected by the native parser; retain a bounded diagnostic model.
	return {"end": start, "parameters": [], "parameter_types": [], "has_return_type": false, "return_type": "",
		"inline": ""}


static func _append_parameter(parameters: Array[String], types: Array[String], text: String) -> void:
	var name := text.split(":")[0].split("=")[0].strip_edges()
	if not name.is_empty():
		parameters.append(name)
		var declaration := text.split("=", true, 1)[0].split(":", true, 1)
		var annotation := declaration[1] if declaration.size() == 2 else ""
		types.append(annotation.replace(" ", "").replace("\t", ""))
