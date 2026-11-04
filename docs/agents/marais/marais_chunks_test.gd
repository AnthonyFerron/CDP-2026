extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Petits détails du Marais découpés en cases : en tout point de la carte, chaque case qui a une plante à moins de
## 15 m du joueur est entièrement affichée (son centre à moins de la distance d'affichage, fondu compris) ;
## puis une marche réelle loin du centre, en comptant les cases proches qui s'éteignent.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/marais/marais.tscn")
	var scatter: Node = level.get_node("Scatter")
	var chunks: Array[MultiMeshInstance3D] = []
	var single := 0
	for node in scatter.get_children():
		var instance := node as MultiMeshInstance3D
		if not instance:
			continue
		if instance.visibility_range_end > 0.0:
			if String(instance.name).begins_with("Detail_"):
				chunks.append(instance)
			else:
				single += 1
	check("%d cases de détails, aucune dispersion à distance limitée d'un seul tenant (%d)" % [chunks.size(), single], chunks.size() > 10 and single == 0)
	var worst := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 400:
		var spot := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 66.0
		var eye := Vector3(spot.x, 1.7, spot.y)
		for chunk in chunks:
			var multimesh := chunk.multimesh
			var near := false
			for index in multimesh.instance_count:
				var origin := chunk.global_transform * multimesh.get_instance_transform(index).origin
				if Vector2(origin.x - eye.x, origin.z - eye.z).length() < 15.0:
					near = true
					break
			if near:
				var center := chunk.global_transform * chunk.get_aabb().get_center()
				worst = maxf(worst, maxf(eye.distance_to(center), eye.distance_to(chunk.global_position)))
	var limit: float = scatter.detail_range - 6.0
	check("plantes proches toujours affichées : case la plus lointaine à %.1f m (limite %.1f)" % [worst, limit], worst < limit)
	# Marche réelle loin du centre, le long de la berge sud-est puis vers l'arrivée.
	await walk_path([Vector3(-3, 0, 48), Vector3(-18, 0, 27), Vector3(-16, 0, 19), Vector3(6, 0, 4)], "marche")
	finish()
