extends SceneTree
## Tournées des villageois après la victoire, jouées image par image (--fixed-fps 60) : à chaque pas de physique, pour
## chaque villageois, on relève
## - s'il traverse quelque chose : un cylindre de 0,3 m de rayon, de 0,35 à 1,7 m au-dessus de ses pieds, contre les
##   collisions (son propre corps, le joueur et les autres villageois exceptés ; ceux-ci comptés à part) ;
## - s'il flotte ou s'enfonce : le premier sol sous lui (rayon) contre la hauteur de ses pieds (écart de plus de 8 cm) ;
## - s'il reste bloqué : en marche, sans céder le passage, et moins de 5 cm parcourus en une seconde ;
## et le nombre de tournées faites. Puis, à chaque pause (son corps y revient), s'il ferme un passage au joueur :
## grille de marche (0,25 m) autour de la pause, avec et sans son corps ; une case perdue hors de son emprise est un
## passage fermé. Arguments : -- <tournées> <feu|pause>. « feu » : départ du feu, comme après la cinématique.
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
const DIRECTIONS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var level: Node3D
var villagers: Node
var space: PhysicsDirectSpaceState3D
var player: CharacterBody3D
var terrain: Node
var bodies: Array[RID] = []
var names := {}


func _initialize() -> void:
	_run.call_deferred()


func label(object: Object) -> String:
	if object is Node and level.is_ancestor_of(object):
		return String(level.get_path_to(object as Node))
	return str(object)


func _run() -> void:
	var args := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			args.append(a)
	var cycles := int(args[0])
	var from_fire := args.size() > 1 and args[1] == "feu"
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	for index in 4:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 30:
		await physics_frame
	level = current_scene
	level.get_node("Props").finish_all()
	villagers = level.get_node("Villagers")
	terrain = level.get_node("Terrain")
	player = level.get_node("Player")
	# Le joueur reste dans l'espace physique (désactivé, Jolt le retirerait, et les grilles de marche des pauses ne
	# buteraient sur rien) : seul son traitement s'arrête, loin des villageois.
	player.set_physics_process(false)
	player.set_process(false)
	player.set_process_unhandled_input(false)
	player.global_position = Vector3(0, 400, 0)
	space = level.get_world_3d().direct_space_state
	if from_fire:
		villagers.stop()
		level.call("_release_survivors")
		villagers.start(true)
	var walkers: Array = villagers.get("_walkers")
	for walker in walkers:
		var body := walker.node.get_node_or_null("Body") as CollisionObject3D
		if body:
			bodies.append(body.get_rid())
	print("VILLAGEOIS %d, départ %s" % [walkers.size(), "du feu" if from_fire else "à la première pause"])
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.3
	cylinder.height = 1.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = cylinder
	var through := {}
	var crossing := {}
	var floating := {}
	var stuck := {}
	var done := {}
	var last_index := {}
	var last_place := {}
	var still := {}
	var frames := 0
	var report_at := {}
	# Au plus 40 minutes de jeu.
	while frames < 60 * 60 * 40:
		await physics_frame
		frames += 1
		var finished := true
		for walker in walkers:
			var node: Node3D = walker.node
			var name := String(node.name)
			var feet := node.global_position
			# Tournées : l'index repasse en arrière quand la tournée reprend.
			if last_index.has(name) and walker.index < last_index[name]:
				done[name] = done.get(name, 0) + 1
				print("TOURNEE %s %d faite à %.0f s" % [name, done[name], frames / 60.0])
				if done[name] == 1 or done[name] == cycles:
					report_at["%s_%d" % [name, done[name]]] = [through.size(), floating.size(), stuck.size(), crossing.size()]
			last_index[name] = walker.index
			if done.get(name, 0) < cycles:
				finished = false
			var own: RID = (node.get_node("Body") as CollisionObject3D).get_rid() if node.has_node("Body") else RID()
			query.exclude = [player.get_rid()] + bodies
			query.transform = Transform3D(Basis(), feet + Vector3(0, 0.35 + cylinder.height * 0.5, 0))
			for hit in space.intersect_shape(query, 4):
				var key := "%s %s %s" % [name, label(hit.collider), Vector2i(roundi(feet.x), roundi(feet.z))]
				if not through.has(key):
					through[key] = true
					print("TRAVERSE %s %s à %s (%s)" % [name, label(hit.collider), feet.snappedf(0.1), "marche" if walker.walking else "pause"])
			# Les autres villageois à leurs pauses (corps actif) : un villageois qui marche ne doit pas les traverser.
			var others: Array[RID] = []
			for rid in bodies:
				if rid != own:
					others.append(rid)
			if walker.walking:
				for other in walkers:
					if other == walker or other.walking:
						continue
					var apart := Vector2(other.node.global_position.x - feet.x, other.node.global_position.z - feet.z).length()
					if apart < 0.7:
						var key := "%s %s %s" % [name, other.node.name, Vector2i(roundi(feet.x), roundi(feet.z))]
						if not crossing.has(key):
							crossing[key] = true
							print("CROISE %s traverse %s à %s" % [name, other.node.name, feet.snappedf(0.1)])
			# Sol sous les pieds.
			# Décalé de quelques millimètres : un rayon pile sur une arête du sol maillé (points de passage ronds) le manque.
			var ray := PhysicsRayQueryParameters3D.create(feet + Vector3(0.007, 1.2, 0.011), feet + Vector3(0.007, -1.5, 0.011))
			ray.exclude = [player.get_rid()] + bodies
			var hit := space.intersect_ray(ray)
			var gap: float = INF if hit.is_empty() else feet.y - float(hit.position.y)
			if absf(gap) > 0.08:
				var key := "%s %s" % [name, Vector2i(roundi(feet.x * 2), roundi(feet.z * 2))]
				if not floating.has(key):
					floating[key] = true
					print("SOL %s à %s : écart %.2f m (%s)" % [name, feet.snappedf(0.1), gap, label(hit.collider) if not hit.is_empty() else "rien"])
			# Bloqué : en marche, sans céder le passage, immobile une seconde.
			if walker.walking and not walker.yielding:
				var flat := Vector2(feet.x, feet.z)
				if not last_place.has(name) or flat.distance_to(last_place[name]) > 0.05:
					last_place[name] = flat
					still[name] = 0
				else:
					still[name] = still.get(name, 0) + 1
					if still[name] == 60:
						stuck["%s %s" % [name, flat]] = true
						print("BLOQUE %s à %s" % [name, feet.snappedf(0.1)])
			else:
				still[name] = 0
				last_place.erase(name)
		if finished:
			break
	print("BILAN %d tournées (%.0f s de jeu) : %d traversées, %d croisements, %d écarts au sol, %d blocages" % [
		cycles, frames / 60.0, through.size(), crossing.size(), floating.size(), stuck.size()])
	for key in report_at:
		print("APRES %s : traversées %d, écarts %d, blocages %d, croisements %d" % [key, report_at[key][0], report_at[key][1], report_at[key][2], report_at[key][3]])
	for walker in walkers:
		print("FAITES %s %d" % [walker.node.name, done.get(String(walker.node.name), 0)])
	await check_pauses(walkers)
	state.reset()
	quit()


