extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Planches de captures à hauteur d'yeux (« ++ dedans » ou « ++ dehors », puis « ++ premier dernier » pour un lot) :
## - dedans : tous les 4 m environ (x -3,5 / 0 / 3,5, z tous les 4 m), 8 directions, deux points par planche ;
##   puis les coins de chaque salle et les plafonds ;
## - dehors : tous les 4 m sur les lieux garnis (ruines, chemin, pont, camp, tombes, siège, tour, batterie, rives des
##   lacs), tous les 16 m ailleurs ; 4 directions de 96° (le tour complet), quatre points par planche ;
##   puis les raccords vus de près.
## Chaque vue est aussi gardée en 640 x 360 (jpg) ; la planche les réduit à 320 x 180.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/passe/"
const THUMB := Vector2i(320, 180)

var camera: Camera3D
var space: PhysicsDirectSpaceState3D
var inside := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	inside = args.has("dedans")
	var numbers: Array[int] = []
	for arg in args:
		if arg.is_valid_int():
			numbers.append(int(arg))
	DirAccess.make_dir_recursive_absolute(OUT + ("dedans/" if inside else "dehors/"))
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	paused = false
	space = level.get_world_3d().direct_space_state
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	for child in level.get_node("Hud").get_children():
		if child is CanvasItem:
			child.visible = false
	camera = Camera3D.new()
	camera.near = 0.05
	camera.far = 400.0
	level.add_child(camera)
	camera.current = true
	if inside:
		level._inside = true
		level._apply_location()
		var stone: Node3D = level.get_node("Interior/Stone")
		stone.position.x -= level.stone_travel
	await wait(10)

	var sheets: Array = _inside_sheets() if inside else _outside_sheets()
	var first := numbers[0] if numbers.size() > 0 else 0
	var last := numbers[1] if numbers.size() > 1 else sheets.size() - 1
	print("planches : %d (lot %d à %d)" % [sheets.size(), first, last])
	for index in range(first, mini(last, sheets.size() - 1) + 1):
		var sheet: Dictionary = sheets[index]
		var image := Image.create(THUMB.x * 4, THUMB.y * 4, false, Image.FORMAT_RGB8)
		var slot := 0
		for view: Array in sheet.views:
			var shot := await _shoot(view[0], view[1], view[2], view[3])
			shot.save_jpg(OUT + ("dedans/" if inside else "dehors/") + "%02d_%02d.jpg" % [index, slot], 0.85)
			shot.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_BILINEAR)
			image.blit_rect(shot, Rect2i(Vector2i.ZERO, THUMB), Vector2i(slot % 4 * THUMB.x, slot / 4 * THUMB.y))
			slot += 1
		image.save_png(OUT + "%s_%02d.png" % ["dedans" if inside else "dehors", index])
		print("planche %02d : %s" % [index, sheet.label])
	finish()


## Une vue : la caméra à hauteur d'yeux au-dessus du sol trouvé sous (x, z), tournée de yaw degrés (0 = vers -z),
## inclinée de pitch degrés, avec un champ vertical de fov degrés.
func _shoot(at: Vector3, yaw: float, pitch: float, fov: float) -> Image:
	# Le menu de pause s'ouvre quand la fenêtre perd le focus : ni pause, ni menu sur les captures.
	paused = false
	var menu := root.get_node_or_null("PauseMenu")
	if menu is CanvasLayer:
		(menu as CanvasLayer).visible = false
		menu.process_mode = Node.PROCESS_MODE_DISABLED
	camera.fov = fov
	camera.global_transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0)), at)
	for i in 3:
		paused = false
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	if shot.get_size() != Vector2i(640, 360):
		shot.resize(640, 360, Image.INTERPOLATE_BILINEAR)
	return shot


