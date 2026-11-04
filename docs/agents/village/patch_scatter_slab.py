"""Collision des arbres et rochers : l'emprise de leurs triangles coupés entre la cheville et le haut de la tranche."""
import sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
start = t.index("## Collision d'un arbre ou d'un rocher posé par placement")
end = t.index("## Pose des copies d'un maillage.")
new = '''## Collision d'un arbre ou d'un rocher posé par placement : l'emprise de sa forme entre ANKLE et TOUCH_HEIGHT (ses
## triangles coupés à ces deux hauteurs), dressée en colonne jusqu'à SOLID_TOP. Un cylindre au tronc laissait entrer
## dans les branches basses des pins, qui tombent jusqu'au sol, et dans le feuillage des arbres grêles ; plus large,
## il aurait fait des murs invisibles.
func _add_solid(body: StaticBody3D, mesh: Mesh, placement: Transform3D) -> void:
	if not _vertices.has(mesh):
		_vertices[mesh] = mesh.get_faces()
	var faces: PackedVector3Array = _vertices[mesh]
	var points := PackedVector3Array()
	for index in range(0, faces.size(), 3):
		var corners: Array[Vector3] = [placement.basis * faces[index], placement.basis * faces[index + 1],
			placement.basis * faces[index + 2]]
		for side in 3:
			var a := corners[side]
			var b := corners[(side + 1) % 3]
			if a.y >= ANKLE and a.y <= TOUCH_HEIGHT:
				_add_column(points, a)
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [ANKLE, TOUCH_HEIGHT]:
				if (a.y - level) * (b.y - level) < 0.0:
					_add_column(points, a.lerp(b, (level - a.y) / (b.y - a.y)))
	if points.size() < 8:
		return
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = placement.origin
	body.add_child(collision)


func _add_column(points: PackedVector3Array, point: Vector3) -> void:
	points.append(Vector3(point.x, -0.5, point.z))
	points.append(Vector3(point.x, SOLID_TOP, point.z))


'''
t = t[:start] + new + t[end:]
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
