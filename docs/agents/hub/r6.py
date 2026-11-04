REPLACEMENTS = [
('@export var reed_count := 1100', '@export var reed_count := 420'),
('''		for stem in _rng.randi_range(3, 6):
			var spot := centre + Vector2(_rng.randf_range(-0.7, 0.7), _rng.randf_range(-0.7, 0.7))
			var ground := maxf(terrain.surface_height(spot.x, spot.y), HubTerrain.WATER_LEVEL - 0.3)
			var group := _rng.randi() % reeds.size()
			var scale_factor := _rng.randf_range(1.4, 2.6)
			reeds[group].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, _rng.randf_range(0.9, 1.5), 1.0) * scale_factor),''',
'''		for stem in _rng.randi_range(2, 4):
			var spot := centre + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))
			var ground := maxf(terrain.surface_height(spot.x, spot.y), HubTerrain.WATER_LEVEL - 0.3)
			# Une touffe d'herbe pour deux tiges : les tiges, plus hautes, restent clairsemées.
			var group := _rng.randi() % reeds.size() if _rng.randf() < 0.45 else reeds.size() - 1
			var scale_factor := _rng.randf_range(0.8, 1.3) if group < reeds.size() - 1 else _rng.randf_range(1.6, 2.6)
			reeds[group].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, _rng.randf_range(0.8, 1.2), 1.0) * scale_factor),'''),
]
