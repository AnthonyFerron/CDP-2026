extends "res://tests/scenes/common_test.gd"
## Sonde des marches : autour de chaque point, carte des hauteurs du sol (pas de 0,25 m) et collisionneurs touchés.

const POINTS := [Vector2(-44, -9), Vector2(-55, -8), Vector2(-15, -42), Vector2(-6, -56)]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	await wait(5)
	var space := player.get_world_3d().direct_space_state
	var terrain: Node = level.get_node("Exterior/Terrain")
	for center: Vector2 in POINTS:
		print("SONDE autour de %s" % center)
		var seen := {}
		for j in range(-6, 7):
			var row := ""
			for i in range(-6, 7):
				var x := center.x + i * 0.25
				var z := center.y + j * 0.25
				var top: float = terrain.surface_height(x, z)
				var query := PhysicsRayQueryParameters3D.create(Vector3(x, top + 3.0, z), Vector3(x, top - 1.0, z))
				query.exclude = [player.get_rid()]
				var hit := space.intersect_ray(query)
				if hit.is_empty():
					row += "  ---"
					continue
				var dy: float = hit.position.y - top
				row += " %+.2f" % dy if hit.collider != terrain else "  .  "
				if hit.collider != terrain:
					var key := "%s#%d" % [hit.collider.get_path(), hit.shape]
					if not seen.has(key):
						seen[key] = true
						var owner_id: int = hit.collider.shape_find_owner(hit.shape)
						var shape_node: Node = hit.collider.shape_owner_get_owner(owner_id)
						var shape: Shape3D = hit.collider.shape_owner_get_shape(owner_id, 0)
						var info := str(shape)
						if shape is CylinderShape3D:
							info = "cylindre r %.2f h %.2f" % [shape.radius, shape.height]
						elif shape is BoxShape3D:
							info = "boîte %s" % shape.size
						elif shape is ConvexPolygonShape3D:
							info = "enveloppe (%d points)" % shape.points.size()
						print("    %s : %s à %s (sol %.2f)" % [key.replace("/root/Desert/", ""), info,
							(shape_node as Node3D).global_position.snappedf(0.01) if shape_node is Node3D else "?", top])
			print("   " + row)
	finish()
