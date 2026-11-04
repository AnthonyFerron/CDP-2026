extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Parcours de la Plaine, à pied :
## - l'escalier oublié descendu et remonté en entier, du bas, du haut et de chaque côté, chaque marche portant le joueur ;
## - chaque passage entre deux salles franchi dans les deux sens, au milieu et près de chaque montant ;
## - le pont traversé dans les deux sens sans brûler, ses parapets qui retiennent ;
## - chaque interactable essayé de chaque place où le joueur s'attend à s'en servir.

var airborne := 0
var worst_air := 0
var lowest := INF
var jumped := false


func _initialize() -> void:
	_run.call_deferred()


## Comme walk_to, mais relève les chutes (images de suite sans sol), le point le plus bas et les téléportations
## (la lave ramène le joueur en arrière).
func walk_track(target: Vector3, label: String, limit := 900, expect := true) -> bool:
	var pivot: Node3D = player.get_node("CameraPivot")
	var body := player as CharacterBody3D
	Input.action_press("move_forward")
	var best := INF
	var stuck := 0
	var reached := false
	var last := player.global_position
	for i in limit:
		paused = false
		await physics_frame
		var now := player.global_position
		if now.distance_to(last) > 1.0:
			jumped = true
		last = now
		lowest = minf(lowest, now.y)
		if body.is_on_floor():
			airborne = 0
		else:
			airborne += 1
			worst_air = maxi(worst_air, airborne)
		var offset := target - now
		var flat := Vector2(offset.x, offset.z)
		if flat.length() < 0.35:
			reached = true
			break
		pivot.rotation.y = atan2(-offset.x, -offset.z)
		if flat.length() < best - 0.01:
			best = flat.length()
			stuck = 0
		else:
			stuck += 1
			if stuck > 120:
				break
	Input.action_release("move_forward")
	await wait(4)
	if not reached and expect:
		check("%s : atteint (bloqué en %s)" % [label, player.global_position.snappedf(0.01)], false)
	return reached


## Un parcours : chaque point dans l'ordre, puis le bilan des chutes et de la hauteur d'arrivée.
func route(points: Array, label: String, end_y := NAN, max_air := 8) -> void:
	airborne = 0
	worst_air = 0
	lowest = INF
	jumped = false
	var start_y := player.global_position.y
	var ok := true
	for point: Vector3 in points:
		if not await walk_track(point, label):
			ok = false
			break
	var y := player.global_position.y
	check("%s : arrivé (%s)" % [label, player.global_position.snappedf(0.01)], ok and (is_nan(end_y) or absf(y - end_y) < 0.2))
	check("%s : toujours porté (au plus %d images sans sol, plus bas %.2f)" % [label, worst_air, lowest],
		worst_air <= max_air and (is_nan(end_y) or (lowest > minf(start_y, end_y) - 0.25 and lowest > -41.2)))
	check("%s : ni lave ni retour en arrière" % label, not jumped)


func place(at: Vector3) -> void:
	# Dehors, posé sur ce qu'il y a de plus haut sous ce point (le tablier du pont, le terrain).
	if at.y > -20.0:
		var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 20.0, at.z), Vector3(at.x, -20.0, at.z), 1)
		query.exclude = [player.get_rid()]
		var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			at.y = hit.position.y
	player.global_position = at + Vector3.UP * 0.1
	(player as CharacterBody3D).velocity = Vector3.ZERO
	paused = false
	await wait(20)


