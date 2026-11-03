class_name GridHeight
## Hauteur d'un sol maillé en grille de triangles, comme le construisent les terrains des niveaux :
## chaque case de la grille est coupée en deux triangles, (0, 1, 2) et (1, 3, 2).
## Le décor posé avec cette hauteur touche le sol affiché, au lieu de flotter au-dessus des pentes.


## Hauteur du maillage au point (x, z). heights contient (cells + 1)² sommets, ligne par ligne selon z.
static func sample(heights: PackedFloat32Array, cells: int, size: float, cell_size: float, x: float, z: float) -> float:
	var gx := clampf((x + size * 0.5) / cell_size, 0.0, cells - 0.001)
	var gz := clampf((z + size * 0.5) / cell_size, 0.0, cells - 0.001)
	var column := int(gx)
	var row := int(gz)
	var u := gx - column
	var v := gz - row
	var first := row * (cells + 1) + column
	var h0 := heights[first]
	var h1 := heights[first + 1]
	var h2 := heights[first + cells + 1]
	var h3 := heights[first + cells + 2]
	if u + v <= 1.0:
		return h0 + u * (h1 - h0) + v * (h2 - h0)
	return h3 + (1.0 - u) * (h2 - h3) + (1.0 - v) * (h1 - h3)


## Pente du maillage autour du point : 0 à plat, 1 pour 45 degrés.
static func slope(heights: PackedFloat32Array, cells: int, size: float, cell_size: float, x: float, z: float) -> float:
	var dx := sample(heights, cells, size, cell_size, x + 0.5, z) - sample(heights, cells, size, cell_size, x - 0.5, z)
	var dz := sample(heights, cells, size, cell_size, x, z + 0.5) - sample(heights, cells, size, cell_size, x, z - 0.5)
	return Vector2(dx, dz).length()