## Chaque pause : le villageois y est posé avec son corps ; grille de marche autour, avec et sans lui.
func check_pauses(walkers: Array) -> void:
	villagers.set_process(false)
	var closed := 0
	for walker in walkers:
		var node: Node3D = walker.node
		var shape := walker.shape as CollisionShape3D
		for entry: Array in walker.entries:
			if entry.size() <= 2:
				continue
			var spot := Vector2(entry[0], entry[1])
			node.global_position = Vector3(spot.x, terrain.surface_height(spot.x, spot.y), spot.y)
			# Les autres villageois loin, sans corps.
			for other in walkers:
				if other != walker:
					other.node.global_position = Vector3(0, -300, 0)
			shape.disabled = true
			await physics_frame
			await physics_frame
			var free := reach(spot)
			shape.disabled = false
			await physics_frame
			await physics_frame
			var blocked := reach(spot)
			var lost := 0
			for cell: Vector2i in free:
				if not blocked.has(cell) and Vector2(cell).distance_to(spot / 0.25) * 0.25 > 1.2:
					lost += 1
			print("PAUSE %s (%.1f, %.1f) : %d cases sans lui, %d avec, %d perdues hors de son emprise" % [node.name, spot.x, spot.y, free.size(), blocked.size(), lost])
			if lost > 0:
				closed += 1
	print("PAUSES : %d passage(s) fermé(s)" % closed)


## Cases (0,25 m) atteintes à pied depuis un point à 6 m de la pause, dans un rayon de 7 m.
func reach(center: Vector2) -> Dictionary:
	var step := 0.25
	var rid := player.get_rid()
	var params := PhysicsTestMotionParameters3D.new()
	params.margin = 0.02
	var result := PhysicsTestMotionResult3D.new()
	var heights := {}
	var queue: Array[Vector2i] = []
	for angle in 8:
		var seed := center + Vector2.from_angle(TAU * angle / 8.0) * 6.0
		var cell := Vector2i(roundi(seed.x / step), roundi(seed.y / step))
		var y := floor_at(cell.x * step, cell.y * step)
		if not is_nan(y) and not heights.has(cell):
			heights[cell] = y
			queue.append(cell)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var from := Vector3(cell.x * step, heights[cell], cell.y * step)
		for direction in DIRECTIONS:
			var next := cell + direction
			if heights.has(next) or Vector2(next).distance_to(center / step) * step > 7.0:
				continue
			params.from = Transform3D(Basis(), from + Vector3.UP * 0.3)
			params.motion = Vector3(direction.x * step, 0.0, direction.y * step)
			if PhysicsServer3D.body_test_motion(rid, params, result):
				if result.get_collider() != terrain or result.get_collision_normal().y < 0.7:
					continue
			var y := floor_at(next.x * step, next.y * step)
			if is_nan(y) or absf(y - from.y) > 0.4:
				continue
			heights[next] = y
			queue.append(next)
	return heights


func floor_at(x: float, z: float) -> float:
	var top: float = terrain.surface_height(x, z) + 1.0
	var ray := PhysicsRayQueryParameters3D.create(Vector3(x + 0.013, top, z + 0.017), Vector3(x + 0.013, top - 3.0, z + 0.017))
	ray.exclude = [player.get_rid()]
	var hit := space.intersect_ray(ray)
	return NAN if hit.is_empty() else hit.position.y