## Sol sous (x, z) et place libre pour un joueur, en s'écartant au besoin par pas de 0,5 m ; null si aucune.
func _eye(x: float, z: float, top: float, bottom: float, terrain_only: bool) -> Variant:
	for ring in 5:
		for k in maxi(1, ring * 8):
			var angle := TAU * k / maxi(1, ring * 8)
			var px := x + cos(angle) * ring * 0.5
			var pz := z + sin(angle) * ring * 0.5
			var query := PhysicsRayQueryParameters3D.create(Vector3(px, top, pz), Vector3(px, bottom, pz), 1)
			query.exclude = [player.get_rid()]
			var hit: Dictionary = space.intersect_ray(query)
			if hit.is_empty() or hit.normal.y < 0.7:
				continue
			# Le sol, pas le dessus d'un meuble ou d'un rocher : le terrain ou le tablier du pont dehors, les dalles dedans.
			var y: float = hit.position.y
			if terrain_only and not String(level.get_path_to(hit.collider)).contains("Terrain") \
					and not (absf(px) < 1.8 and pz > 23.0 and pz < 36.0 and y < 0.2):
				continue
			if not terrain_only and absf(y + 40.0) > 0.05 and absf(y + 41.0) > 0.05 and not (pz < -36.6 and pz > -38.6):
				continue
			var shape := CapsuleShape3D.new()
			shape.radius = 0.4
			shape.height = 1.8
			var test := PhysicsShapeQueryParameters3D.new()
			test.shape = shape
			test.transform = Transform3D(Basis(), hit.position + Vector3.UP * 1.05)
			test.exclude = [player.get_rid()]
			if space.intersect_shape(test, 1).is_empty():
				return hit.position + Vector3.UP * 1.65
	return null


func _inside_sheets() -> Array:
	var points: Array[Vector3] = []
	for k in 9:
		var z := -2.0 - 4.0 * k
		for x in [-3.5, 0.0, 3.5]:
			var top := -36.3
			var eye: Variant = _eye(x, z, top, -42.5, false)
			if eye != null:
				points.append(eye)
	for spot in [Vector2(0, -36.5), Vector2(0, -37.6), Vector2(0, -38.9), Vector2(0, -42.6)]:
		var eye: Variant = _eye(spot.x, spot.y, -37.1, -42.5, false)
		if eye != null:
			points.append(eye)
	var sheets := []
	for i in range(0, points.size(), 2):
		var views := []
		var label := ""
		for point in points.slice(i, i + 2):
			label += "(%.1f, %.1f) " % [point.x, point.z]
			for d in 8:
				views.append([point, -45.0 * d, -5.0, 62.0])
		sheets.append({views = views, label = label + "— 8 directions chacun, de -z en tournant vers +x"})
	# Coins de chaque salle, regardés en biais, et plafonds.
	var corners := []
	for room in 3:
		# Murs du bout de chaque salle : celui de l'entrée (côté +z) et celui du fond (côté -z).
		for wall_z in [-12.0 * room, -12.0 * (room + 1)]:
			var inward := -1.0 if wall_z == -12.0 * room else 1.0
			for side in [-1.0, 1.0]:
				corners.append(_corner_view(side, wall_z, inward))
	corners = corners.filter(func(view: Variant) -> bool: return view != null)
	sheets.append({views = corners, label = "coins des trois salles (lecture, scriptorium, archives), vers le haut des murs"})
	var ceilings := []
	for z in [-6.0, -18.0, -30.0]:
		for yaw in [0.0, 180.0]:
			ceilings.append([Vector3(0, -38.35, z), yaw, 65.0, 75.0])
	for spot in [Vector3(0, -38.35, -36.5), Vector3(0, -39.4, -40.5)]:
		for yaw in [0.0, 180.0]:
			ceilings.append([spot, yaw, 55.0, 75.0])
	for side in [-1.0, 1.0]:
		ceilings.append([Vector3(side * 1.0, -39.4, -38.6), 180.0 + side * 30.0, -10.0, 70.0])
		ceilings.append([Vector3(side * 0.8, -38.35, -35.2), 180.0 - side * 20.0, -15.0, 70.0])
	sheets.append({views = ceilings, label = "plafonds des salles, du passage et de la petite salle ; pied et haut de l'escalier"})
	return sheets


## Vue d'un coin : à 2,5 m du mur du bout et 2,6 m du mur de côté, tournée vers le coin, un peu vers le haut.
func _corner_view(side: float, wall_z: float, inward: float) -> Variant:
	var eye: Variant = _eye(side * 2.9, wall_z + inward * 2.5, -36.3, -42.5, false)
	if eye == null:
		return null
	var target := Vector3(side * 5.5, -38.0, wall_z)
	var flat: Vector2 = Vector2(target.x - eye.x, target.z - eye.z)
	print("coin : œil %s, cible %s" % [eye, target])
	return [eye, rad_to_deg(atan2(-flat.x, -flat.y)), 12.0, 70.0]


