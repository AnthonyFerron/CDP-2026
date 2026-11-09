extends SceneTree
## Grille de marche du hub : depuis des points de départ, on propage le joueur de case en case (0,5 m) dans 8
## directions, avec son corps réel (body_test_motion, marche de 0,3 m permise). On relève :
## - les trous (aucun sol sous une case atteinte), les pentes où l'on glisse, les sorties de la vallée ;
## - les ressauts de plus de 0,4 m entre deux cases où l'on passe ;
## - les blocages : ce qui arrête le joueur, et s'il n'y a aucun maillage visible à moins de 0,5 m (mur invisible) ;
## - les maillages visibles de plus de 0,3 m, à hauteur de corps, sans aucune collision.
## Arguments : -- <livres> <fichier des zones> ; une zone par ligne : nom xmin zmin xmax zmax y x,z;x,z [x0,z0,x1,z1 de la pièce]
## Dans la pièce donnée : cases libres où l'on ne peut pas aller (poches), et plafond au-dessus de chaque case atteinte.
## Arguments : -- <livres> <fichier des zones> [dossier de sortie]. Écrit <dossier>/<nom>_<livres>.json.
## Le décor est regroupé d'un bloc (finish_all) avant la grille : les boîtes visibles viennent des « pieces » des lots.
var AGENT := "/home/ubuntu/cdp-dev/.claude/captures/verif-hub/grille/"
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
const DIRECTIONS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
## Décor sans collision voulu : fleurs, herbes, roseaux, buissons, nénuphars, tapis, eau, terrain, effets.
const PASSABLE := ["flower", "grass", "reed", "bamboo", "bush", "lily", "rug", "plant_flat", "crops_", "crop_", "moss",
	"Water", "planks", "fountain-center", "patch", "banner", "flag", "Glow", "Orb", "Fire", "Smoke", "Ember", "Spark",
	"roof", "chimney", "lantern-candle", "candle", "books", "potion", "mortar", "apple", "loaf", "bread", "cabbage",
	"carrot", "fish", "cheese", "cutting-board", "rollingPin", "bucket", "food_kit", "dirtRow", "debris", "coin",
	"shield", "stump_round", "Letter", "Circle", "Ceiling", "Beam", "canoe", "rocks-small"]

var space: PhysicsDirectSpaceState3D
var level: Node
var player: CharacterBody3D
var rid: RID
var step := 0.5
var terrain_rid: RID
var visible_boxes := {}
var capsule := CapsuleShape3D.new()
var names := {}


func _initialize() -> void:
	_run.call_deferred()


func ground(x: float, z: float, top: float, depth := 3.0) -> Dictionary:
	x += 0.013
	z += 0.017
	var ray := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, top - depth, z))
	ray.exclude = [rid]
	return space.intersect_ray(ray)


func standable(point: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), point + Vector3.UP * 0.96)
	query.exclude = [rid]
	return space.intersect_shape(query, 1).is_empty()


func collider_name(object: Object) -> String:
	if not object:
		return "?"
	var id := object.get_instance_id()
	if not names.has(id):
		var node := object as Node
		names[id] = String(level.get_path_to(node)) if node and level.is_ancestor_of(node) else str(object)
	return names[id]


func is_decor(text: String) -> bool:
	for word in PASSABLE:
		if text.contains(word):
			return true
	return false


