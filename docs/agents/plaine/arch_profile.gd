extends "res://tests/scenes/common_test.gd"
## Portes voûtées (fantasy_town_kit/wall-doorway-round) d'un lieu : profil de la collision comparé à l'arche visible.
## Pour chaque arche, des rayons partent du milieu de l'ouverture vers chaque montant, tous les 2,5 cm de 0,11 à 2,89 m
## au-dessus du pied du mur, au milieu de l'épaisseur du mur et à ±0,15 m. Le maillage visible de l'arche est
## recopié en fantôme sur une couche à part (les lieux fondent leur décor) ; la collision est celle du jeu.
##   mur invisible : la collision arrête le rayon avant l'arche visible ;
##   entrée : le rayon entre dans l'arche visible avant que la collision ne l'arrête.
##   godot --headless --path frontend --script <ce fichier> -- <village|plaine> [seuil] --api=...

const GHOST_LAYER := 1 << 19
const MODEL := "res://assets/models/kenney/fantasy_town_kit/wall-doorway-round.glb"

var space: PhysicsDirectSpaceState3D
var ghosts: StaticBody3D
var problems: Array[String] = []
var worst_wall := 0.0
var worst_entry := 0.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	var place: String = args[0] if not args.is_empty() else "village"
	var limit := float(args[1]) if args.size() > 1 else 0.05
	await start_level("res://scenes/levels/%s/%s.tscn" % [place, place])
	for name in ["PauseMenu", "Pause"]:
		if root.has_node(name):
			root.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
	space = player.get_world_3d().direct_space_state
	await wait(10)
	# Chaque arche : [nom, transformation du modèle dans le monde].
	var arches := []
	if place == "village":
		var props: Node3D = level.get_node("Props")
		var copy := (load("res://scenes/levels/village/village_props.tscn") as PackedScene).instantiate()
		var list: Array = copy.get_node("Instances/fantasy_town_kit_wall_doorway_round").get("transforms")
		for index in list.size():
			arches.append(["maison, arche %d" % index, props.global_transform * (list[index] as Transform3D)])
		copy.free()
		_scene_arches(arches, level.get_node("Interior/Hall"), "res://scenes/levels/village/village_hall.tscn", "mairie")
	else:
		_scene_arches(arches, level.get_node("Interior/Library"), "res://scenes/levels/plaine/library_interior.tscn", "archives")
	ghosts = StaticBody3D.new()
	ghosts.collision_layer = GHOST_LAYER
	ghosts.collision_mask = 0
	level.add_child(ghosts)
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	root.add_child(model)
	var parts := []
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		parts.append([model.global_transform.affine_inverse() * mesh.global_transform, mesh.mesh.get_faces()])
	model.queue_free()
	for arch: Array in arches:
		var xform: Transform3D = arch[1]
		var faces := PackedVector3Array()
		for part: Array in parts:
			for vertex: Vector3 in part[1]:
				faces.append(xform * (part[0] as Transform3D) * vertex)
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		shape.backface_collision = true
		var collision := CollisionShape3D.new()
		collision.shape = shape
		ghosts.add_child(collision)
	await physics_frame
	await physics_frame
	print("%s : %d arches" % [place, arches.size()])
	for arch: Array in arches:
		profile(arch[0], arch[1], limit)
	print("PIRE mur invisible %.3f m, entrée %.3f m" % [worst_wall, worst_entry])
	for line in problems:
		print("PROBLEME " + line)
	check("arches de %s : écart au plus %.2f m" % [place, limit], problems.is_empty())
	finish()


func _scene_arches(arches: Array, holder: Node3D, path: String, label: String) -> void:
	var copy := (load(path) as PackedScene).instantiate()
	for node in copy.get_node("Models").get_children():
		if String(node.name).begins_with("wall_doorway_round"):
			arches.append(["%s, %s" % [label, node.name], holder.global_transform * (node as Node3D).transform])
	copy.free()


func profile(label: String, xform: Transform3D, limit: float) -> void:
	# Le mur du modèle est à x = 0,4..0,5 (échelle 1), son ouverture centrée en z = 0.
	var center := xform * Vector3(0.45, 0, 0)
	var out := xform.basis.x.normalized()
	var along := xform.basis.z.normalized()
	var wall := 0.0
	var entry := 0.0
	var wall_at := 0.0
	var entry_at := 0.0
	# Hauteurs décalées de 13 mm des multiples de 5 cm : un rayon posé pile sur la face d'une boîte la manque.
	for step in range(0, 112):
		var h := 0.113 + step * 0.025
		for depth: float in [-0.15, 0.0, 0.15]:
			for sign: float in [-1.0, 1.0]:
				var from: Vector3 = center + Vector3.UP * h + out * depth
				var to: Vector3 = from + along * sign * 1.6
				var solid := _cast(from, to, 1)
				var seen := _cast(from, to, GHOST_LAYER)
				if seen < 0.0 or solid < 0.0:
					continue
				if seen - solid > wall:
					wall = seen - solid
					wall_at = h
				if solid - seen > entry:
					entry = solid - seen
					entry_at = h
	print("%s (%s) : mur invisible au plus %.3f m (à %.2f m), entrée dans l'arche au plus %.3f m (à %.2f m)" % [
		label, center.snappedf(0.1), wall, wall_at, entry, entry_at])
	worst_wall = maxf(worst_wall, wall)
	worst_entry = maxf(worst_entry, entry)
	if wall > limit or entry > limit:
		problems.append("%s : mur invisible %.3f m à %.2f m, entrée %.3f m à %.2f m" % [label, wall, wall_at, entry, entry_at])


func _cast(from: Vector3, to: Vector3, mask: int) -> float:
	var ray := PhysicsRayQueryParameters3D.create(from, to, mask)
	ray.exclude = [player.get_rid()]
	ray.hit_back_faces = true
	var hit := space.intersect_ray(ray)
	return from.distance_to(hit.position) if not hit.is_empty() else -1.0
