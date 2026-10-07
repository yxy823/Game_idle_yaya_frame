extends Control

var value: Variant
var changed: Callable
var locked: bool = false


func bind(next: Variant, callback: Callable) -> void:
	changed = callback
	set_value(next)


func set_value(next: Variant) -> void:
	value = next


func set_locked(next: bool) -> void:
	locked = next
