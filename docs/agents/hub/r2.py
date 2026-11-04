REPLACEMENTS = [
('''func _is_free(spot: Vector2, margin: float) -> bool:
	if terrain.flat_mask(spot.x, spot.y) > 0.2 or spot.length() > HubTerrain.LIMIT_RADIUS - 2.0:
		return false
	if HubTerrain.castle_distance(spot) < 6.0 + margin or spot.distance_to(HubTerrain.BUNKER) < 14.0:
		return false''',
'''func _is_free(spot: Vector2, margin: float) -> bool:
	if not HubTerrain.inside_limit(spot, 2.0) or terrain.flat_mask(spot.x, spot.y) > 0.2:
		return false
	if HubTerrain.castle_distance(spot) < 6.0 + margin or spot.distance_to(HubTerrain.BUNKER) < 14.0:
		return false
	# Ni dans la rivière ni sur ses berges, ni dans le jardin du roi, dont les arbres sont plantés en allées.
	if terrain.shore_distance(spot.x, spot.y) < 3.5 + margin or HubTerrain.PARK_AREA.grow(3.0 + margin).has_point(spot):
		return false
	for bridge: Array in HubTerrain.BRIDGES:
		if HubTerrain.bridge_contains(bridge, spot, 3.0 + margin):
			return false
	if HubTerrain.alley_distance(spot, false, 4.0) < 3.0 + margin:
		return false'''),
('''		var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * HubTerrain.LIMIT_RADIUS
		if not _is_free(spot, 1.0):''',
'''		var angle := _rng.randf() * TAU
		var spot := Vector2.from_angle(angle) * sqrt(_rng.randf()) * HubTerrain.limit_radius(angle)
		if not _is_free(spot, 1.0):'''),
('''		var spot := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(HubTerrain.LIMIT_RADIUS + 1.0, HubTerrain.PLAY_RADIUS + 24.0)
		if terrain.slope_at(spot.x, spot.y) > 1.0:
			continue''',
'''		var angle := _rng.randf() * TAU
		var spot := Vector2.from_angle(angle) * _rng.randf_range(HubTerrain.limit_radius(angle) + 1.0, HubTerrain.play_radius(angle) + 24.0)
		if terrain.slope_at(spot.x, spot.y) > 1.0 or terrain.shore_distance(spot.x, spot.y) < 2.5:
			continue'''),
]
