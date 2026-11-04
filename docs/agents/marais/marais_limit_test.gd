extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Limites des marais : on ne sort ni de la carte ni de la crypte, en marchant, en courant ou en sautant.
## Dehors, 24 directions depuis le fond des eaux (l'enlisement coupé, pour éprouver la limite elle-même),
## 3 directions depuis l'îlot de l'arrivée (enlisement actif), 8 chutes depuis 12 m de haut contre la berge.
## Dans la crypte, 16 directions depuis chaque salle, et des sauts depuis le dessus des tombeaux.

const LIMIT := 68.5
# Cases de la crypte (indices de case de 4 m), comme CRYPT_ROOMS dans tools/build_marais.py.
const CELLS := [
	Vector2i(0, 0), Vector2i(3, -3), Vector2i(4, -3), Vector2i(-3, -3), Vector2i(-4, -3),
	Vector2i(-3, -1), Vector2i(-3, 0), Vector2i(3, -1), Vector2i(3, 0),
]

var _escapes := 0


func _initialize() -> void:
	_run.call_deferred()


func inside_cell(point: Vector3) -> bool:
	var x := point.x
	var z := point.z
	# Long escalier et palier : x de -1,5 à 1,5, z de 2 à 14,4.
	if absf(x) < 1.5 and z > 1.9 and z < 14.4:
		return true
	var cells: Array = CELLS.duplicate()
	for ix in range(-2, 3):
		for iz in range(-5, 0):
			cells.append(Vector2i(ix, iz))
	for ix in range(5, 8):
		for iz in range(-4, -1):
			cells.append(Vector2i(ix, iz))
			cells.append(Vector2i(-ix, iz))
	for ix in range(-5, -3):
		for iz in range(0, 2):
			cells.append(Vector2i(ix, iz))
			cells.append(Vector2i(-ix, iz))
	for cell: Vector2i in cells:
		if absf(x - cell.x * 4.0) <= 2.0 and absf(z - cell.y * 4.0) <= 2.0:
			return true
	return false


## Pousse le joueur dans une direction en courant et en sautant ; renvoie la plus grande distance au centre atteinte.
func push(direction: Vector2, frames: int, crypt := false) -> float:
	var pivot: Node3D = player.get_node("CameraPivot")
	pivot.rotation.y = atan2(-direction.x, -direction.y)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	var farthest := 0.0
	for i in frames:
		if i % 35 == 0:
			Input.action_press("jump")
		elif i % 35 == 3:
			Input.action_release("jump")
		await physics_frame
		var p := player.global_position
		if crypt:
			if not inside_cell(p - Vector3(0, -40, 0)) or p.y > -40.0 + 8.3 or p.y < -41.0:
				_escapes += 1
				print("  sortie de la crypte en ", p.snappedf(0.1))
				break
		else:
			farthest = maxf(farthest, Vector2(p.x, p.z).length())
			if p.y < -5.0:
				farthest = INF
				break
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("jump")
	await wait(3)
	return farthest


func _run() -> void:
	await start_level("res://scenes/levels/marais/marais.tscn")
	var terrain: Node = level.get_node("Terrain")
	# Enlisement coupé : le joueur marche au fond de l'eau jusqu'à la berge.
	level.set("_inside", true)
	for i in 24:
		var direction := Vector2.from_angle(TAU * i / 24.0)
		var start := direction * 58.0
		player.global_position = Vector3(start.x, terrain.surface_height(start.x, start.y) + 0.3, start.y)
		player.velocity = Vector3.ZERO
		await wait(3)
		var farthest := await push(direction, 420)
		check("direction %d° : arrêté à %.1f m" % [i * 15, farthest], farthest < LIMIT + 0.2)
	# Chutes depuis 12 m contre la limite, comme un saut depuis un objet haut.
	for i in 8:
		var direction := Vector2.from_angle(TAU * i / 8.0 + 0.2)
		var start := direction * (LIMIT - 1.5)
		player.global_position = Vector3(start.x, 12.0, start.y)
		player.velocity = Vector3.ZERO
		var farthest := await push(direction, 240)
		check("chute %d : arrêté à %.1f m" % [i, farthest], farthest < LIMIT + 0.2)
	# Enlisement actif : depuis l'arrivée, vers le sud, derrière le portail.
	level.set("_inside", false)
	for angle in [80.0, 90.0, 100.0]:
		player.global_position = Vector3(0.0, 0.6, 60.0)
		player.velocity = Vector3.ZERO
		await wait(5)
		var direction := Vector2.from_angle(deg_to_rad(angle))
		var farthest := await push(direction, 360)
		check("arrivée, cap %.0f° : arrêté à %.1f m" % [angle, farthest], farthest < LIMIT + 0.2)
		await wait(80)

	# La crypte : depuis chaque salle, 16 directions, en courant et en sautant.
	level.set("_inside", true)
	level.call("_apply_location")
	_escapes = 0
	for room: Vector3 in [Vector3(0, 0, 0), Vector3(0, 0, -12), Vector3(-24, 0, -12), Vector3(24, 0, -12),
			Vector3(-18, 0, 2), Vector3(18, 0, 2), Vector3(-14, 0, -12), Vector3(14, 0, -12), Vector3(0, 4.05, 12.4)]:
		for i in 16:
			player.global_position = room + Vector3(0, -39.7, 0)
			player.velocity = Vector3.ZERO
			await wait(2)
			await push(Vector2.from_angle(TAU * i / 16.0), 150, true)
	check("crypte fermée de partout (%d sortie)" % _escapes, _escapes == 0)
	# Sauts depuis le dessus des tombeaux et du mécanisme : la tête bute au plafond.
	var highest := -INF
	for top: Vector3 in [Vector3(-21.2, 1.25, -8.95), Vector3(-26.8, 1.25, -15.05), Vector3(24, 1.25, -12), Vector3(0, 0.35, -12)]:
		player.global_position = top + Vector3(0, -40, 0)
		player.velocity = Vector3.ZERO
		await wait(2)
		Input.action_press("jump")
		for i in 50:
			await physics_frame
			highest = maxf(highest, player.global_position.y)
		Input.action_release("jump")
		await wait(30)
	check("sauts sous le plafond (pieds au plus haut à %.2f m, plafond à 4,15 m)" % (highest + 40.0), highest + 40.0 + 1.8 < 4.2)
	finish()
