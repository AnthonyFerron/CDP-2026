"""Collision des arbres et rochers : hauteurs mesurées au-dessus du vrai sol sous chaque sommet."""
import sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
start = t.index("## Collision d'un arbre ou d'un rocher posé par placement")
end = t.index("## Pose des copies d'un maillage.")
t = t[:start] + '''## Collision d'un arbre ou d'un rocher posé par placement : l'emprise de sa forme entre ANKLE et TOUCH_HEIGHT au-dessus
## du sol (ses triangles coupés à ces deux hauteurs), dressée en colonne. Un cylindre au tronc laissait entrer dans les
## branches basses des pins, qui tombent jusqu'au sol, et dans le feuillage des arbres grêles ; plus large, il aurait
## fait des murs invisibles. Les hauteurs se mesurent au-dessus du sol sous chaque sommet : sur le talus, la couronne
## d'un grand arbre passe haut au-dessus du joueur qui descend, et les branches basses tournées vers le replat restent
## à hauteur d'homme.
func _add_solid(body: StaticBody3D, mesh: Mesh, placement: Transform3D) -> void:
	if not _vertices.has(mesh):
		_vertices[mesh] = mesh.get_faces()
	var faces: PackedVector3Array = _vertices[mesh]
	var o := placement.origin
	# Écart du sol autour du pied : il borne les triangles à examiner (une couronne haute est vite écartée).
	var spread := 0.0
	var around := placement.basis.get_scale().x * 0.7
	for step in 8:
		var spot := o + Vector3.RIGHT.rotated(Vector3.UP, TAU * step / 8.0) * around
		spread = maxf(spread, absf(terrain.surface_height(spot.x, spot.z) - o.y))
	spread += 0.5
	var points := PackedVector3Array()
	for index in range(0, faces.size(), 3):
		var corners: Array[Vector3] = [placement.basis * faces[index], placement.basis * faces[index + 1],
			placement.basis * faces[index + 2]]
		var lowest := minf(corners[0].y, minf(corners[1].y, corners[2].y))
		var highest := maxf(corners[0].y, maxf(corners[1].y, corners[2].y))
		if lowest - spread > TOUCH_HEIGHT or highest + spread < ANKLE:
			continue
		var grounds: Array[float] = []
		for corner in corners:
			grounds.append(terrain.surface_height(o.x + corner.x, o.z + corner.z) - o.y)
		for side in 3:
			var next := (side + 1) % 3
			var a := corners[side]
			var b := corners[next]
			var ha := a.y - grounds[side]
			var hb := b.y - grounds[next]
			if ha >= ANKLE and ha <= TOUCH_HEIGHT:
				_add_column(points, a, grounds[side])
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [ANKLE, TOUCH_HEIGHT]:
				if (ha - level) * (hb - level) < 0.0:
					var weight := (level - ha) / (hb - ha)
					_add_column(points, a.lerp(b, weight), lerpf(grounds[side], grounds[next], weight))
	if points.size() < 8:
		return
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = placement.origin
	body.add_child(collision)


## Colonne sous un point de l'emprise, du dessous du sol à SOLID_TOP au-dessus.
func _add_column(points: PackedVector3Array, point: Vector3, ground: float) -> void:
	points.append(Vector3(point.x, ground - 1.0, point.z))
	points.append(Vector3(point.x, ground + SOLID_TOP, point.z))


''' + t[end:]
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
