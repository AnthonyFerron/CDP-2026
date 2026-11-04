extends SceneTree
## Sonde : -- x z [rayon] : collisions trouvées par des rayons verticaux autour du point, tous les 0,5 m.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.get_node("GameState").reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	for i in 30:
		await physics_frame
	var level: Node3D = current_scene
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var x0 := float(args[0])
	var z0 := float(args[1])
	var top := float(args[2]) if args.size() > 2 else 6.0
	for dx in [-0.5, 0.0, 0.5]:
		for dz in [-0.5, 0.0, 0.5]:
			var from := Vector3(x0 + dx, top, z0 + dz)
			var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 12.0)
			var hit: Dictionary = space.intersect_ray(ray)
			if hit.is_empty():
				print("(%.1f, %.1f) : rien" % [from.x, from.z])
			else:
				var node: Node = hit.collider
				var shape := ""
				if node is CollisionObject3D:
					var owner_id := (node as CollisionObject3D).shape_find_owner(hit.shape)
					var owner_node := (node as CollisionObject3D).shape_owner_get_owner(owner_id)
					shape = String(owner_node.name) if owner_node else ""
				print("(%.1f, %.1f) : y %.2f normale %s %s/%s" % [from.x, from.z, hit.position.y, (hit.normal as Vector3).snappedf(0.01), level.get_path_to(node), shape])
	quit()
