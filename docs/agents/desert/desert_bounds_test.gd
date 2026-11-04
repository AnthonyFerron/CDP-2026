extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Sortie de carte du désert de Pythania : dans 32 directions, le joueur court vers le bord en marchant, en sautant
## sans arrêt, et en tombant d'un point haut au pied des crêtes (comme s'il sautait d'un rocher) ; il ne doit jamais
## dépasser la limite invisible ni tomber sous le sol. Dans la cave, il court et saute vers 16 directions, et saute
## depuis la table ronde et les tables : il ne doit traverser ni les murs ni le plafond.

const DIRECTIONS := 32
const FRAMES := 300
## Bord intérieur de la limite invisible (rayon moins la demi-épaisseur du mur et le rayon du joueur).
const LIMIT := DesertTerrain.LIMIT_RADIUS - 0.5 - 0.35
## Cave : intérieur des murs et dessous du plafond, en coordonnées du monde.
const CAVE_MIN := Vector2(-9.45, -11.45)
const CAVE_MAX := Vector2(9.45, 4.05)
const CEILING := -40.0 + 4.15
## Plafond de la cage de l'escalier, plus haut, au sud de z = 0.
const SHAFT_CEILING := -40.0 + 5.4


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	var terrain: Node = level.get_node("Exterior/Terrain")
	var pivot: Node3D = player.get_node("CameraPivot")
	var worst := 0.0
	for index in DIRECTIONS:
		var angle := TAU * index / DIRECTIONS
		var direction := Vector2.from_angle(angle)
		for mode in ["en marchant", "en sautant", "depuis un point haut"]:
			var start := direction * (52.0 if mode != "depuis un point haut" else 63.5)
			var lift := 0.4 if mode != "depuis un point haut" else 4.5
			player.global_position = Vector3(start.x, terrain.surface_height(start.x, start.y) + lift, start.y)
			player.velocity = Vector3.ZERO
			pivot.rotation.y = atan2(-direction.x, -direction.y)
			var reach := await push(mode != "en marchant", FRAMES)
			worst = maxf(worst, reach.x)
			check("vers %3d° %s : reste dans la zone (au plus %.1f m, y %.1f)" % [roundi(rad_to_deg(angle)), mode, reach.x, reach.y],
				reach.x < LIMIT + 0.05 and reach.y > -20.0)
	print("Distance la plus grande atteinte : %.2f m (limite %.2f m)" % [worst, LIMIT])

	# Cave : murs et plafond.
	level.set("_inside", true)
	level.call("_apply_location")
	await wait(5)
	for index in 16:
		var angle := TAU * index / 16
		var direction := Vector2.from_angle(angle)
		for origin: Vector3 in [Vector3(0, -40, -2.6), Vector3(-5.5, -40, -6.0), Vector3(5.5, -40, -6.0)]:
			player.global_position = origin + Vector3.UP * 0.1
			player.velocity = Vector3.ZERO
			pivot.rotation.y = atan2(-direction.x, -direction.y)
			var box := await push_cave(200)
			check("cave vers %3d° depuis %s : enfermé (x %.1f..%.1f, z %.1f..%.1f, tête sous le plafond de %.2f m)" % [
				roundi(rad_to_deg(angle)), Vector2(origin.x, origin.z), box[0].x, box[1].x, box[0].y, box[1].y, -box[2]],
				box[0].x > CAVE_MIN.x and box[1].x < CAVE_MAX.x and box[0].y > CAVE_MIN.y and box[1].y < CAVE_MAX.y
				and box[2] < 0.0 and box[3] > -40.5)
	# Sauter depuis la table ronde et les tables des runes : la tête bute contre le plafond.
	for top: Vector3 in [Vector3(0, -38.78, -6.0), Vector3(-7.0, -39.05, -1.9), Vector3(7.0, -39.05, -1.9)]:
		player.global_position = top + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		var highest := -INF
		for jump in 6:
			Input.action_press("jump")
			await physics_frame
			Input.action_release("jump")
			for frame in 50:
				await physics_frame
				highest = maxf(highest, player.global_position.y)
		check("saut depuis %s : sous le plafond (pieds au plus %.2f, plafond %.2f)" % [top.snappedf(0.1), highest, CEILING],
			highest + 1.75 < CEILING)
	finish()


## Court droit devant, en sautant si demandé ; rend (distance au centre la plus grande, hauteur la plus basse).
func push(jumping: bool, frames: int) -> Vector2:
	Input.action_press("move_forward")
	Input.action_press("sprint")
	var farthest := 0.0
	var lowest := INF
	for frame in frames:
		if jumping and frame % 24 == 0:
			Input.action_press("jump")
		elif jumping and frame % 24 == 1:
			Input.action_release("jump")
		await physics_frame
		farthest = maxf(farthest, Vector2(player.global_position.x, player.global_position.z).length())
		lowest = minf(lowest, player.global_position.y)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("jump")
	await wait(2)
	return Vector2(farthest, lowest)


## Même chose dans la cave : rend [coin bas (x, z), coin haut (x, z), pieds le plus haut, pieds le plus bas].
func push_cave(frames: int) -> Array:
	Input.action_press("move_forward")
	Input.action_press("sprint")
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	var top := -INF
	var bottom := INF
	for frame in frames:
		if frame % 20 == 0:
			Input.action_press("jump")
		elif frame % 20 == 1:
			Input.action_release("jump")
		await physics_frame
		var p := player.global_position
		low = Vector2(minf(low.x, p.x), minf(low.y, p.z))
		high = Vector2(maxf(high.x, p.x), maxf(high.y, p.z))
		# Marge entre la tête et le plafond au-dessus d'elle : négative tant que le joueur reste dessous.
		top = maxf(top, p.y + 1.75 - (SHAFT_CEILING if p.z > 0.05 else CEILING))
		bottom = minf(bottom, p.y)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("jump")
	await wait(2)
	return [low, high, top, bottom]