## Boîtes des maillages visibles, rangées par case de 2 m, pour savoir si un blocage se voit.
func index_visible() -> Array:
	var boxes := []
	for node in level.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		if not geometry.is_visible_in_tree() or geometry is Label3D:
			continue
		if level.get_node("Terrain").is_ancestor_of(geometry) or player.is_ancestor_of(geometry):
			continue
		var label := String(level.get_path_to(geometry))
		if geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		if geometry.has_meta(&"pieces"):
			for piece: Array in geometry.get_meta(&"pieces"):
				boxes.append([piece[1], label + " " + str(piece[0])])
			continue
		if geometry is MultiMeshInstance3D:
			var multimesh := (geometry as MultiMeshInstance3D).multimesh
			if not multimesh or not multimesh.mesh:
				continue
			label += " " + multimesh.mesh.resource_path.get_file() + " " + multimesh.mesh.resource_name
			var local := multimesh.mesh.get_aabb()
			var count := multimesh.visible_instance_count if multimesh.visible_instance_count >= 0 else multimesh.instance_count
			for index in count:
				boxes.append([geometry.global_transform * multimesh.get_instance_transform(index) * local, label])
		elif geometry is MeshInstance3D and (geometry as MeshInstance3D).mesh:
			var owner_path := geometry.owner.scene_file_path.get_file() if geometry.owner else ""
			boxes.append([geometry.global_transform * (geometry as MeshInstance3D).get_aabb(), label + " " + owner_path])
	for entry: Array in boxes:
		var box: AABB = entry[0]
		for cx in range(floori(box.position.x / 2.0), floori(box.end.x / 2.0) + 1):
			for cz in range(floori(box.position.z / 2.0), floori(box.end.z / 2.0) + 1):
				var key := Vector2i(cx, cz)
				if not visible_boxes.has(key):
					visible_boxes[key] = []
				visible_boxes[key].append(entry)
	return boxes


func seen_near(point: Vector3, margin: float) -> bool:
	var key := Vector2i(floori(point.x / 2.0), floori(point.z / 2.0))
	for cx in range(key.x - 1, key.x + 2):
		for cz in range(key.y - 1, key.y + 2):
			for entry: Array in visible_boxes.get(Vector2i(cx, cz), []):
				if (entry[0] as AABB).grow(margin).has_point(point):
					return true
	return false


func _run() -> void:
	# Sans les options (--api=… : l'adresse morte du serveur), qui ne sont pas des arguments de la grille.
	var args := PackedStringArray()
	for entry in OS.get_cmdline_user_args():
		if not entry.begins_with("--"):
			args.append(entry)
	var books := int(args[0])
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 40:
		await physics_frame
	level = current_scene
	player = level.get_node("Player")
	# Le joueur reste dans l'espace physique (désactivé, Jolt le retirerait) : seul son traitement s'arrête.
	player.set_physics_process(false)
	player.set_process(false)
	player.set_process_unhandled_input(false)
	player.global_position = Vector3(0, 500, 0)
	await physics_frame
	await physics_frame
	rid = player.get_rid()
	capsule.radius = 0.4
	capsule.height = 1.8
	space = level.get_world_3d().direct_space_state
	if args.size() > 2:
		AGENT = args[2].trim_suffix("/") + "/"
	await physics_frame
	var props: Node = level.get_node("Props")
	props.finish_all()
	await physics_frame
	# L'abri souterrain est caché tant que le joueur est dehors : compté comme visible pour la grille.
	level.get_node("BunkerInterior").visible = true
	var boxes := index_visible()
	level.get_node("BunkerInterior").visible = false
	print("BOITES %d" % boxes.size())
	# Une zone par ligne du fichier : nom xmin zmin xmax zmax y x,z;x,z [x0,z0,x1,z1 de la pièce]
	for line in FileAccess.get_file_as_string(args[1]).split("\n", false):
		var f := line.strip_edges().split(" ", false)
		if f.size() < 7 or line.begins_with("#"):
			continue
		var seeds: Array[Vector2] = []
		for pair in f[6].split(";"):
			var values := pair.split(",")
			seeds.append(Vector2(float(values[0]), float(values[1])))
		var room := Rect2()
		if f.size() > 7:
			var r := f[7].split(",")
			room = Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
		step = float(f[8]) if f.size() > 8 else 0.5
		survey(books, f[0], Rect2(float(f[1]), float(f[2]), float(f[3]) - float(f[1]), float(f[4]) - float(f[2])), float(f[5]), seeds, room, boxes)
	state.reset()
	quit()


