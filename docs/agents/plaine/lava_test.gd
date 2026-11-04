extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Lave des plaines : la coulée est continue d'un lac à l'autre, sans trou ni marche à ses raccords, ses bords ne
## flottent pas, et la zone qui brûle colle à la lave visible (rien ne brûle à sec, rien de profond ne laisse passer).

const STEP := 0.25


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var terrain: PlaineTerrain = level.get_node("Exterior/Terrain")
	var scatter: PlaineScatter = level.get_node("Exterior/Scatter")
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var ribbon_half := PlaineTerrain.flow_lava_half_width() + 0.5

	# Surface de lave visible en un point : lac d'un cratère, sinon ruban de la coulée, sinon rien.
	var lava_at := func(x: float, z: float) -> float:
		for pool in scatter.lava_pools:
			var center: Vector3 = pool.center
			if Vector2(x - center.x, z - center.z).length() < pool.radius:
				return center.y
		if PlaineTerrain.flow_distance(x, z) < ribbon_half:
			var nearest := PlaineTerrain.flow_nearest(x, z)
			return terrain.flow_lava_height(nearest.x, nearest.y)
		return -INF

	var burns := func(x: float, y: float, z: float) -> bool:
		var query := PhysicsPointQueryParameters3D.new()
		query.position = Vector3(x, y, z)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		for hit in space.intersect_point(query, 8):
			if hit.collider is Area3D and hit.collider.get_parent() == scatter:
				return true
		return false

	# 1. Le milieu de la coulée, d'un bout à l'autre : la lave est toujours au-dessus du sol.
	var holes := 0
	var flow := PlaineTerrain.LAVA_FLOW
	for index in flow.size() - 1:
		var length := flow[index].distance_to(flow[index + 1])
		for step in int(length / STEP):
			var point := flow[index].lerp(flow[index + 1], step * STEP / length)
			var lava: float = lava_at.call(point.x, point.y)
			if lava < terrain.surface_height(point.x, point.y) + 0.02:
				holes += 1
				if holes < 6:
					print("      trou dans la coulée en %s : lave %.2f, sol %.2f" % [point.snappedf(0.1), lava,
						terrain.surface_height(point.x, point.y)])
	check("coulée continue d'un lac à l'autre (%d points sans lave)" % holes, holes == 0)

	# 2. Marche au raccord : le ruban arrive au niveau du lac.
	for pool_index in [0, 1]:
		var crater := PlaineTerrain.CRATERS[pool_index]
		var pool: Dictionary = scatter.lava_pools[pool_index]
		var level_y: float = pool.center.y
		var worst := 0.0
		for index in flow.size() - 1:
			var length := flow[index].distance_to(flow[index + 1])
			for step in int(length / STEP):
				var point := flow[index].lerp(flow[index + 1], step * STEP / length)
				var distance := Vector2(point.x - crater.x, point.y - crater.y).length()
				if absf(distance - pool.radius) < 0.4:
					worst = maxf(worst, absf(terrain.flow_lava_height(point.x, point.y) - level_y))
		check("raccord du cratère (%.0f, %.0f) : marche de %.2f m au bord du lac" % [crater.x, crater.y, worst], worst < 0.06)

	# 3. Bords du ruban cachés sous les berges, hors des lacs.
	var floating := 0
	for index in flow.size() - 1:
		var a := flow[index]
		var b := flow[index + 1]
		var side := (b - a).normalized().orthogonal()
		var length := a.distance_to(b)
		for step in int(length / 0.5):
			var point := a.lerp(b, step * 0.5 / length)
			var lava := terrain.flow_lava_height(point.x, point.y)
			for sign in [-1.0, 1.0]:
				var edge: Vector2 = point + side * sign * ribbon_half
				var in_pool := false
				for pool in scatter.lava_pools:
					if Vector2(edge.x - pool.center.x, edge.y - pool.center.z).length() < pool.radius + 0.6:
						in_pool = true
				if not in_pool and terrain.surface_height(edge.x, edge.y) < lava - 0.03:
					floating += 1
					if floating < 6:
						print("      bord de lave en l'air en %s : lave %.2f, sol %.2f" % [edge.snappedf(0.1), lava,
							terrain.surface_height(edge.x, edge.y)])
	check("bords de la coulée sous les berges (%d points en l'air)" % floating, floating == 0)

	# 4. Zone qui brûle contre lave visible, sur une grille autour de la coulée et des deux lacs.
	var dry_burns := 0
	var safe_lava := 0
	var checked := 0
	for x in range(-36 * 4, 34 * 4):
		for z in range(10 * 4, 36 * 4):
			var px := x * STEP
			var pz := z * STEP
			if PlaineTerrain.flow_distance(px, pz) > 5.0 and Vector2(px - 26, pz - 26).length() > 9.0 \
					and Vector2(px + 28, pz - 18).length() > 11.0:
				continue
			checked += 1
			var ground := terrain.surface_height(px, pz)
			var lava: float = lava_at.call(px, pz)
			var depth := lava - ground
			var hot: bool = burns.call(px, ground + 0.15, pz)
			if hot and depth < -0.05:
				dry_burns += 1
				if dry_burns < 6:
					print("      brûle à sec en (%.2f, %.2f) : sol %.2f, lave %.2f" % [px, pz, ground, lava])
			elif not hot and depth > 0.3:
				safe_lava += 1
				if safe_lava < 6:
					print("      lave sans brûlure en (%.2f, %.2f) : %.2f m de lave" % [px, pz, depth])
	check("rien ne brûle à sec (%d points sur %d)" % [dry_burns, checked], dry_burns == 0)
	check("toute lave de plus de 30 cm brûle (%d points sur %d)" % [safe_lava, checked], safe_lava == 0)
	# Sur le tablier du pont, à hauteur des pieds et de la tête du joueur, rien ne brûle.
	var deck_burns := 0
	for x in range(-16, 17):
		for z in range(int(23.4 * 4), int(35.6 * 4)):
			for y in [0.1, 0.9, 1.7]:
				if burns.call(x * 0.1, y, z * 0.25):
					deck_burns += 1
	check("rien ne brûle sur le pont (%d points)" % deck_burns, deck_burns == 0)
	finish()
