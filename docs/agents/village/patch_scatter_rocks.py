"""Rochers : leur collision suit leur forme au-dessus de la cheville, sans colonne au-dessus (on peut y grimper)."""
import sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
pairs = [
    ('''	_scatter(tree_models, tree_count, Vector2(3.5, 5.5), true, true)
	_scatter(rock_models, rock_count, Vector2(2.0, 4.0), true, true)''',
     '''	_scatter(tree_models, tree_count, Vector2(3.5, 5.5), true, true)
	_scatter(rock_models, rock_count, Vector2(2.0, 4.0), true, true, true)'''),
    ('''func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, outside_town: bool) -> void:''',
     '''func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, outside_town: bool,
		climbable := false) -> void:'''),
    ('''			_add_solid(body, meshes[placed % meshes.size()], Transform3D(basis, origin))''',
     '''			_add_solid(body, meshes[placed % meshes.size()], Transform3D(basis, origin), climbable)'''),
    ('''## à hauteur d'homme.
func _add_solid(body: StaticBody3D, mesh: Mesh, placement: Transform3D) -> void:''',
     '''## à hauteur d'homme. Un rocher (climbable) garde sa forme au-dessus de la cheville, sans colonne : on y grimpe.
func _add_solid(body: StaticBody3D, mesh: Mesh, placement: Transform3D, climbable := false) -> void:'''),
    ('''		if lowest - spread > TOUCH_HEIGHT or highest + spread < ANKLE:
			continue''',
     '''		if (lowest - spread > TOUCH_HEIGHT and not climbable) or highest + spread < ANKLE:
			continue'''),
    ('''			if ha >= ANKLE and ha <= TOUCH_HEIGHT:
				_add_column(points, a, grounds[side])
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [ANKLE, TOUCH_HEIGHT]:
				if (ha - level) * (hb - level) < 0.0:
					var weight := (level - ha) / (hb - ha)
					_add_column(points, a.lerp(b, weight), lerpf(grounds[side], grounds[next], weight))''',
     '''			if climbable:
				if ha >= ANKLE:
					_add_footing(points, a, grounds[side])
				if (ha - ANKLE) * (hb - ANKLE) < 0.0:
					var cut := (ANKLE - ha) / (hb - ha)
					_add_footing(points, a.lerp(b, cut), lerpf(grounds[side], grounds[next], cut))
				continue
			if ha >= ANKLE and ha <= TOUCH_HEIGHT:
				_add_column(points, a, grounds[side])
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [ANKLE, TOUCH_HEIGHT]:
				if (ha - level) * (hb - level) < 0.0:
					var weight := (level - ha) / (hb - ha)
					_add_column(points, a.lerp(b, weight), lerpf(grounds[side], grounds[next], weight))'''),
    ('''## Colonne sous un point de l'emprise, du dessous du sol à SOLID_TOP au-dessus.''',
     '''## Point d'un rocher et son aplomb sous le sol.
func _add_footing(points: PackedVector3Array, point: Vector3, ground: float) -> void:
	points.append(point)
	points.append(Vector3(point.x, ground - 1.0, point.z))


## Colonne sous un point de l'emprise, du dessous du sol à SOLID_TOP au-dessus.'''),
]
for a, b in pairs:
    assert t.count(a) == 1, a[:70]
    t = t.replace(a, b)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
