REPLACEMENTS = [
('''	var groups: Array[Array] = []
	for model in models:
		groups.append([])
	var placed := 0
	for attempt in count * 12:''', '''	var groups: Array[Array] = []
	# Hauteur de chaque modèle : la collision d'un rocher s'arrête à son sommet (celle d'un arbre, à 3 m).
	var heights: Array[float] = []
	for model in models:
		groups.append([])
		heights.append(_load_mesh(model).get_aabb().size.y if body else 0.0)
	var placed := 0
	for attempt in count * 12:'''),
('''			shape.radius = float(radii[model % radii.size()]) * scale_factor
			shape.height = 3.0
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = Vector3(spot.x, ground + 1.5, spot.y)''',
'''			shape.radius = float(radii[model % radii.size()]) * scale_factor
			shape.height = clampf(heights[model] * scale_factor, 0.6, 3.0)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = Vector3(spot.x, ground + shape.height * 0.5, spot.y)'''),
]
