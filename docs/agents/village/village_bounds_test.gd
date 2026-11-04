extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Village : on ne sort pas de la carte. Le joueur court et saute droit devant lui, dans 24 directions depuis le
## bourg et depuis des points hauts (remparts, tours, engin de siège, mur de maison, étal, moulin), puis dans la
## mairie sous la carte (rez-de-chaussée, escalier, bureau, salle secrète) contre chaque mur et chaque plafond.
## Toutes les tentatives doivent échouer.

const DIRECTIONS := 24
## Rayon que le joueur ne doit jamais dépasser : la limite invisible (72 m), moins sa demi-épaisseur et la capsule.
const MAX_RADIUS := 71.0
const RUN_FRAMES := 540


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	var space := player.get_world_3d().direct_space_state
	# 1. Depuis le bourg, vers l'extérieur, en courant et en sautant.
	for index in DIRECTIONS:
		var angle := TAU * index / DIRECTIONS
		var direction := Vector3(cos(angle), 0, sin(angle))
		var start := free_start(space, direction, 46.0)
		var result := await escape(start, direction, RUN_FRAMES)
		check("direction %d (%.0f°) : rayon max %.1f m, hauteur min %.1f" % [index, rad_to_deg(angle), result.x, result.y],
			result.x < MAX_RADIUS and result.y > -6.0)
	# 2. Depuis des points hauts, en sautant vers l'extérieur.
	for entry: Array in [
			["rempart ouest", Vector3(-35.0, 5.35, 30.0), Vector3(-1, 0, 0)],
			["rempart sud", Vector3(-22.0, 5.35, 41.0), Vector3(0, 0, 1)],
			["rempart est", Vector3(33.0, 5.35, 22.0), Vector3(1, 0, 0)],
			["tour de la porte", Vector3(6.0, 9.35, 42.0), Vector3(0.3, 0, 1)],
			["tour de siège", Vector3(-16.0, 8.5, 52.0), Vector3(-0.6, 0, 1)],
			["bélier", Vector3(14.0, 3.0, 50.0), Vector3(0.5, 0, 1)],
			["mur de maison", Vector3(-14.0, 4.1, 28.0), Vector3(-1, 0, 0)],
			["étal", Vector3(-7.0, 3.8, -9.0), Vector3(-0.4, 0, -1)],
			["tour du moulin", Vector3(30.0, 14.1, -30.0), Vector3(0.7, 0, -0.7)],
			["colline du moulin", Vector3(34.0, 3.0, -34.0), Vector3(0.7, 0, -0.7)],
			["berge du ruisseau", Vector3(-40.0, 0.0, -30.0), Vector3(-0.3, 0, -1)],
			["derrière le portail", Vector3(0.0, 0.5, 66.0), Vector3(0, 0, 1)]]:
		var start: Vector3 = entry[1]
		if entry[0] == "derrière le portail":
			start = ground_point(space, start)
		var result := await escape(start, (entry[2] as Vector3).normalized(), RUN_FRAMES)
		check("%s : rayon max %.1f m, hauteur min %.1f" % [entry[0], result.x, result.y], result.x < MAX_RADIUS and result.y > -6.0)

	# 3. La mairie, sous la carte : ses murs, ses plafonds et le garde-corps de l'escalier tiennent.
	level.set("_inside", true)
	level.call("_apply_location")
	var rooms := [
		["accueil", Vector3(-2.0, -39.9, 2.0)], ["accueil nord-ouest", Vector3(-6.0, -39.9, -4.8)],
		["pied de l'escalier", Vector3(5.2, -39.9, 4.6)], ["bureau", Vector3(-2.0, -35.4, 2.0)],
		["bureau, près du garde-corps", Vector3(3.6, -35.4, -1.0)], ["haut de l'escalier", Vector3(6.2, -35.4, -5.0)],
		["bureau sud-est", Vector3(6.4, -35.4, 3.4)]]
	for room: Array in rooms:
		var worst := ""
		for index in 16:
			var angle := TAU * index / 16
			var direction := Vector3(cos(angle), 0, sin(angle))
			var path := await escape_path(room[1], direction, 150)
			var wrong := outside_hall(path, room[1].y > -37.0 and room[0] != "haut de l'escalier", false)
			if wrong != Vector3.INF:
				worst = "%s vers %.0f° : %s" % [worst, rad_to_deg(angle), wrong.snappedf(0.01)]
		check("mairie, %s : enfermé dans 16 directions%s" % [room[0], worst], worst.is_empty())
	# La salle secrète, une fois la bibliothèque déplacée.
	level.call("_on_codes_solved")
	await wait(240)
	var worst := ""
	for index in 16:
		var angle := TAU * index / 16
		var path := await escape_path(Vector3(-12.0, -35.4, 1.5), Vector3(cos(angle), 0, sin(angle)), 150)
		var wrong := outside_hall(path, false, true)
		if wrong != Vector3.INF:
			worst = "%s vers %.0f° : %s" % [worst, rad_to_deg(angle), wrong.snappedf(0.01)]
	check("mairie, salle secrète : enfermé dans 16 directions%s" % worst, worst.is_empty())
	finish()


