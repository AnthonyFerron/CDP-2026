"""Collision des arbres et rochers sur une pente : la tranche touchée suit le sol autour du pied."""
import sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
pairs = [
    ('''	var faces: PackedVector3Array = _vertices[mesh]
	var points := PackedVector3Array()''',
     '''	var faces: PackedVector3Array = _vertices[mesh]
	# Sur une pente, le joueur se tient plus haut ou plus bas que le pied : la tranche touchée suit le sol autour.
	var low := 0.0
	var high := 0.0
	var around := placement.basis.get_scale().x * 0.6
	for step in 8:
		var spot := placement.origin + Vector3.RIGHT.rotated(Vector3.UP, TAU * step / 8.0) * around
		var rise := terrain.footing_height(spot.x, spot.z) - placement.origin.y
		low = minf(low, rise)
		high = maxf(high, rise)
	var bottom := ANKLE + low
	var top := TOUCH_HEIGHT + high
	var points := PackedVector3Array()'''),
    ('''			if a.y >= ANKLE and a.y <= TOUCH_HEIGHT:
				_add_column(points, a)
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [ANKLE, TOUCH_HEIGHT]:''',
     '''			if a.y >= bottom and a.y <= top:
				_add_column(points, a)
			# Là où le côté traverse la cheville ou le haut de la tranche.
			for level: float in [bottom, top]:'''),
    ('''func _add_column(points: PackedVector3Array, point: Vector3) -> void:
	points.append(Vector3(point.x, -0.5, point.z))
	points.append(Vector3(point.x, SOLID_TOP, point.z))''',
     '''func _add_column(points: PackedVector3Array, point: Vector3) -> void:
	points.append(Vector3(point.x, -1.5, point.z))
	points.append(Vector3(point.x, SOLID_TOP + 1.0, point.z))'''),
]
for a, b in pairs:
    assert t.count(a) == 1, a[:60]
    t = t.replace(a, b)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
