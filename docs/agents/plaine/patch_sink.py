"""Gros rochers et rochers des remparts : plus aucun bord qui flotte sur une pente (plaine_scatter.gd)."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def swap(old, new):
    global text
    assert old in text, old[:90]
    text = text.replace(old, new, 1)


# 1. Les gros rochers de la plaine s'enfoncent sous leur emprise.
swap("""			var item := _ground_transform(_random_spot(1.1), _rng.randf_range(5.0, 9.0))
			items.append(item)""", """			var item := _sink_rock(mesh, _ground_transform(_random_spot(1.1), _rng.randf_range(5.0, 9.0)))
			items.append(item)""")

# 2. Ceux des remparts aussi, une fois leur modèle connu.
swap("""		var border_mesh := _load_mesh(large_rock_models[index])
		for item: Transform3D in transforms:
			body.add_child(_rock_collision(border_mesh, item, true))""", """		var border_mesh := _load_mesh(large_rock_models[index])
		for k in transforms.size():
			transforms[k] = _sink_rock(border_mesh, transforms[k])
		for item: Transform3D in transforms:
			body.add_child(_rock_collision(border_mesh, item, true))""")

# 3. La fonction.
swap("""## Remparts : de hauts rochers sur le pourtour, pour que la zone ne s'arrête pas sur une pente nue.""",
     """## Abaisse un gros rocher pour qu'aucun de ses bords ne flotte : en 16 points de son emprise, le dessous de son
## maillage (lu sur ses triangles, une fois par modèle) doit passer sous le sol. Sur la pente des remparts, un rocher
## posé à la hauteur de son centre débordait de plusieurs mètres dans le vide du côté de la descente.
func _sink_rock(mesh: Mesh, item: Transform3D) -> Transform3D:
	if not _undersides.has(mesh):
		var faces := mesh.get_faces()
		var box := mesh.get_aabb()
		var points: Array[Vector3] = []
		for i in 4:
			for j in 4:
				var local := Vector3(box.position.x + box.size.x * (0.125 + 0.25 * i), box.position.y - 1.0,
					box.position.z + box.size.z * (0.125 + 0.25 * j))
				var underside := INF
				for t in range(0, faces.size(), 3):
					var hit: Variant = Geometry3D.ray_intersects_triangle(local, Vector3.UP, faces[t], faces[t + 1], faces[t + 2])
					if hit != null:
						underside = minf(underside, (hit as Vector3).y)
				if underside < INF:
					points.append(Vector3(local.x, underside, local.z))
		_undersides[mesh] = points
	var gap := 0.0
	for point: Vector3 in _undersides[mesh]:
		var world := item * point
		gap = maxf(gap, world.y - terrain.surface_height(world.x, world.z))
	if gap > 0.0:
		item.origin.y -= gap + 0.05
	return item


## Remparts : de hauts rochers sur le pourtour, pour que la zone ne s'arrête pas sur une pente nue.""")

swap("""var _tree_tops: Array[Vector3] = []""", """var _tree_tops: Array[Vector3] = []
## Dessous de chaque modèle de gros rocher, en 16 points de son emprise (repère du modèle).
var _undersides := {}""")

path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
