extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"
## Cartes, dans le repère d'un modèle (u vers la droite, v vers l'avant), des points à moins de 0,12 m d'un
## triangle visible, à plusieurs hauteurs : de quoi tailler ses collisions au plus près.

const STEP_MAP := 0.2
const MAPS := [
	["bannière", Vector3(5.0, 0.0, -17.5), 0.0, Vector2(1.3, 0.6), [0.4, 1.0, 1.8, 2.6, 3.2]],
	["étal rouge", Vector3(-38.41, 0.0, -23.54), 130.0, Vector2(1.6, 1.6), [0.4, 1.0, 1.6, 2.4, 3.0]],
	["étal vert", Vector3(-29.11, 0.0, -30.82), -49.85, Vector2(1.6, 1.6), [0.4, 1.0, 1.6, 2.4, 3.0]],
	["charrette", Vector3(-41.27, 0.0, -34.72), 140.0, Vector2(1.4, 2.2), [0.3, 0.8, 1.3, 1.8, 2.3]],
]


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	for spec: Array in MAPS:
		var center: Vector3 = spec[1]
		var basis := Basis(Vector3.UP, deg_to_rad(spec[2]))
		var half: Vector2 = spec[3]
		var columns := int(round(half.x * 2.0 / STEP_MAP)) + 1
		var rows := int(round(half.y * 2.0 / STEP_MAP)) + 1
		for height: float in spec[4]:
			print("CARTE %s à %.1f m (u de %.1f à %.1f, v de %.1f en haut à %.1f en bas)" % [spec[0], height, -half.x, half.x, half.y, -half.y])
			for j in rows:
				var v := half.y - j * STEP_MAP
				var line := ""
				for i in columns:
					var u := -half.x + i * STEP_MAP
					var point := center + basis * Vector3(u, 0.0, v) + Vector3.UP * height
					line += "#" if _visible_near(point, 0.12) else "."
				print("CARTE %5.1f %s" % [v, line])
	finish()
