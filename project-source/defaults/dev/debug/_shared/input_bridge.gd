extends Node

var receive: Callable


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	# These developer shortcuts must precede focused text fields and popup GUI input.
	if receive.is_valid() and receive.call(event):
		get_viewport().set_input_as_handled()
