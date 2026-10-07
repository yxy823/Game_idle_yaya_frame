extends Node2D
## A candidate effect still in dev/: its script names its parameter script by path, so
## adoption has to rewrite that path when the files move.

const Params := preload("res://dev/debug/_shared/tests/fixtures/sample/debug/sample/slots/feedback/effect/spark/spark_params.gd")
const LIFETIME := 0.3

var params: Params
var _age: float = 0.0


func play(effect_params: Resource) -> void:
	params = effect_params as Params


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
