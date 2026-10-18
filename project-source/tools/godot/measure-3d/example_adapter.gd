extends RefCounted
## Example adapter for measure_3d.gd: three items on a row of square slots and one enemy, under an
## orthographic camera. Copy it to dev/asset_validation/<topic>/measure_adapter.gd and replace
## open() and subjects() with the project's scene, save fixture and nodes.

const SLOT_SIZE := 1.5
const ITEM_HEIGHTS: Array[float] = [0.8, 2.6, 0.8]


## Names of the variants to measure, for example one per model set.
func variants() -> Array[String]:
	return ["example"]


## Opens the scene for a variant and returns its root once it is ready to render.
func open(tree: SceneTree, _variant: String) -> Node:
	var scene := Node3D.new()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.position = Vector3(0.0, 6.0, 4.2)
	scene.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3.ZERO)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	scene.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	scene.add_child(light)
	for index in ITEM_HEIGHTS.size():
		var item := MeshInstance3D.new()
		item.name = "Item%d" % index
		var box := BoxMesh.new()
		box.size = Vector3(0.9, ITEM_HEIGHTS[index], 0.9)
		item.mesh = box
		item.position = Vector3(_slot_x(index), ITEM_HEIGHTS[index] / 2.0, 0.0)
		scene.add_child(item)
	var enemy := MeshInstance3D.new()
	enemy.name = "Enemy"
	enemy.mesh = CapsuleMesh.new()
	enemy.position = Vector3(0.0, 1.0, -3.0)
	scene.add_child(enemy)
	tree.root.add_child(scene)
	await tree.process_frame
	return scene


## The measured objects. Items carry the world corners of their slot's ground square and the ids
## of the items next to them; enemies only need id, kind and node.
func subjects(scene: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var half := SLOT_SIZE / 2.0
	for index in ITEM_HEIGHTS.size():
		var center := Vector3(_slot_x(index), 0.0, 0.0)
		var neighbors: Array[String] = []
		for other in [index - 1, index + 1]:
			if other >= 0 and other < ITEM_HEIGHTS.size():
				neighbors.append("item%d" % other)
		found.append({"id": "item%d" % index, "kind": "item", "node": scene.get_node("Item%d" % index),
			"slot_corners": [center + Vector3(-half, 0, -half), center + Vector3(half, 0, -half),
				center + Vector3(half, 0, half), center + Vector3(-half, 0, half)],
			"neighbors": neighbors})
	found.append({"id": "enemy", "kind": "enemy", "node": scene.get_node("Enemy")})
	return found


## Frees the scene and undoes anything open() changed outside it, such as a save path.
func close(scene: Node) -> void:
	scene.free()


static func _slot_x(index: int) -> float:
	return (index - (ITEM_HEIGHTS.size() - 1) / 2.0) * SLOT_SIZE