## Point de départ libre au sol, sur la demi-droite donnée, en reculant vers le centre s'il tombe dans un objet.
func free_start(space: PhysicsDirectSpaceState3D, direction: Vector3, radius: float) -> Vector3:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	for step in 30:
		var point := direction * (radius - step * 1.5)
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 30.0, point + Vector3.DOWN * 10.0)
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			continue
		var foot: Vector3 = hit.position + Vector3.UP * 0.15
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * 1.0)
		query.exclude = [player.get_rid()]
		if space.intersect_shape(query, 1).is_empty():
			return foot
	return Vector3(0, 0.3, 40)


## Point posé sur le sol, sous ou au-dessus du point donné.
func ground_point(space: PhysicsDirectSpaceState3D, point: Vector3) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 30.0, point + Vector3.DOWN * 30.0)
	ray.exclude = [player.get_rid()]
	var hit := space.intersect_ray(ray)
	return (hit.position as Vector3) + Vector3.UP * 0.15 if hit else point


## Court et saute droit devant : renvoie (rayon horizontal maximal atteint, hauteur minimale), position par position.
func escape(start: Vector3, direction: Vector3, frames: int) -> Vector2:
	var path := await escape_path(start, direction, frames)
	var radius := 0.0
	var lowest := INF
	for point in path:
		radius = maxf(radius, Vector2(point.x, point.z).length())
		lowest = minf(lowest, point.y)
	return Vector2(radius, lowest)


## Court et saute droit devant : renvoie toutes les positions prises.
func escape_path(start: Vector3, direction: Vector3, frames: int) -> PackedVector3Array:
	player.global_position = start
	player.velocity = Vector3.ZERO
	var pivot: Node3D = player.get_node("CameraPivot")
	pivot.rotation.y = atan2(-direction.x, -direction.z)
	await wait(2)
	var path := PackedVector3Array([player.global_position])
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for frame in frames:
		if frame % 36 == 0:
			Input.action_press("jump")
		elif frame % 36 == 2:
			Input.action_release("jump")
		await physics_frame
		pivot.rotation.y = atan2(-direction.x, -direction.z)
		path.append(player.global_position)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("jump")
	await wait(2)
	return path


## Première position hors de la mairie (murs à ±7,75 m, plafond du bureau à -32 m, pieds au-dessus du sol), ou
## Vector3.INF. Depuis l'étage, le joueur ne tombe pas dans la cage d'escalier ; la salle secrète (x < -8) n'est
## ouverte qu'après l'énigme, et ses murs sont à ±3,75 m.
func outside_hall(path: PackedVector3Array, upstairs: bool, secret_open: bool) -> Vector3:
	var west := -15.75 if secret_open else -7.75
	for point in path:
		if point.x < west - 0.05 or point.x > 7.75 + 0.05 or absf(point.z) > 5.75 + 0.05:
			return point
		if point.y < -40.2 or point.y + 1.8 > -32.0 + 0.05:
			return point
		if point.x < -8.0 and absf(point.z) > 3.75 + 0.05:
			return point
		if upstairs and point.y < -35.7:
			return point
	return Vector3.INF
