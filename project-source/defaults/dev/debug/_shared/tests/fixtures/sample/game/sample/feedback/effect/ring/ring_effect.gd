extends Node2D
## The game's ring effect: shows for LIFETIME seconds at its parameters' size, then frees itself.

const LIFETIME := 0.4

var params: Resource
var _age: float = 0.0


func play(effect_params: Resource) -> void:
	params = effect_params
	scale = Vector2.ONE * params.size / 100.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
