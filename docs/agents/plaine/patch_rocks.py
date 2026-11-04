"""Collisions des rochers calées sur leur maillage, rochers des remparts solides, MultiMesh nommés (plaine_scatter.gd)."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def swap(old, new):
    global text
    assert old in text, old[:90]
    text = text.replace(old, new, 1)


swap("""		_add_chunked_multimesh(mesh, burnt, soot)
		_add_chunked_multimesh(mesh, glowing, rust)""", """		_add_chunked_multimesh(mesh, burnt, soot, "Grass")
		_add_chunked_multimesh(mesh, glowing, rust, "Grass")""")

swap("""		var mesh := _load_mesh(model)
		var size := mesh.get_aabb().size
		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(0.3), _rng.randf_range(1.5, 4.0))
			items.append(item)
			# Les cailloux assez hauts pour gêner le pas ont une collision à leur taille ; les plus plats se franchissent.
			var real := size * item.basis.get_scale()
			if real.y < 0.25:
				continue
			var shape := BoxShape3D.new()
			shape.size = real * 0.85
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.transform = Transform3D(item.basis.orthonormalized(), item.origin + Vector3.UP * shape.size.y * 0.5)
			body.add_child(collision)
		_add_chunked_multimesh(_load_mesh(model), items, material)""", """		var mesh := _load_mesh(model)
		var size := mesh.get_aabb().size
		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(0.3), _rng.randf_range(1.5, 4.0))
			items.append(item)
			# Les cailloux assez hauts pour gêner le pas ont une collision à leur taille ; les plus plats se franchissent.
			if (size * item.basis.get_scale()).y < 0.25:
				continue
			body.add_child(_rock_collision(mesh, item, 0.85))
		_add_chunked_multimesh(mesh, items, material, "Pebbles")""")

swap("""		for i in count:
			var item := _ground_transform(_random_spot(1.1), _rng.randf_range(5.0, 9.0))
			items.append(item)
			var shape := BoxShape3D.new()
			shape.size = size * item.basis.get_scale() * 0.8
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.transform = Transform3D(
				item.basis.orthonormalized(), item.origin + Vector3.UP * shape.size.y * 0.5
			)
			body.add_child(collision)
		var instance := _add_multimesh(mesh, items, material)
		instance.visibility_range_end = 0.0""", """		for i in count:
			var item := _ground_transform(_random_spot(1.1), _rng.randf_range(5.0, 9.0))
			items.append(item)
			body.add_child(_rock_collision(mesh, item, 0.8))
		var instance := _add_multimesh(mesh, items, material)
		instance.name = "LargeRocksMesh%d" % get_child_count()
		instance.visibility_range_end = 0.0""")

swap("""		var size := mesh.get_aabb().size
		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(1.1)""", """		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(1.1)""")

swap("""		var instance := _add_multimesh(meshes[index], transforms, material)
		instance.visibility_range_end = 0.0


## Remparts""", """		var instance := _add_multimesh(meshes[index], transforms, material)
		instance.name = "DeadTreesMesh%d" % index
		instance.visibility_range_end = 0.0


## Collision d'un rocher : sa boîte, un peu réduite, centrée sur son maillage et non sur son origine.
func _rock_collision(mesh: Mesh, item: Transform3D, shrink: float) -> CollisionShape3D:
	var box := mesh.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = box.size * item.basis.get_scale() * shrink
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var middle := item.basis * Vector3(box.get_center().x, 0.0, box.get_center().z)
	collision.transform = Transform3D(item.basis.orthonormalized(), item.origin + middle + Vector3.UP * shape.size.y * 0.5)
	return collision


## Remparts""")

swap("""	for index in large_rock_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])""", """	# Les plus gros débordent en deçà de la limite : ils ont leur collision, comme les rochers de la plaine.
	var body := StaticBody3D.new()
	body.name = "BorderRocks"
	add_child(body)
	for index in large_rock_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		var border_mesh := _load_mesh(large_rock_models[index])
		for item: Transform3D in transforms:
			body.add_child(_rock_collision(border_mesh, item, 0.8))""")

swap("""func _add_chunked_multimesh(mesh: Mesh, transforms: Array[Transform3D], material: Material) -> void:""",
     """func _add_chunked_multimesh(mesh: Mesh, transforms: Array[Transform3D], material: Material, kind: String) -> void:""")
swap("""		instance.name = "Detail%d_%d_%d" % [get_child_count(), cell.x, cell.y]""",
     """		instance.name = "%sDetail%d_%d_%d" % [kind, get_child_count(), cell.x, cell.y]""")

path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
