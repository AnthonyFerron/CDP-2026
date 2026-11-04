"""Coulée de lave raccordée aux lacs des cratères (plaine_terrain.gd) : une ligne de lave qui rejoint le niveau de
chaque lac, et un lit creusé sous elle. Usage : patch_flow.py <plaine_terrain.gd>"""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def swap(old, new):
    global text
    assert old in text, old[:80]
    text = text.replace(old, new, 1)


swap("""## Coulée de lave qui relie deux cratères et coupe le chemin sous le pont de pierre : points (x, z) de son lit,
## comme dans tools/build_plaine.py. Le lit traverse le chemin en ligne droite, d'ouest en est, sous le pont.
const LAVA_FLOW: Array[Vector2] = [
	Vector2(21.0, 26.8), Vector2(14.0, 29.2), Vector2(6.5, 29.5), Vector2(-6.5, 29.5),
	Vector2(-13.5, 27.2), Vector2(-22.0, 21.0),
]""", """## Coulée de lave qui relie deux cratères et coupe le chemin sous le pont de pierre : points (x, z) de son lit.
## Le lit traverse le chemin en ligne droite, d'ouest en est, sous le pont, et ses deux bouts entrent dans les lacs.
const LAVA_FLOW: Array[Vector2] = [
	Vector2(23.2, 26.45), Vector2(21.0, 26.8), Vector2(14.0, 29.2), Vector2(6.5, 29.5), Vector2(-6.5, 29.5),
	Vector2(-13.5, 27.2), Vector2(-22.0, 21.0), Vector2(-24.9, 19.6),
]""")

swap("""var _relief := FastNoiseLite.new()
""", """var _relief := FastNoiseLite.new()
## Niveau de la lave de chaque cratère, calé sur son bord : la coulée s'y raccorde.
var _pool_levels: Array[float] = []
""")

swap("""	_relief.frequency = 0.035
	_build()""", """	_relief.frequency = 0.035
	_pool_levels.clear()
	for crater in CRATERS:
		_pool_levels.append(_pool_level(crater))
	_build()""")

swap("""func height_at(x: float, z: float) -> float:
	var height := base_height_at(x, z) + _flow_profile(x, z)
	for impact in IMPACTS:""", """func height_at(x: float, z: float) -> float:
	var height := _carve_flow(x, z, base_height_at(x, z))
	for impact in IMPACTS:""")

swap("""## Distance horizontale au milieu du lit de la coulée.
static func flow_distance(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var best := INF
	for index in LAVA_FLOW.size() - 1:
		var a := LAVA_FLOW[index]
		var b := LAVA_FLOW[index + 1]
		var t := clampf((point - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		best = minf(best, point.distance_to(a.lerp(b, t)))
	return best
""", """## Distance horizontale au milieu du lit de la coulée.
static func flow_distance(x: float, z: float) -> float:
	return Vector2(x, z).distance_to(flow_nearest(x, z))


## Point du milieu du lit le plus proche.
static func flow_nearest(x: float, z: float) -> Vector2:
	var point := Vector2(x, z)
	var best := INF
	var nearest := LAVA_FLOW[0]
	for index in LAVA_FLOW.size() - 1:
		var a := LAVA_FLOW[index]
		var b := LAVA_FLOW[index + 1]
		var t := clampf((point - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var candidate := a.lerp(b, t)
		if point.distance_to(candidate) < best:
			best = point.distance_to(candidate)
			nearest = candidate
	return nearest


## Niveau de la lave d'un cratère : juste sous le point le plus bas de son bassin, au bord de la lave.
func _pool_level(crater: Vector4) -> float:
	var lowest := INF
	for i in 12:
		var edge := Vector2.from_angle(TAU * i / 12.0) * crater.z * LAVA_RATIO
		lowest = minf(lowest, base_height_at(crater.x + edge.x, crater.y + edge.y))
	return lowest - 0.08


## Niveau de la lave du cratère donné (index dans CRATERS).
func crater_lava_level(index: int) -> float:
	if _pool_levels.is_empty():
		return _pool_level(CRATERS[index])
	return _pool_levels[index]


## Hauteur de la lave de la coulée en un point de son milieu : au milieu de son lit, et au niveau du lac à
## l'approche d'un cratère, un peu au-dessus de lui sur son bord pour en couvrir la croûte, un peu en dessous
## au large pour disparaître sous sa surface.
func flow_lava_height(x: float, z: float) -> float:
	var lava := base_height_at(x, z) - FLOW_DEPTH + FLOW_LAVA_RISE
	for index in CRATERS.size():
		var crater := CRATERS[index]
		var radius := crater.z * LAVA_RATIO
		var distance := Vector2(x - crater.x, z - crater.y).length()
		if distance > radius + FLOW_JOIN:
			continue
		var level := crater_lava_level(index)
		var near := lerpf(level - 0.05, level + 0.03, smoothstep(radius - 0.9, radius - 0.3, distance))
		lava = lerpf(near, lava, smoothstep(radius + 0.3, radius + FLOW_JOIN, distance))
	return lava
""")

swap("""## Lit en creux de la coulée, qui s'efface au fond des cratères où elle se jette.
func _flow_profile(x: float, z: float) -> float:
	var ratio := flow_distance(x, z) / FLOW_HALF_WIDTH
	if ratio >= 1.0:
		return 0.0
	var fade := 1.0
	for crater in CRATERS:
		var inside := Vector2(x - crater.x, z - crater.y).length() / crater.z
		fade = minf(fade, smoothstep(0.45, 0.85, inside))
	return -FLOW_DEPTH * (1.0 - ratio * ratio) * fade
""", """## Lit en creux de la coulée, creusé sous sa ligne de lave : son fond est à FLOW_LAVA_RISE sous la lave, et ses
## berges remontent au-dessus d'elle, jusque dans les lacs où elle se jette. Il ne remblaie jamais le sol.
func _carve_flow(x: float, z: float, ground: float) -> float:
	var nearest := flow_nearest(x, z)
	var ratio := Vector2(x, z).distance_to(nearest) / FLOW_HALF_WIDTH
	if ratio >= 1.0:
		return ground
	var bed := flow_lava_height(nearest.x, nearest.y) - FLOW_LAVA_RISE
	return minf(ground, bed + FLOW_DEPTH * ratio * ratio)
""")

swap("""const FLOW_LAVA_RISE := 0.7
""", """const FLOW_LAVA_RISE := 0.7
## Longueur, au-delà du bord d'un lac, sur laquelle la coulée rejoint son niveau.
const FLOW_JOIN := 3.0
""")

path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
