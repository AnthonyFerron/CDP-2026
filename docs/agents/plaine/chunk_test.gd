extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Herbes et cailloux des plaines : le joueur marche loin du centre, et à chaque pas les détails à moins de 10 m de
## lui doivent rester en deçà de leur distance d'effacement (mesurée, comme Godot, au centre de la boîte de leur case).

const POINTS := 24


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var scatter: Node3D = level.get_node("Exterior/Scatter")
	var details: Array[MultiMeshInstance3D] = []
	for child in scatter.get_children():
		if child is MultiMeshInstance3D and child.visibility_range_end > 0.0:
			details.append(child)
	check("détails découpés en cases : %d MultiMesh" % details.size(), details.size() > 20)
	var camera: Camera3D = player.get_node("CameraPivot/SpringArm3D/Camera3D")
	var worst := 0.0
	var faded := 0
	var checked := 0
	# Un tour de la carte à 60 m du centre, puis un aller-retour du portail au fond.
	var route: Array[Vector2] = []
	for index in POINTS:
		route.append(Vector2.from_angle(TAU * index / POINTS) * 60.0)
	for z in range(56, -60, -8):
		route.append(Vector2(8.0, z))
	var terrain: PlaineTerrain = level.get_node("Exterior/Terrain")
	for spot in route:
		player.global_position = Vector3(spot.x, terrain.surface_height(spot.x, spot.y) + 0.1, spot.y)
		await wait(2)
		var eye := camera.global_position
		for detail in details:
			var multimesh := detail.multimesh
			var near := false
			for index in multimesh.instance_count:
				var origin := detail.global_transform * multimesh.get_instance_transform(index).origin
				if Vector2(origin.x - eye.x, origin.z - eye.z).length() < 10.0:
					near = true
					break
			if not near:
				continue
			checked += 1
			# Boîte de la case, comme le moteur la calcule : celle du maillage placée à chaque instance (le rendu
			# factice du mode headless ne la calcule pas).
			var box := AABB()
			for index in multimesh.instance_count:
				var part := multimesh.get_instance_transform(index) * multimesh.mesh.get_aabb()
				box = part if index == 0 else box.merge(part)
			var center := detail.global_transform * box.get_center()
			var distance := eye.distance_to(center)
			if checked % 40 == 1:
				print("  %s : œil %s, centre de la case %s, %.1f m" % [detail.name, eye.snappedf(0.1), center.snappedf(0.1), distance])
			worst = maxf(worst, distance)
			if distance > detail.visibility_range_end:
				faded += 1
	# Pour comparer : avec une seule boîte pour toute la carte, son centre est près du milieu de la carte.
	var whole := AABB()
	for detail in details:
		for index in detail.multimesh.instance_count:
			var part := AABB(detail.multimesh.get_instance_transform(index).origin, Vector3.ONE * 0.01)
			whole = part if whole.size == Vector3.ZERO else whole.merge(part)
	var far := 0.0
	for spot in route:
		far = maxf(far, Vector2(spot.x - whole.get_center().x, spot.y - whole.get_center().z).length())
	print("  avant : une seule boîte, centre %s, jusqu'à %.1f m du joueur (au-delà de %.0f m, tout s'effaçait)" % [
		whole.get_center().snappedf(0.1), far, details[0].visibility_range_end])
	check("détails proches du joueur jamais effacés (%d cas vérifiés, pire distance %.1f m, limite %.0f m)" % [
		checked, worst, details[0].visibility_range_end if details else 0.0], faded == 0 and checked > 0)
	finish()
