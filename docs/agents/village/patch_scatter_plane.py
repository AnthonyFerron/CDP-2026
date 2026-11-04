"""Collision des arbres et rochers sur une pente : la tranche touchée est mesurée au-dessus du plan du sol autour du
pied, pas au-dessus du pied seul (sinon, sous un grand arbre de talus, sa couronne faisait un mur invisible)."""
import sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
start = t.index("## Ce que le joueur peut toucher d'un arbre ou d'un rocher")
end = t.index("\nvar _rng")
t = t[:start] + '''## Ce que le joueur peut toucher d'un arbre ou d'un rocher : sa forme entre ANKLE et TOUCH_HEIGHT au-dessus du sol.
## Son emprise devient une colonne de collision, de sous le sol à SOLID_TOP au-dessus, qu'on ne traverse pas et où
## l'on ne grimpe pas.
const ANKLE := 0.3
const TOUCH_HEIGHT := 2.2
const SOLID_TOP := 3.2
''' + t[end:]
start = t.index("## Collision d'un arbre ou d'un rocher posé par placement")
end = t.index("## Pose des copies d'un maillage.")
t = t[:start] + '''## Collision d'un arbre ou d'un rocher posé par placement : l'emprise de sa forme entre ANKLE et TOUCH_HEIGHT au-dessus
## du sol (ses triangles coupés à ces deux hauteurs), dressée en colonne. Un cylindre au tronc laissait entrer dans les
## branches basses des pins, qui tombent jusqu'au sol, et dans le feuillage des arbres grêles ; plus large, il aurait
## fait des murs invisibles. Sur le talus, les hauteurs se mesurent au-dessus du plan du sol autour du pied : sous un
## grand arbre de pente, la couronne passe haut au-dessus du joueur qui descend, et ne l'arrête pas.
func _add_solid(body: StaticBody3D, mesh: Mesh, placement: Transform3D) -> void:
	if not _vertices.has(mesh):
		_vertices[mesh] = mesh.get_faces()
	var faces: PackedVector3Array = _vertices[mesh]
	var around := placement.basis.get_scale().x * 0.5
	var o := placement.origin
	var slope := Vector2(
		terrain.footing_height(o.x + around, o.z) - terrain.footing_height(o.x - around, o.z),
		terrain.footing_height(o.x, o.z + around) - terrain.footing_height(o.x, o.z - around)) / (2.0 * around)
	var points := PackedVector3Array()
	for index in range(0, faces.size(), 3):
		var corners: Array[Vector3] = [placement.basis * faces[index], placement.basis * faces[index + 1],
			placement.basis * faces[index + 2]]
		for side in 3:
			var a := corners[side]
			var b := corners[(side + 1) % 3]
			var ha := a.y - slope.dot(Vector2(a.x, a.z))
			var hb := b.y - slope.dot(Vector2(b.x, b.z))
			if ha >= ANKLE and ha <= TOUCH_HEIGHT:
				_add_column(points, a, slope)
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [ANKLE, TOUCH_HEIGHT]:
				if (ha - level) * (hb - level) < 0.0:
					_add_column(points, a.lerp(b, (level - ha) / (hb - ha)), slope)
	if points.size() < 8:
		return
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = placement.origin
	body.add_child(collision)


## Colonne sous un point de l'emprise, du dessous du sol à SOLID_TOP au-dessus (le sol étant le plan de pente).
func _add_column(points: PackedVector3Array, point: Vector3, slope: Vector2) -> void:
	var ground := slope.dot(Vector2(point.x, point.z))
	points.append(Vector3(point.x, ground - 1.0, point.z))
	points.append(Vector3(point.x, ground + SOLID_TOP, point.z))


''' + t[end:]
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