func _outside_sheets() -> Array:
	var terrain := level.get_node("Exterior/Terrain") as PlaineTerrain
	var spots: Array[Vector2] = []
	var add := func(x: float, z: float) -> void:
		var spot := Vector2(snappedf(x, 0.1), snappedf(z, 0.1))
		if spot.length() < 63.0 and not spots.has(spot):
			spots.append(spot)
	for site in PlaineTerrain.SITES:
		var n := int((site.z + 2.0) / 4.0)
		for i in range(-n, n + 1):
			for j in range(-n, n + 1):
				if Vector2(i, j).length() * 4.0 <= site.z + 2.0:
					add.call(site.x + i * 4.0, site.y + j * 4.0)
	for z in range(10, 58, 4):
		add.call(0.0, z)
	for x in range(-12, 13, 4):
		add.call(x, 12.0)
		add.call(x, -16.0)
	for z in range(-12, 12, 4):
		add.call(-14.0, z)
		add.call(14.0, z)
	for crater in PlaineTerrain.CRATERS:
		var away := -Vector2(crater.x, crater.y).normalized()
		var spot := Vector2(crater.x, crater.y) + away * (crater.z * PlaineTerrain.LAVA_RATIO + 3.5)
		add.call(spot.x, spot.y)
	var content := spots.size()
	for x in range(-64, 65, 16):
		for z in range(-64, 65, 16):
			var spot := Vector2(x, z)
			if spot.length() >= 60.0:
				continue
			var far := true
			for other in spots:
				if other.distance_to(spot) < 8.0:
					far = false
					break
			if far:
				add.call(x, z)
	print("points dehors : %d sur les lieux garnis, %d en tout" % [content, spots.size()])
	var eyes: Array[Vector3] = []
	for spot in spots:
		var eye: Variant = _eye(spot.x, spot.y, 30.0, -15.0, true)
		if eye != null and not (level.get_node("Exterior/Scatter") as PlaineScatter).is_near_lava(eye, 1.0):
			eyes.append(eye)
	var sheets := []
	for i in range(0, eyes.size(), 4):
		var views := []
		var label := ""
		for eye in eyes.slice(i, i + 4):
			label += "(%.0f, %.0f) " % [eye.x, eye.z]
			for d in 4:
				views.append([eye, -90.0 * d, -6.0, 62.0])
		sheets.append({views = views, label = label + "— une ligne par point : vers -z, +x, +z, -x"})
	# Raccords vus de près : bouts du pont, porte et pied des ruines, portail, lanternes, rives.
	var joints := []
	for z in [22.6, 36.4]:
		for x in [-1.2, 1.2]:
			joints.append([Vector3(x * 2.4, terrain.surface_height(x * 2.4, z) + 1.2, z + (-2.0 if z > 30 else 2.0)),
				180.0 if z > 30 else 0.0, -28.0, 60.0])
	joints.append([Vector3(0, 1.4, 11.0), 0.0, -12.0, 60.0])
	joints.append([Vector3(-6.0, 1.4, 11.5), 20.0, -15.0, 60.0])
	joints.append([Vector3(6.0, 1.4, 11.5), -20.0, -15.0, 60.0])
	joints.append([Vector3(0, 1.6, 52.5), 180.0, -8.0, 60.0])
	joints.append([Vector3(-1.5, 1.6, 59.5), 0.0, -8.0, 60.0])
	for crater: Vector4 in [PlaineTerrain.CRATERS[1], PlaineTerrain.CRATERS[0], PlaineTerrain.CRATERS[4], PlaineTerrain.CRATERS[2]]:
		var away := -Vector2(crater.x, crater.y).normalized()
		var spot := Vector2(crater.x, crater.y) + away * (crater.z * PlaineTerrain.LAVA_RATIO + 2.5)
		var flat := Vector2(crater.x, crater.y) - spot
		joints.append([Vector3(spot.x, terrain.surface_height(spot.x, spot.y) + 1.6, spot.y),
			rad_to_deg(atan2(-flat.x, -flat.y)), -30.0, 60.0])
	sheets.append({views = joints, label = "raccords : bouts du pont, porte et pied des ruines, portail, rives de quatre lacs"})
	return sheets
