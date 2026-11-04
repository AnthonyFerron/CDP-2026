extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_audit_test.gd"
## Appels de dessin dans la cave et devant la stèle du couchant, avant et après le regroupement des stèles.


func _measure(label: String) -> void:
	await wait(20)
	print("FUSION %s : appels %d, objets %d" % [label, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	await wait(5)
	var camera := Camera3D.new()
	level.add_child(camera)
	camera.current = true
	for merged in [false, true]:
		if merged:
			for stele: Node3D in [level.get_node("Exterior/Clues/Levant"), level.get_node("Exterior/Clues/Zenith"), level.get_node("Exterior/Clues/Couchant")]:
				level.call("_merge_static", stele)
		var tag := "fusion" if merged else "sans"
		level.set("_inside", false)
		level.call("_apply_location")
		camera.global_position = Vector3(-6, 1.8, 14)
		camera.look_at(Vector3(-7, 1.6, 8))
		await _measure(tag + " dehors")
		level.set("_inside", true)
		level.call("_apply_location")
		camera.global_position = Vector3(0, -38.35, -1)
		camera.look_at(Vector3(0, -39, -6))
		await _measure(tag + " cave")
		var count := 0
		for node: Node in level.get_node("Exterior/Clues").find_children("*", "GeometryInstance3D", true, false):
			count += 1
		print("FUSION %s : %d géométries sous Exterior/Clues" % [tag, count])
	finish()
