"""Zone qui brûle calée sur la lave visible (plaine_scatter.gd). Usage : patch_hazard.py <plaine_scatter.gd>"""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def swap(old, new):
    global text
    assert old in text, old[:90]
    text = text.replace(old, new, 1)


swap("""	_add_crater_effects()
	_add_lava_flow()
""", """	_add_crater_effects()
	_add_lava_flow()
	_add_lava_hazards()
""")

swap("""		add_child(_lava_surface(pool, radius))
		add_child(_lava_hazard(pool, radius))
""", """		add_child(_lava_surface(pool, radius))
""")

swap("""	# Zone qui brûle : des boîtes courtes qui suivent la pente, sous le tablier du pont.
	var area := Area3D.new()
	area.name = "LavaFlowHazard"
	add_child(area)
	for index in range(0, points.size() - 1, 2):
		var last := mini(index + 2, points.size() - 1)
		var a := Vector3(points[index].x, heights[index], points[index].y)
		var b := Vector3(points[last].x, heights[last], points[last].y)
		var shape := BoxShape3D.new()
		shape.size = Vector3(PlaineTerrain.flow_lava_half_width() * 1.8, 1.6, a.distance_to(b) + 0.4)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var middle := (a + b) * 0.5
		collision.transform = Transform3D(Basis.looking_at(Vector3(b.x - a.x, 0.0, b.z - a.z)), middle + Vector3.DOWN * 0.5)
		area.add_child(collision)
	area.body_entered.connect(func(body: Node3D) -> void: lava_touched.emit(body))

""", "\n")

swap("""func _lava_hazard(center: Vector3, radius: float) -> Area3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius * 0.92
	shape.height = 3.4
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var area := Area3D.new()
	area.position = center + Vector3.DOWN * 1.3
	area.add_child(collision)
	area.body_entered.connect(func(body: Node3D) -> void: lava_touched.emit(body))
	return area
""", """## Hauteur de la lave visible en un point : lac d'un cratère ou ruban de la coulée, sinon -INF.
func lava_surface_at(x: float, z: float) -> float:
	var lava := -INF
	for pool in lava_pools:
		var center: Vector3 = pool.center
		if Vector2(x - center.x, z - center.z).length() < pool.radius:
			lava = maxf(lava, center.y)
	if PlaineTerrain.flow_distance(x, z) < PlaineTerrain.flow_lava_half_width() + 0.5:
		var nearest := PlaineTerrain.flow_nearest(x, z)
		lava = maxf(lava, terrain.flow_lava_height(nearest.x, nearest.y))
	return lava


## Zone qui brûle, calée sur la lave visible : par rangées de HAZARD_STEP mètres, des bandes là où la lave couvre le
## sol de plus de HAZARD_DEPTH. Elle colle aux rives tortueuses des lacs comme aux élargissements de la coulée, et
## reste sous le tablier du pont.
func _add_lava_hazards() -> void:
	var area := Area3D.new()
	area.name = "LavaHazard"
	add_child(area)
	var regions: Array[Rect2] = []
	for pool in lava_pools:
		var center: Vector3 = pool.center
		regions.append(Rect2(center.x - pool.radius, center.z - pool.radius, pool.radius * 2.0, pool.radius * 2.0))
	var flow := PlaineTerrain.LAVA_FLOW
	var bounds := Rect2(flow[0], Vector2.ZERO)
	for point in flow:
		bounds = bounds.expand(point)
	regions.append(bounds.grow(PlaineTerrain.flow_lava_half_width() + 0.5))
	for region in regions:
		var z := region.position.y + HAZARD_STEP * 0.5
		while z < region.end.y:
			var start := INF
			var top := -INF
			var bottom := INF
			var x := region.position.x
			while x <= region.end.x + HAZARD_STEP:
				var ground := terrain.surface_height(x, z)
				var lava := lava_surface_at(x, z) if x <= region.end.x else -INF
				if lava - ground > HAZARD_DEPTH:
					if start == INF:
						start = x
					top = maxf(top, lava)
					bottom = minf(bottom, ground)
				elif start != INF:
					_hazard_strip(area, start, x, z, bottom - 0.4, top + 0.3)
					start = INF
					top = -INF
					bottom = INF
				x += HAZARD_STEP * 0.5
			z += HAZARD_STEP
	area.body_entered.connect(func(body: Node3D) -> void: lava_touched.emit(body))


func _hazard_strip(area: Area3D, from_x: float, to_x: float, z: float, bottom: float, top: float) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(to_x - from_x, top - bottom, HAZARD_STEP)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3((from_x + to_x) * 0.5 - HAZARD_STEP * 0.25, (top + bottom) * 0.5, z)
	area.add_child(collision)
""")

swap("""## Côté des cases des petits détails (herbes, cailloux), et longueur de leur fondu au loin.""",
     """## Pas des bandes de la zone qui brûle, et épaisseur de lave à partir de laquelle elle brûle.
const HAZARD_STEP := 0.5
const HAZARD_DEPTH := 0.08
## Côté des cases des petits détails (herbes, cailloux), et longueur de leur fondu au loin.""")

path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