## L'invite attendue s'affiche depuis cette place, le joueur tourné vers l'objet.
func prompt_from(at: Vector3, target: Vector3, expected: String, label: String) -> void:
	await place(at)
	await face(target)
	paused = false
	await wait(4)
	check("%s depuis %s : « %s »" % [label, Vector2(at.x, at.z), prompt()], prompt().contains(expected))


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	paused = false

	# --- Dehors : porte de la bibliothèque, de face et de biais. ---
	var door := Vector3(0, 1.2, 8.6)
	for spot in [Vector3(0, 0, 10.6), Vector3(-1.6, 0, 10.4), Vector3(1.6, 0, 10.4), Vector3(0, 0, 9.4)]:
		await prompt_from(spot, door, "Entrer", "porte d'entrée")

	# --- Pont : traversé dans les deux sens, au milieu et près de chaque parapet. ---
	for x in [-0.9, 0.0, 0.9]:
		await place(Vector3(x, 0.0, 37.0))
		await route([Vector3(x, 0, 22.0)], "pont vers le nord, x %.1f" % x, NAN, 12)
		check("pont vers le nord, x %.1f : resté sur le tablier (x %.2f)" % [x, player.global_position.x], absf(player.global_position.x - x) < 0.3)
		await route([Vector3(x, 0, 37.0)], "pont vers le sud, x %.1f" % x, NAN, 12)
	# Les parapets retiennent : en marchant droit vers la lave depuis le tablier, on reste sur le pont.
	for side in [-1.0, 1.0]:
		await place(Vector3(0.0, 0.0, 29.5))
		jumped = false
		var deck := player.global_position.y
		var reached := await walk_track(Vector3(side * 6.0, 0, 29.5), "parapet", 240, false)
		check("parapet %s : le joueur reste sur le tablier (x %.2f)" % ["ouest" if side < 0 else "est", player.global_position.x],
			not reached and absf(player.global_position.x) < 2.6 and not jumped and absf(player.global_position.y - deck) < 0.3)

	# --- Portail : invite de face, de dos et de côté. ---
	var portal := Vector3(0, 0, 56)
	for spot in [Vector3(0, 0, 53.6), Vector3(0, 0, 58.4), Vector3(-2.2, 0, 56), Vector3(2.2, 0, 56)]:
		await prompt_from(spot, portal, "Portail", "portail")

	# --- Entrée : la porte mène dedans. ---
	await place(Vector3(0, 0, 10.4))
	await face(door)
	await use("Entrer")
	await wait(80)
	check("dans la bibliothèque (%s)" % player.global_position.snappedf(0.1), player.global_position.y < -38.0)

	# --- Porte de sortie, de face et de biais. ---
	var exit := Vector3(0, -38.8, -0.8)
	for spot in [Vector3(0, -40, -2.6), Vector3(-1.3, -40, -2.2), Vector3(1.3, -40, -2.2), Vector3(0, -40, -1.5)]:
		await prompt_from(spot, exit, "Sortir", "porte de sortie")

	# --- Passages entre les salles : au milieu et près de chaque montant, dans les deux sens. ---
	for x in [-4.45, -4.0, -3.55]:
		await place(Vector3(x, -40, -10.6))
		await route([Vector3(x, -40, -13.4)], "lecture → scriptorium, x %.2f" % x, -40.0)
		await route([Vector3(x, -40, -10.6)], "scriptorium → lecture, x %.2f" % x, -40.0)
	for x in [3.55, 4.0, 4.45]:
		await place(Vector3(x, -40, -22.6))
		await route([Vector3(x, -40, -25.4)], "scriptorium → archives, x %.2f" % x, -40.0)
		await route([Vector3(x, -40, -22.6)], "archives → scriptorium, x %.2f" % x, -40.0)
	# En venant du milieu des salles, comme un joueur.
	await place(Vector3(0, -40, -5.0))
	await route([Vector3(-4, -40, -11.0), Vector3(-4, -40, -13.0), Vector3(0, -40, -18.0)], "milieu de la lecture → milieu du scriptorium", -40.0)
	await route([Vector3(4, -40, -23.0), Vector3(4, -40, -25.0), Vector3(0, -40, -29.0)], "milieu du scriptorium → milieu des archives", -40.0)
	await route([Vector3(4, -40, -25.0), Vector3(4, -40, -23.0), Vector3(0, -40, -18.0)], "milieu des archives → milieu du scriptorium", -40.0)
	await route([Vector3(-4, -40, -13.0), Vector3(-4, -40, -11.0), Vector3(0, -40, -5.0)], "milieu du scriptorium → milieu de la lecture", -40.0)

	# --- Tablette : de face et de biais. ---
	var tablet := Vector3(0, -38.65, -32.7)
	for spot in [Vector3(0, -40, -31.2), Vector3(-1.2, -40, -31.5), Vector3(1.2, -40, -31.5), Vector3(-1.6, -40, -33.0), Vector3(1.6, -40, -33.0)]:
		await prompt_from(spot, tablet, "tablette", "tablette")

	# --- La dalle s'ouvre : l'escalier oublié. ---
	level._on_puzzle_solved()
	paused = false
	await wait(int(level.stone_duration * 60) + 30)
	var stone: Node3D = level.get_node("Interior/Stone")
	check("la dalle a glissé (x %.2f)" % stone.position.x, stone.position.x < -3.0)

	# Descente et montée, en finissant au pied de l'escalier à gauche, au milieu et à droite.
	for x in [-1.3, 0.0, 1.3]:
		await place(Vector3(0, -40, -34.8))
		await route([Vector3(0, -40, -36.3), Vector3(x * 0.6, -40, -36.9), Vector3(x, -41, -38.6), Vector3(x, -41, -39.1)],
			"escalier descendu vers x %.1f" % x, -41.0)
		await route([Vector3(x, -41, -38.4), Vector3(x * 0.6, -40, -36.9), Vector3(0, -40, -36.3), Vector3(0, -40, -34.8)],
			"escalier remonté depuis x %.1f" % x, -40.0)
	# De chaque côté : depuis le fond de la petite salle, en contournant le pupitre, puis en biais sur les marches.
	for side in [-1.0, 1.0]:
		await place(Vector3(0, -41, -43.0))
		await route([Vector3(side * 1.25, -41, -41.0), Vector3(side * 1.25, -41, -39.6), Vector3(side * 1.4, -41, -38.6), Vector3(-side * 0.5, -40, -36.8),
			Vector3(0, -40, -36.3), Vector3(0, -40, -35.0)], "du fond de la salle, côté %s, jusqu'aux archives" % ("ouest" if side < 0 else "est"), -40.0)
		await route([Vector3(0, -40, -36.3), Vector3(side * 1.4, -41, -38.6), Vector3(side * 1.25, -41, -39.6), Vector3(side * 1.25, -41, -41.0), Vector3(0, -41, -43.0)],
			"des archives au fond de la salle, côté %s" % ("ouest" if side < 0 else "est"), -41.0)
	# Monter et descendre le long de chaque mur de l'escalier.
	for x in [-1.55, 1.55]:
		await place(Vector3(x, -41, -39.0))
		await route([Vector3(x, -40, -36.8)], "le long du mur x %.2f, en montant" % x, -40.0)
		await route([Vector3(x, -41, -39.0)], "le long du mur x %.2f, en descendant" % x, -41.0)
	# Chaque marche porte le joueur arrêté dessus, à gauche, au milieu, à droite.
	var run := (-36.7 + 38.5) / 4.0
	for step in 4:
		var z := -36.7 - run * (step + 0.5)
		for x in [-1.5, 0.0, 1.5]:
			player.global_position = Vector3(x, -40.0 - 0.25 * step + 0.3, z)
			(player as CharacterBody3D).velocity = Vector3.ZERO
			paused = false
			await wait(30)
			var y := player.global_position.y
			check("marche %d, x %.1f : porte le joueur (y %.2f)" % [step + 1, x, y],
				(player as CharacterBody3D).is_on_floor() and y > -40.0 - 0.25 * (step + 1) - 0.05 and y < -39.95)

	# --- Le Projenomicon : du haut de l'escalier, des marches, du pied, de chaque côté et de derrière le pupitre. ---
	var book := Vector3(0, -39.83, -39.8)
	for spot in [Vector3(0, -40, -36.5), Vector3(-1.0, -40, -36.6), Vector3(1.0, -40, -36.6), Vector3(0, -40.5, -37.6),
			Vector3(0, -41, -38.7), Vector3(-1.4, -41, -39.8), Vector3(1.4, -41, -39.8), Vector3(0, -41, -41.2)]:
		await prompt_from(spot, book, "Projenomicon", "Projenomicon")
	await place(Vector3(0, -40, -36.5))
	await face(book)
	await use("Projenomicon")
	await wait(30)
	check("le Projenomicon est pris du haut de l'escalier", level._has_book)

	# --- Sortie : de retour dehors, le portail s'est rallumé. ---
	await place(Vector3(0, -40, -2.6))
	await face(exit)
	await use("Sortir")
	await wait(80)
	check("de retour dehors (%s)" % player.global_position.snappedf(0.1), player.global_position.y > -5.0)
	for spot in [Vector3(0, 0, 53.6), Vector3(0, 0, 58.4)]:
		await prompt_from(spot, portal, "Retourner au hub", "portail rallumé")
	finish()
