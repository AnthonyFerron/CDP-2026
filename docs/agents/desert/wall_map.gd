extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"
## Carte, à 1,1 m de haut, des points proches (0,3 m) d'un triangle visible autour des deux angles de la muraille.


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	for center_x: float in [12.6]:
		print("CARTE mur x %.1f (lignes : z de -1 à 6 ; colonnes : x de %.1f à %.1f)" % [center_x, center_x - 4.0, center_x + 4.0])
		for j in 15:
			var z := -1.0 + j * 0.5
			var line := ""
			for i in 17:
				var x := center_x - 4.0 + i * 0.5
				line += "#" if _visible_near(Vector3(x, 1.3, z), 0.3) else "."
			print("CARTE z %5.1f %s" % [z, line])
	for p: Vector3 in [Vector3(12.0, 1.3, 3.1), Vector3(11.95, 1.3, 3.1), Vector3(11.9, 1.3, 3.1), Vector3(12.0, 1.3, 2.6), Vector3(11.9, 1.25, 2.6)]:
		print("CARTE point %s visible 0,5 : %s" % [p, _visible_near(p, 0.5)])
	finish()
