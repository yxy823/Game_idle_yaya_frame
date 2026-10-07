extends Resource
## Sample tuning resource: the effect a button shows, a scene candidate with its parameters.

@export var candidate: PackedScene:
	set(value):
		candidate = value
		emit_changed()
@export var candidate_params: Resource:
	set(value):
		if candidate_params != null:
			candidate_params.changed.disconnect(emit_changed)
		candidate_params = value
		if candidate_params != null:
			candidate_params.changed.connect(emit_changed)
		emit_changed()
