"""Rochers : enveloppe convexe de leur maillage ; arbres morts : cylindre penché comme leur tronc (plaine_scatter.gd)."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def swap(old, new):
    global text
    assert old in text, old[:90]
    text = text.replace(old, new, 1)


swap("""## Collision d'un rocher : sa boîte, un peu réduite, centrée sur son maillage et non sur son origine.
func _rock_collision(mesh: Mesh, item: Transform3D, shrink: float) -> CollisionShape3D:
	var box := mesh.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = box.size * item.basis.get_scale() * shrink
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var middle := item.basis * Vector3(box.get_center().x, 0.0, box.get_center().z)
	collision.transform = Transform3D(item.basis.orthonormalized(), item.origin + middle + Vector3.UP * shape.size.y * 0.5)
	return collision
""", """## Collision d'un rocher : l'enveloppe convexe de son maillage, à sa taille. Une boîte laissait des coins vides
## autour des blocs arrondis, des murs invisibles.
func _rock_collision(mesh: Mesh, item: Transform3D, _shrink: float) -> CollisionShape3D:
	var points := PackedVector3Array()
	var scale := item.basis.get_scale()
	for vertex in mesh.get_faces():
		points.append(vertex * scale)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(item.basis.orthonormalized(), item.origin)
	return collision
""")

swap("""		var item := _ground_transform(spot, _rng.randf_range(0.9, 1.5))
		items[i % meshes.size()].append(item)
		var shape := CylinderShape3D.new()
		shape.radius = 0.4
		shape.height = 3.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = item.origin + Vector3.UP * 1.5
		body.add_child(collision)""", """		var item := _ground_transform(spot, _rng.randf_range(0.9, 1.5))
		items[i % meshes.size()].append(item)
		# Le tronc penche : sa collision le suit, à sa grosseur, jusqu'au-dessus de la tête.
		var axis := (item.basis * _tree_tops[i % meshes.size()]).normalized()
		var shape := CylinderShape3D.new()
		shape.radius = 0.44 * item.basis.get_scale().x
		shape.height = 3.2
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = Transform3D(Basis(Quaternion(Vector3.UP, axis)), item.origin + axis * 1.6)
		body.add_child(collision)""")

swap("""	var height := _rng.randf_range(5.0, 7.5)
	var lean := Vector3(_rng.randf_range(-0.5, 0.5), 0.0, _rng.randf_range(-0.5, 0.5))
	var top := Vector3.UP * height + lean""", """	var height := _rng.randf_range(5.0, 7.5)
	var lean := Vector3(_rng.randf_range(-0.5, 0.5), 0.0, _rng.randf_range(-0.5, 0.5))
	var top := Vector3.UP * height + lean
	_tree_tops.append(top)""")

swap("""var lava_pools: Array[Dictionary] = []""", """var lava_pools: Array[Dictionary] = []
## Sommet du tronc de chaque modèle d'arbre mort, pour pencher sa collision comme lui.
var _tree_tops: Array[Vector3] = []""")

path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
