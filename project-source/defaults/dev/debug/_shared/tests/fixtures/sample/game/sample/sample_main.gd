extends Node
## The sample main scene starts its game after every child is ready, like a real main scene.


func _ready() -> void:
	($Game as Node).call("start")
