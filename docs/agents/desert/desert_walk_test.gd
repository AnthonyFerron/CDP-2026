extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Parcours à pied du désert de Pythania : depuis le portail, le joueur marche (sans téléportation) dans l'allée,
## l'avant-cour, la salle des colonnes, les chambres du levant et du zénith, le portique du sanctuaire, puis jusqu'à
## l'oasis, la caravane et les tombes, et enfin dans la cave par la trappe. Devant chaque indice, il se tourne vers lui
## et vérifie l'invite. Chaque étape : [point où marcher, objet à regarder ou null, début de l'invite attendue].

const OUTSIDE := [
	[Vector3(0, 0, 40), null, ""],
	[Vector3(0, 0, 14), null, ""],
	[Vector3(1.6, 0, 12.6), Vector3(2.6, 0, 12), "Ramasser la rune"],
	[Vector3(8.4, 0, 9.4), Vector3(8.4, 0, 7.6), "Ramasser la rune"],
	[Vector3(-4, 0, 6.4), Vector3(-4, 0, 8), "Maintenir"],
	[Vector3(-6.4, 0, 6.8), Vector3(-7, 1.4, 8), "Lire la stèle"],
	[Vector3(-10.5, 0, 7.6), Vector3(-10.5, 1.45, 6), "Lire la plaque"],
	[Vector3(-4, 0, 7.4), null, ""],
	[Vector3(-3, 0, 3), null, ""],
	[Vector3(-7.3, 0, -1), Vector3(-9, 0, -1), "Maintenir"],
	[Vector3(-8, 0, -10), null, ""],
	[Vector3(-11.6, 0, -12), null, ""],
	[Vector3(-15, 0, -12.8), Vector3(-15.4, 0, -14.4), "Ramasser la rune"],
	[Vector3(-15.6, 0, -12), Vector3(-17.6, 1.4, -12), "Lire la stèle"],
	[Vector3(-11.6, 0, -12), null, ""],
	[Vector3(8, 0, -12), null, ""],
	[Vector3(11.6, 0, -12), null, ""],
	[Vector3(14.6, 0, -10.8), Vector3(15.6, 0, -9.4), "Maintenir"],
	[Vector3(15.8, 0, -12), Vector3(17.6, 1.4, -12), "Lire la stèle"],
	[Vector3(13.4, 0, -13.6), Vector3(14.6, 0.85, -13.6), "Lire la tablette"],
	[Vector3(11.6, 0, -12), null, ""],
	[Vector3(8, 0, -12), null, ""],
	[Vector3(7.75, 0, -17.6), null, ""],
	[Vector3(7.75, 0, -21.3), null, ""],
	[Vector3(0, 0, -21.3), null, ""],
	[Vector3(-7.75, 0, -21.3), null, ""],
	[Vector3(-7.75, 0, -17.6), null, ""],
	[Vector3(-3, 0, 2), null, ""],
	[Vector3(4, 0, 9.5), null, ""],
	[Vector3(15, 0, 9), null, ""],
	[Vector3(14.6, 0, 2.5), null, ""],
	[Vector3(21, 0, 1), null, ""],
	[Vector3(30, 0, -2), null, ""],
	[Vector3(36.5, 0, -1.5), null, ""],
	[Vector3(38.2, 0, 2), null, ""],
	[Vector3(36, 0, 6.6), null, ""],
	[Vector3(34.9, 0, 5.8), Vector3(34.2, 0.56, 4.75), "Lire le journal"],
	[Vector3(36, 0, 6.6), null, ""],
	[Vector3(38.2, 0, 2), null, ""],
	[Vector3(30, 0, -2), null, ""],
	[Vector3(21, 0, 1), null, ""],
	[Vector3(14.6, 0, 2.5), null, ""],
	[Vector3(15, 0, 9), null, ""],
	[Vector3(4, 0, 9.5), null, ""],
	[Vector3(-3, 0, 2), null, ""],
	[Vector3(-8, 0, -10), null, ""],
	[Vector3(-11.6, 0, -12), null, ""],
	[Vector3(-14, 0, -9.5), null, ""],
	[Vector3(-14, 0, -5.5), null, ""],
	[Vector3(-23, 0, -4.5), null, ""],
	[Vector3(-22, 0, -10), null, ""],
	[Vector3(-20.5, 0, -20), null, ""],
	[Vector3(-21, 0, -24), null, ""],
	[Vector3(-29, 0, -28.5), null, ""],
	[Vector3(-32.4, 0, -28.6), Vector3(-32.85, 0.9, -30.29), "Lire le carnet"],
	[Vector3(-29, 0, -28.5), null, ""],
	[Vector3(-21, 0, -24), null, ""],
	[Vector3(-22.4, 0, -22), null, ""],
	[Vector3(-20.5, 0, -20), null, ""],
	[Vector3(-22, 0, -10), null, ""],
	[Vector3(-23, 0, -4.5), null, ""],
	[Vector3(-14, 0, 8), null, ""],
	[Vector3(-4, 0, 10), null, ""],
	[Vector3(0, 0, 14), null, ""],
	[Vector3(0, 0, 21), null, ""],
	[Vector3(-4, 0, 28), null, ""],
	[Vector3(-9.6, 0, 36), null, ""],
	[Vector3(-18.6, 0, 44), null, ""],
	[Vector3(-18.6, 0, 46.5), Vector3(-20, 1.1, 46.5), "Lire la lettre"],
	[Vector3(-10, 0, 36), null, ""],
	[Vector3(-3, 0, 36), null, ""],
	[Vector3(0, 0, 12), null, ""],
	[Vector3(0, 0, -3.8), Vector3(0, 0, -6), "Soulever la trappe"],
]
const CAVE := [
	[Vector3(-7, -40, -4), Vector3(-7, -39.06, -1.9), "Ramasser la rune"],
	[Vector3(-6.5, -40, -6), Vector3(-9, -38.7, -6), "Examiner l'algorithme"],
	[Vector3(-5.5, -40, -7.4), Vector3(-6.5, -40, -8.8), "Maintenir"],
	[Vector3(-2.6, -40, -7.6), Vector3(-3.6, -40, -8.2), "Maintenir"],
	[Vector3(0, -40, -8.4), Vector3(0, -38.05, -11.3), "Lire l'inscription"],
	[Vector3(4.6, -40, -5.2), Vector3(6, -40, -4.4), "Maintenir"],
	[Vector3(6.5, -40, -6), Vector3(9, -38.7, -6), "Examiner l'algorithme"],
	[Vector3(7.4, -40, -3.0), Vector3(7, -39.06, -1.9), "Ramasser la rune"],
	[Vector3(5.4, -40, -4.6), null, ""],
	[Vector3(3.0, -40, -4.6), null, ""],
	[Vector3(2.4, -40, -2.6), Vector3(3.75, -39.36, -2.65), "Lire le rouleau"],
	[Vector3(0, -40, -3.6), Vector3(0, -39, -6), "Examiner la table ronde"],
	[Vector3(0, -40, -0.9), Vector3(0, -38.4, 1.7), "Remonter"],
	# L'escalier se monte et se descend en entier ; la sortie marche en bas comme en haut.
	[Vector3(0, -37.3, 3.0), Vector3(0, -38.4, 1.7), "Remonter"],
	[Vector3(0, -40, -1.6), null, ""],
	[Vector3(0, -37.3, 3.0), Vector3(0, -38.4, 1.7), "Remonter"],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	await _route(OUTSIDE)
	await press("interact")
	await wait(90)
	check("dans la cave par la trappe", player.global_position.y < -30)
	await _route(CAVE)
	check("en haut de l'escalier (hauteur %.2f)" % (player.global_position.y + 40.0), player.global_position.y > -37.6)
	await press("interact")
	await wait(90)
	check("remonté à la surface", player.global_position.y > -5)
	finish()


func _route(steps: Array) -> void:
	for step: Array in steps:
		var point: Vector3 = step[0]
		var reached := await walk_to(point, "marche vers %s" % Vector2(point.x, point.z), 1400)
		if step[1] != null:
			await face(step[1])
			await wait(4)
			check("  invite « %s » vers %s : %s" % [step[2], Vector2(step[1].x, step[1].z), prompt()], prompt().contains(step[2]))
		if not reached:
			# On repart du point voulu, posé sur le sol, pour vérifier la suite du parcours.
			var ground: float = point.y if point.y < -20.0 else level.get_node("Exterior/Terrain").surface_height(point.x, point.z)
			player.global_position = Vector3(point.x, ground + 0.3, point.z)
			player.velocity = Vector3.ZERO
			await wait(10)
