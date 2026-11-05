extends "res://tests/scenes/common_test.gd"
## La lave brûle toujours : le joueur posé au-dessus de chaque lac de cratère et de la coulée tombe dans la zone qui
## brûle, est ramené à son dernier endroit sûr avec le message de la lave ; posé sur le sol sec, rien ne se passe.
## Usage : --script <ce fichier> -- --api=http://127.0.0.1:9/api/v1


func _initialize() -> void:
	_run.call_deferred()


func _drop(at: Vector3, label: String, burns: bool) -> void:
	var hud_message: Label = hud().get_node("%Message")
	hud_message.text = ""
	await wait(10)
	var safe: Vector3 = level._safe_position
	player.global_position = at
	player.velocity = Vector3.ZERO
	var burned := false
	for i in 240:
		await physics_frame
		if hud_message.text.contains("lave"):
			burned = true
		if burned and not level._busy:
			break
	await wait(5)
	if burns:
		check("%s : brûle (message « %s »)" % [label, hud_message.text], burned)
		check("%s : ramené à l'endroit sûr (%s, attendu %s)" % [label, player.global_position.snappedf(0.1),
			safe.snappedf(0.1)], player.global_position.distance_to(safe) < 0.6)
	else:
		check("%s : ne brûle pas" % label, not burned)


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var scatter: PlaineScatter = level.get_node("Exterior/Scatter")
	var terrain: PlaineTerrain = level.get_node("Exterior/Terrain")
	var hazard: Area3D = scatter.get_node("LavaHazard")
	check("zone qui brûle : %d bandes, dans le monde" % hazard.get_child_count(),
		hazard.get_child_count() > 2000 and hazard.is_inside_tree() and hazard.monitoring)
	var start := player.global_position
	await _drop(start + Vector3.UP * 0.3, "arrivée", false)
	for index in scatter.lava_pools.size():
		var pool: Dictionary = scatter.lava_pools[index]
		var center: Vector3 = pool.center
		await _drop(center + Vector3.UP * 0.6, "lac du cratère %d" % index, true)
	# Coulée, entre deux de ses points, loin du pont.
	var flow := (PlaineTerrain.LAVA_FLOW[5] + PlaineTerrain.LAVA_FLOW[6]) * 0.5
	await _drop(Vector3(flow.x, terrain.flow_lava_height(flow.x, flow.y) + 0.6, flow.y), "coulée", true)
	finish()
