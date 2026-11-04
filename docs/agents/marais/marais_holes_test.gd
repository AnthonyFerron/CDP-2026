extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Jours dans la crypte : depuis des points de chaque pièce, à plusieurs hauteurs, 200 rayons dans toutes les
## directions. Dans une crypte close, chaque rayon doit toucher un maillage visible avant 40 m : un rayon qui file
## dans le vide montre un jour entre deux murs, un plafond ou un sol. On teste les maillages (pas les collisions),
## en lançant les rayons contre les triangles des modèles via des collisions temporaires.

const POINTS := [
	Vector3(0, 1.6, 0), Vector3(0, 1.0, 3.0), Vector3(0, 2.5, 5.0), Vector3(0, 3.5, 7.0), Vector3(0, 5.0, 9.0), Vector3(0, 5.7, 12.0),
	Vector3(-6, 1.6, -5), Vector3(0, 1.6, -12), Vector3(6, 1.6, -19), Vector3(-6, 3.5, -19), Vector3(6, 3.5, -5),
	Vector3(-12, 1.6, -12), Vector3(12, 1.6, -12), Vector3(-24, 1.6, -12), Vector3(24, 1.6, -12), Vector3(-27, 3.2, -8),
	Vector3(27, 3.2, -16), Vector3(-12, 1.6, -2), Vector3(-18, 1.6, 2), Vector3(12, 1.6, -2), Vector3(18, 1.6, 2),
]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/marais/marais.tscn")
	level.set("_inside", true)
	level.call("_apply_location")
	var interior: Node3D = level.get_node("Interior")
	# Collisions temporaires, à la forme exacte de chaque maillage de la crypte.
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 19
	body.collision_mask = 0
	level.add_child(body)
	var count := 0
	for node in interior.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not mesh.mesh or not mesh.is_visible_in_tree():
			continue
		var faces := mesh.mesh.get_faces()
		if faces.is_empty():
			continue
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(faces)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		collision.global_transform = mesh.global_transform
		count += 1
	# Le décor fixe de la crypte est regroupé en MultiMesh (MaraisBatch) : une collision par instance.
	for node in interior.find_children("Batch_*", "MultiMeshInstance3D", true, false):
		var batch := node as MultiMeshInstance3D
		var batch_faces := batch.multimesh.mesh.get_faces()
		if batch_faces.is_empty():
			continue
		var batch_shape := ConcavePolygonShape3D.new()
		batch_shape.backface_collision = true
		batch_shape.set_faces(batch_faces)
		for place: Transform3D in batch.get_meta(&"transforms"):
			var piece := CollisionShape3D.new()
			piece.shape = batch_shape
			body.add_child(piece)
			piece.global_transform = place
			count += 1
	await wait(3)
	var space := player.get_world_3d().direct_space_state
	var leaks := 0
	for point: Vector3 in POINTS:
		var origin := point + Vector3(0, -40, 0)
		for i in 200:
			# Directions réparties sur la sphère (spirale de Fibonacci).
			var y := 1.0 - (i + 0.5) / 100.0
			var radius := sqrt(maxf(0.0, 1.0 - y * y))
			var angle := i * 2.39996
			var direction := Vector3(cos(angle) * radius, y, sin(angle) * radius)
			var ray := PhysicsRayQueryParameters3D.create(origin, origin + direction * 40.0, 1 << 19)
			var hit := space.intersect_ray(ray)
			if hit.is_empty():
				leaks += 1
				if leaks <= 30:
					print("  jour : depuis %s vers %s" % [point, direction.snappedf(0.01)])
	check("crypte close : %d maillages, %d rayons perdus sur %d" % [count, leaks, POINTS.size() * 200], leaks == 0)
	finish()
