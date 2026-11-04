extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Le long escalier de la crypte, à pied : on le descend et on le monte en entier, au milieu et sur chaque côté ;
## chaque marche porte le joueur (pas de chute, pas de ressaut, pas d'arrêt) ; en haut, là où l'on s'arrête en
## montant, l'invite « Remonter à la surface » apparaît et fonctionne ; en bas, « Remonter l'escalier » aussi.

const FLOOR := -40.0
const LANDING := -40.0 + 4.05


func _initialize() -> void:
	_run.call_deferred()


## Marche vers un point en relevant la hauteur des pieds à chaque image : renvoie [atteint, plus forte montée
## d'une image à l'autre, plus forte descente, hauteur la plus basse, hauteur la plus haute].
func walk_track(target: Vector3, label: String) -> Array:
	var pivot: Node3D = player.get_node("CameraPivot")
	Input.action_press("move_forward")
	var best := INF
	var stuck := 0
	var reached := false
	var previous := player.global_position.y
	var rise := 0.0
	var drop := 0.0
	var lowest := INF
	var highest := -INF
	for i in 900:
		await physics_frame
		var offset := target - player.global_position
		var flat := Vector2(offset.x, offset.z)
		var y := player.global_position.y
		rise = maxf(rise, y - previous)
		drop = maxf(drop, previous - y)
		lowest = minf(lowest, y)
		highest = maxf(highest, y)
		previous = y
		if flat.length() < 0.4:
			reached = true
			break
		pivot.rotation.y = atan2(-offset.x, -offset.z)
		if flat.length() < best - 0.01:
			best = flat.length()
			stuck = 0
		else:
			stuck += 1
			if stuck > 90:
				break
	Input.action_release("move_forward")
	await wait(6)
	check("%s (pos %s)" % [label, player.global_position.snappedf(0.05)], reached)
	return [reached, rise, drop, lowest, highest]


func _run() -> void:
	await start_level("res://scenes/levels/marais/marais.tscn")
	await walk_path([Vector3(-3, 0, 48), Vector3(-18, 0, 27), Vector3(-16, 0, 19), Vector3(6, 0, 4), Vector3(8.4, 0, 2.0),
		Vector3(8.4, 0, -8.0), Vector3(8.5, 0, -10.0), Vector3(3, 0, -28), Vector3(0, 0, -34.6)], "vers la crypte")
	await face(Vector3(0, 1.4, -36))
	await use("Descendre")
	await wait(150)
	check("arrivée en haut de l'escalier (%.2f)" % player.global_position.y, absf(player.global_position.y - LANDING) < 0.2)
	for lane in [0.0, -1.0, 1.0]:
		# Descente du palier jusqu'au pied de l'escalier, puis montée jusqu'à la dernière marche.
		await walk_to(Vector3(lane, LANDING, 11.0), "palier, couloir %.0f" % lane)
		var down: Array = await walk_track(Vector3(lane, FLOOR, 1.2), "descente, couloir %.0f" % lane)
		check("descente sans saut ni chute (montée max %.2f, chute max %.2f par image)" % [down[1], down[2]], down[1] < 0.06 and down[2] < 0.2)
		check("descente jusqu'au sol (%.2f)" % player.global_position.y, absf(player.global_position.y - FLOOR) < 0.1)
		var up: Array = await walk_track(Vector3(lane, LANDING, 10.0), "montée, couloir %.0f" % lane)
		check("montée sans ressaut ni chute (montée max %.2f, chute max %.2f par image)" % [up[1], up[2]], up[1] < 0.2 and up[2] < 0.06)
		check("montée jusqu'au palier (%.2f)" % player.global_position.y, absf(player.global_position.y - LANDING) < 0.1)
		# Le joueur s'arrête en haut, tourné vers le palier : l'invite de sortie est là.
		await wait(4)
		check("invite en haut de l'escalier : « %s »" % prompt(), prompt().contains("Remonter à la surface"))
	# On remonte par la trappe, depuis le haut de l'escalier.
	await press("interact")
	await wait(90)
	check("revenu à la surface par le haut (%.1f)" % player.global_position.y, player.global_position.y > -2.0)
	# Et l'on peut aussi remonter d'en bas.
	await walk_to(Vector3(0, 0, -34.6), "devant la porte")
	await face(Vector3(0, 1.4, -36))
	await use("Descendre")
	await wait(150)
	await walk_to(Vector3(0, LANDING, 10.4), "palier")
	await walk_track(Vector3(0, FLOOR, 0.6), "au pied de l'escalier")
	await face(Vector3(0, FLOOR + 1.2, 2.0))
	await use("Remonter l'escalier")
	await wait(90)
	check("revenu à la surface par le bas (%.1f)" % player.global_position.y, player.global_position.y > -2.0)
	# Le parcours dans l'autre sens : de la crypte au portail, par les trois pontons, puis le débarcadère aller-retour.
	await walk_path([Vector3(0, 0, -34.0), Vector3(3, 0, -28), Vector3(8.5, 0, -10.0), Vector3(8.4, 0, -8.0), Vector3(8.4, 0, 2.0),
		Vector3(6, 0, 4), Vector3(-16, 0, 19), Vector3(-18, 0, 27), Vector3(-3, 0, 48), Vector3(0, 0, 57)], "retour vers le portail")
	await walk_path([Vector3(7.0, 0, 53.4), Vector3(13.4, 0, 51.4), Vector3(7.0, 0, 53.4), Vector3(0, 0, 57)], "débarcadère aller-retour")
	check("toujours au sec (%.2f)" % player.global_position.y, player.global_position.y > 0.2)
	finish()
