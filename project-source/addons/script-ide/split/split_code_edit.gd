## The CodeEdit that is used when the editor is split, to show the split script.
@tool
extends CodeEdit

var last_v_scroll: float

func _ready() -> void:
	editable = false
	caret_draw_when_editable_disabled = true
	set_v_scroll.call_deferred(last_v_scroll)

static func new_from(from_code_edit: CodeEdit) -> CodeEdit:
	var new_code_edit: CodeEdit = new()

	new_code_edit.text = from_code_edit.text
	# This read-only text snapshot needs its own highlighter, without the source TextEdit's lifetime.
	if from_code_edit.syntax_highlighter != null:
		new_code_edit.syntax_highlighter = SplitSyntaxHighlighter.new(from_code_edit)
	new_code_edit.highlight_all_occurrences = from_code_edit.highlight_all_occurrences
	new_code_edit.highlight_current_line = from_code_edit.highlight_current_line

	new_code_edit.use_default_word_separators = from_code_edit.use_default_word_separators
	new_code_edit.use_custom_word_separators = from_code_edit.use_custom_word_separators
	new_code_edit.custom_word_separators = from_code_edit.custom_word_separators

	new_code_edit.line_folding = from_code_edit.line_folding
	new_code_edit.line_length_guidelines = from_code_edit.line_length_guidelines

	new_code_edit.gutters_draw_line_numbers = from_code_edit.gutters_draw_line_numbers
	new_code_edit.gutters_draw_fold_gutter = from_code_edit.gutters_draw_fold_gutter

	new_code_edit.minimap_draw = from_code_edit.minimap_draw
	new_code_edit.minimap_width = from_code_edit.minimap_width

	new_code_edit.delimiter_strings = from_code_edit.delimiter_strings
	new_code_edit.delimiter_comments = from_code_edit.delimiter_comments

	new_code_edit.indent_automatic = from_code_edit.indent_automatic
	new_code_edit.indent_size = from_code_edit.indent_size
	new_code_edit.indent_use_spaces = from_code_edit.indent_use_spaces
	new_code_edit.indent_automatic_prefixes = from_code_edit.indent_automatic_prefixes

	new_code_edit.draw_control_chars = from_code_edit.draw_control_chars
	new_code_edit.draw_tabs = from_code_edit.draw_tabs
	new_code_edit.draw_spaces = from_code_edit.draw_spaces

	new_code_edit.last_v_scroll = from_code_edit.scroll_vertical

	return new_code_edit


class SplitSyntaxHighlighter extends SyntaxHighlighter:
	var line_highlighting: Array[Dictionary] = []

	func _init(source: CodeEdit) -> void:
		for line in range(source.get_line_count()):
			line_highlighting.append(source.syntax_highlighter.get_line_syntax_highlighting(line).duplicate(true))

	func _get_line_syntax_highlighting(line: int) -> Dictionary:
		return line_highlighting[line]
