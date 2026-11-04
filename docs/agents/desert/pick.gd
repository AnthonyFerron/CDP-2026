extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"
## Ce que montre un pixel d'une capture : le maillage le plus proche le long du rayon de la caméra.

const PICKS := [
	[Vector3(-24, 1.65, -2.5), Vector3(-30, 0.3, -2.5), [Vector2(250, 290), Vector2(500, 270), Vector2(150, 330)]],
	[Vector3(-23.5, 1.5, 44), Vector3(-20.5, 0.3, 46.2), [Vector2(810, 500), Vector2(780, 560)]],
]


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	await wait(5)
	_collect_visuals(level)
	var camera := Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	print("PICK vue %s" % root.get_visible_rect().size)
	for pick: Array in PICKS:
		camera.global_position = pick[0]
		camera.look_at(pick[1], Vector3.UP)
		for shot_pixel: Vector2 in pick[2]:
			var pixel := shot_pixel * 1.5
			var from := camera.project_ray_origin(pixel)
			var to := from + camera.project_ray_normal(pixel) * 40.0
			var best := 1e9
			var label := "rien"
			for mesh in meshes:
				if not mesh.is_visible_in_tree():
					continue
				var inverse := mesh.global_transform.affine_inverse()
				var hit: Dictionary = tri(mesh.mesh).intersect_segment(inverse * from, inverse * to)
				if hit.is_empty():
					continue
				var d := from.distance_to(mesh.global_transform * Vector3(hit.position))
				if d < best:
					best = d
					var material := mesh.get_active_material(0)
					label = "%s (%s)" % [mesh.get_path(), material.albedo_color if material is BaseMaterial3D else material]
			for instance in multimeshes:
				if not instance.is_visible_in_tree():
					continue
				for index in instance.multimesh.instance_count:
					var xform := instance.global_transform * instance.multimesh.get_instance_transform(index)
					var inverse := xform.affine_inverse()
					var hit: Dictionary = tri(instance.multimesh.mesh).intersect_segment(inverse * from, inverse * to)
					if hit.is_empty():
						continue
					var d := from.distance_to(xform * Vector3(hit.position))
					if d < best:
						best = d
						label = "%s #%d" % [instance.get_path(), index]
			print("PICK %s %s : %.2f m %s" % [pick[0], pixel, best, label])
			# Boîtes englobantes traversées par le rayon, de la plus proche à la plus lointaine.
			var seen := {}
			for step in 60:
				var point := from + camera.project_ray_normal(pixel) * (0.5 + step * 0.25)
				for mesh in meshes:
					if seen.has(mesh) or not mesh.is_visible_in_tree():
						continue
					if (mesh.global_transform * mesh.get_aabb()).has_point(point):
						seen[mesh] = true
						print("    boîte à %.2f m : %s" % [0.5 + step * 0.25, mesh.get_path()])
				for instance in multimeshes:
					if not instance.is_visible_in_tree():
						continue
					for index in instance.multimesh.instance_count:
						var key := "%s#%d" % [instance.get_path(), index]
						if seen.has(key):
							continue
						var xform := instance.global_transform * instance.multimesh.get_instance_transform(index)
						if (xform * instance.multimesh.mesh.get_aabb()).has_point(point):
							seen[key] = true
							print("    boîte à %.2f m : %s" % [0.5 + step * 0.25, key])
	finish()
