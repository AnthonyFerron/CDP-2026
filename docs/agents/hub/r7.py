REPLACEMENTS = [
('''	await place(0, 0, Vector3(120, 1, 0))
	player.global_position = Vector3(100, 2, 0)
	await walk_to(Vector3(125, 0, 0), "limite infranchissable (doit echouer)", 300)
	check("le joueur reste dans le hub (%.1f)" % Vector2(player.global_position.x, player.global_position.z).length(),
		Vector2(player.global_position.x, player.global_position.z).length() < 107.0)''',
'''	# La vallée n'est plus un cercle : la limite se lit dans le terrain, à l'est (126 m) et à l'ouest (106 m).
	for angle: float in [0.0, PI]:
		var limit: float = HubTerrain.limit_radius(angle)
		var direction := Vector2.from_angle(angle)
		var start := direction * (limit - 8.0)
		await place(start.x, start.y, Vector3(direction.x * 200.0, 1, direction.y * 200.0))
		await walk_to(Vector3(direction.x * (limit + 20.0), 0, direction.y * (limit + 20.0)), "limite infranchissable (doit echouer)", 300)
		check("le joueur reste dans le hub (%.1f / %.0f)" % [Vector2(player.global_position.x, player.global_position.z).length(), limit],
			Vector2(player.global_position.x, player.global_position.z).length() < limit + 1.0)'''),
]
