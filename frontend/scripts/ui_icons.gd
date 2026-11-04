class_name UiIcons
## Icônes dessinées en code : flèches et coche. Les polices du jeu, Cinzel et Lora, n'ont pas ces symboles,
## et la version web n'a pas de police système pour les remplacer.

## Triangle plein pointé vers la direction donnée : Vector2.LEFT, RIGHT, UP ou DOWN.
static func arrow(direction: Vector2, size := 28, color := Color.WHITE) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size * 0.5
	for y in size:
		for x in size:
			# Coordonnées tournées pour que la flèche pointe toujours vers +u.
			var p := Vector2(x + 0.5 - half, y + 0.5 - half) / half
			var u := p.dot(direction)
			var v := absf(p.dot(direction.orthogonal()))
			# Pointe en u = 0,8, base en u = -0,7 : la demi-largeur diminue vers la pointe.
			var inside := u > -0.7 and u < 0.8 and v < (0.8 - u) * 0.62
			image.set_pixel(x, y, color if inside else Color(color, 0.0))
	return ImageTexture.create_from_image(image)


## Coche épaisse, comme celle d'une case validée.
static func check(size := 28, color := Color.WHITE) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var a := Vector2(0.14, 0.52) * size
	var b := Vector2(0.4, 0.78) * size
	var c := Vector2(0.88, 0.2) * size
	var thickness := size * 0.09
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var distance := minf(_segment_distance(p, a, b), _segment_distance(p, b, c))
			image.set_pixel(x, y, Color(color, clampf(thickness + 0.5 - distance, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	return p.distance_to(a + (b - a) * t)
