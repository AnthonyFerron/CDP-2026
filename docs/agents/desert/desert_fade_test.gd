extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Rien ne s'efface sous les pieds : Godot mesure la distance de visibilité jusqu'au centre de la boîte d'un objet.
## Pour 40 points de la carte (jusqu'au bord), tout objet à distance de visibilité dont un morceau est à moins de
## 25 m du joueur doit avoir le centre de sa boîte dans sa distance de visibilité. Vérifie aussi qu'aucun bélier de
## siège (l'engin à toit) ne reste dans la scène.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	var faded: Array[GeometryInstance3D] = []
	for node in level.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		if geometry.visibility_range_end > 0.0 and geometry.global_position.y > -20.0:
			faded.append(geometry)
	print("objets à distance de visibilité : %d" % faded.size())
	var spots: Array[Vector3] = []
	for ring: float in [0.0, 20.0, 40.0, 58.0]:
		for index in 10:
			var angle := TAU * index / 10.0 + ring * 0.01
			spots.append(Vector3(cos(angle) * ring, 1.7, sin(angle) * ring))
	var failures_here := 0
	for spot in spots:
		for geometry in faded:
			var box := geometry.global_transform * geometry.get_aabb()
			var nearest := spot.clamp(box.position, box.end)
			if nearest.distance_to(spot) > 25.0:
				continue
			var to_center := box.get_center().distance_to(spot)
			if to_center > geometry.visibility_range_end:
				failures_here += 1
				if failures_here <= 12:
					print("    disparaît sous les yeux en %s : %s (centre à %.0f m, distance %.0f m)" % [
						Vector2(spot.x, spot.z).snappedf(1), str(geometry.get_path()).replace("/root/Desert/", ""), to_center, geometry.visibility_range_end])
	check("aucun détail ne disparaît près du joueur (%d cas)" % failures_here, failures_here == 0)
	var rams := 0
	for node in level.find_children("*", "Node3D", true, false):
		if node.scene_file_path.contains("siege-ram"):
			rams += 1
	check("aucun bélier de siège couvert dans le désert (%d)" % rams, rams == 0)
	finish()