func survey(books: int, name: String, area: Rect2, start_y: float, seeds: Array[Vector2], room: Rect2, boxes: Array) -> void:
	var started := Time.get_ticks_msec()

	var heights := {}
	var queue: Array[Vector2i] = []
	for seed in seeds:
		var cell := Vector2i(roundi(seed.x / step), roundi(seed.y / step))
		var hit := ground(cell.x * step, cell.y * step, start_y + 1.5, 4.0)
		if hit:
			heights[cell] = hit.position.y
			queue.append(cell)
	var holes := []
	var steep := []
	var drops := []
	var slides := []
	var outside := []
	var blocked := {}
	var invisible := {}
	var params := PhysicsTestMotionParameters3D.new()
	params.margin = 0.02
	var result := PhysicsTestMotionResult3D.new()
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var y: float = heights[cell]
		var from := Vector3(cell.x * step, y, cell.y * step)
		if not HubTerrain.inside_limit(Vector2(from.x, from.z), -1.0) and from.y > -20.0:
			outside.append([from.x, from.y, from.z])
			continue
		for direction in DIRECTIONS:
			var next := cell + direction
			if heights.has(next):
				continue
			var target := Vector2(next.x * step, next.y * step)
			if not area.has_point(target):
				continue
			params.from = Transform3D(Basis(), from + Vector3.UP * 0.3)
			params.motion = Vector3(target.x - from.x, 0.0, target.y - from.z)
			if PhysicsServer3D.body_test_motion(rid, params, result):
				var point := result.get_collision_point()
				var label := collider_name(result.get_collider())
				if result.get_collider() == level.get_node("Terrain") and result.get_collision_normal().y >= 0.7:
					var rise := ground(target.x, target.y, y + 1.0, 4.0)
					if rise and rise.collider == level.get_node("Terrain") and rise.position.y - y < 0.45 and standable(rise.position):
						heights[next] = rise.position.y
						queue.append(next)
						continue
				if not blocked.has(label):
					blocked[label] = [0, [point.x, point.y, point.z]]
				blocked[label][0] += 1
				if not seen_near(point, 0.5) and not invisible.has(label + str(Vector2i(point.x, point.z))):
					invisible[label + str(Vector2i(point.x, point.z))] = [label, point.x, point.y, point.z]
				continue
			var hit := ground(target.x, target.y, y + 1.0, 4.0)
			if not hit:
				holes.append([target.x, y, target.y])
				continue
			var height: float = hit.position.y
			if not standable(hit.position):
				continue
			if height > y + 0.4:
				# Montée trop raide : seul le sol du terrain compte (un meuble trop haut se contourne).
				if hit.collider == level.get_node("Terrain"):
					steep.append([target.x, height, target.y, snappedf(height - y, 0.01)])
				continue
			if height < y - 0.4:
				drops.append([target.x, height, target.y, snappedf(height - y, 0.01), collider_name(hit.collider)])
			if (hit.normal as Vector3).y < 0.7:
				slides.append([target.x, height, target.y])
			heights[next] = height
			queue.append(next)

	# Maillages visibles, à hauteur de corps, sans aucune collision dans leur emprise.
	var bare := []
	var query := PhysicsShapeQueryParameters3D.new()
	var probe := BoxShape3D.new()
	query.shape = probe
	query.exclude = [rid]
	for entry: Array in boxes:
		var box: AABB = entry[0]
		var label: String = entry[1]
		if box.size.y < 0.3 or is_decor(label) or not area.has_point(Vector2(box.get_center().x, box.get_center().z)):
			continue
		# Sol où le joueur peut se tenir près de l'objet, d'après la grille parcourue : un objet hors d'atteinte
		# (à l'étage, sur un socle haut, dans la forêt des montagnes) n'a pas besoin de collision.
		var reach: Variant = null
		var center_cell := Vector2i(roundi(box.get_center().x / step), roundi(box.get_center().z / step))
		var span := ceili((maxf(box.size.x, box.size.z) * 0.5 + 0.8) / step)
		for dx in range(-span, span + 1):
			for dz in range(-span, span + 1):
				var near_cell := center_cell + Vector2i(dx, dz)
				if heights.has(near_cell) and float(heights[near_cell]) <= box.position.y + 0.6:
					reach = float(heights[near_cell]) if reach == null else maxf(reach, float(heights[near_cell]))
		if reach == null:
			continue
		# Hors de la vallée (forêt des montagnes) : derrière la limite, hors de portée.
		if not HubTerrain.inside_limit(Vector2(box.get_center().x, box.get_center().z), 0.5) and box.position.y > -20.0:
			continue
		var base: float = reach
		if box.position.y > base + 1.5 or box.size.x > 30.0 or box.size.z > 30.0:
			continue
		var low := maxf(box.position.y, base) + 0.15
		var high := minf(box.end.y, base + 1.7)
		if high - low < 0.15:
			continue
		probe.size = Vector3(maxf(box.size.x * 0.6, 0.05), high - low, maxf(box.size.z * 0.6, 0.05))
		query.transform = Transform3D(Basis(), Vector3(box.get_center().x, (low + high) * 0.5, box.get_center().z))
		var hits := space.intersect_shape(query, 4)
		var solid := false
		for hit in hits:
			if hit.collider is CollisionObject3D and not (hit.collider is Area3D):
				solid = true
		if not solid:
			bare.append([label, snappedf(box.get_center().x, 0.1), snappedf(box.position.y, 0.1), snappedf(box.get_center().z, 0.1),
				snappedf(box.size.x, 0.1), snappedf(box.size.y, 0.1), snappedf(box.size.z, 0.1)])

	# Pièce : cases libres (le joueur y tient debout) que la grille n'atteint pas, et plafond au-dessus des cases atteintes.
	var pockets := []
	var open_ceiling := []
	var low_ceiling := []
	if room.size.x > 0.0:
		for cx in range(ceili(room.position.x / step), floori(room.end.x / step) + 1):
			for cz in range(ceili(room.position.y / step), floori(room.end.y / step) + 1):
				var cell := Vector2i(cx, cz)
				var point := Vector2(cx * step, cz * step)
				if heights.has(cell):
					var y0: float = heights[cell]
					var up := PhysicsRayQueryParameters3D.create(Vector3(point.x + 0.013, y0 + 1.0, point.y + 0.017), Vector3(point.x + 0.013, y0 + 6.0, point.y + 0.017))
					up.exclude = [rid]
					var top := space.intersect_ray(up)
					if top.is_empty():
						open_ceiling.append([point.x, y0, point.y])
					elif top.position.y - y0 < 2.0:
						low_ceiling.append([point.x, y0, point.y, snappedf(top.position.y - y0, 0.01), collider_name(top.collider)])
					continue
				var floor_hit := ground(point.x, point.y, start_y + 0.6, 1.5)
				if floor_hit and floor_hit.position.y < start_y + 0.2 and standable(floor_hit.position):
					pockets.append([point.x, floor_hit.position.y, point.y])
	var report := {"cases": heights.size(), "poches": pockets, "plafond_ouvert": open_ceiling, "plafond_bas": low_ceiling, "trous": holes, "ressauts": steep, "chutes": drops, "glissades": slides, "hors_vallee": outside,
		"blocages": blocked, "murs_invisibles": invisible.values(), "sans_collision": bare,
		"duree_ms": Time.get_ticks_msec() - started}
	DirAccess.make_dir_recursive_absolute(AGENT)
	var file := FileAccess.open(AGENT + "%s_%d.json" % [name, books], FileAccess.WRITE)
	file.store_string(JSON.stringify(report, " "))
	file.close()
	print("RESUME %s %d livres : %d cases, %d trous, %d ressauts, %d chutes, %d glissades, %d hors vallee, %d murs invisibles, %d sans collision, %d poches, %d plafond ouvert, %d plafond bas, %d ms" % [
		name, books, heights.size(), holes.size(), steep.size(), drops.size(), slides.size(), outside.size(), invisible.size(), bare.size(),
		pockets.size(), open_ceiling.size(), low_ceiling.size(), report.duree_ms])
