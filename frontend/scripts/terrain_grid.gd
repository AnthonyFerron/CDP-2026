class_name TerrainGrid
## Assemble le maillage d'un sol en grille, comme le font les terrains des lieux : chaque case est coupée en deux
## triangles, (0, 1, 2) et (1, 3, 2), chacun avec sa normale et sa couleur (faces plates). Les hauteurs aux sommets
## et la couleur de chaque face sont calculées par le terrain, ou lues dans son calcul d'avance (LevelBake) :
## le maillage est le même dans les deux cas.
##
## Les couleurs passent par des octets (RGBA8). Le moteur range de toute façon les couleurs de sommets ainsi, en
## tronquant chaque composante (c x 255) : colors_to_bytes tronque de la même façon, et b / 255 redonne l'octet b.
## Le maillage ne change donc pas d'un bit, et le calcul d'avance pèse quatre fois moins.


## Octets RGBA8 des couleurs, tronqués comme le moteur les range dans un maillage.
static func colors_to_bytes(colors: PackedColorArray) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(colors.size() * 4)
	for index in colors.size():
		var color := colors[index]
		bytes[index * 4] = int(clampf(color.r * 255.0, 0.0, 255.0))
		bytes[index * 4 + 1] = int(clampf(color.g * 255.0, 0.0, 255.0))
		bytes[index * 4 + 2] = int(clampf(color.b * 255.0, 0.0, 255.0))
		bytes[index * 4 + 3] = int(clampf(color.a * 255.0, 0.0, 255.0))
	return bytes


## Tableaux du maillage (sommets, normales, couleurs). heights : (columns + 1) x (rows + 1) sommets, ligne par
## ligne selon z ; colors : octets RGBA8 d'une couleur par case, ou de deux (un par triangle) si per_triangle.
## Le coin de la case (column, row) est en (origin_x + column x cell, origin_z + row x cell).
static func assemble(heights: PackedFloat32Array, colors: PackedByteArray, columns: int, rows: int, origin_x: float,
		origin_z: float, cell: float, per_triangle := false) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tints := PackedColorArray()
	var count := columns * rows * 6
	vertices.resize(count)
	normals.resize(count)
	tints.resize(count)
	var palette := PackedColorArray()
	palette.resize(colors.size() / 4)
	for index in palette.size():
		palette[index] = Color(colors[index * 4] / 255.0, colors[index * 4 + 1] / 255.0, colors[index * 4 + 2] / 255.0,
			colors[index * 4 + 3] / 255.0)
	var stride := columns + 1
	var index := 0
	for row in rows:
		var z := origin_z + row * cell
		var z1 := z + cell
		for column in columns:
			var x := origin_x + column * cell
			var x1 := x + cell
			var first := row * stride + column
			var p0 := Vector3(x, heights[first], z)
			var p1 := Vector3(x1, heights[first + 1], z)
			var p2 := Vector3(x, heights[first + stride], z1)
			var p3 := Vector3(x1, heights[first + stride + 1], z1)
			var n0 := (p2 - p0).cross(p1 - p0).normalized()
			var n1 := (p2 - p1).cross(p3 - p1).normalized()
			var face := row * columns + column
			var c0: Color
			var c1: Color
			if per_triangle:
				c0 = palette[face * 2]
				c1 = palette[face * 2 + 1]
			else:
				c0 = palette[face]
				c1 = c0
			vertices[index] = p0
			vertices[index + 1] = p1
			vertices[index + 2] = p2
			vertices[index + 3] = p1
			vertices[index + 4] = p3
			vertices[index + 5] = p2
			normals[index] = n0
			normals[index + 1] = n0
			normals[index + 2] = n0
			normals[index + 3] = n1
			normals[index + 4] = n1
			normals[index + 5] = n1
			tints[index] = c0
			tints[index + 1] = c0
			tints[index + 2] = c0
			tints[index + 3] = c1
			tints[index + 4] = c1
			tints[index + 5] = c1
			index += 6
	return [vertices, normals, tints]


## Vrai si les hauteurs calculées d'avance redonnent celles du terrain en quelques points de la grille (height_at
## de chaque terrain) : le relief n'a pas changé sans que ses réglages changent. Le bruit peut différer d'un
## processeur à l'autre de quelques millionièmes, pas d'un millimètre.
static func spot_check(heights: PackedFloat32Array, columns: int, rows: int, origin_x: float, origin_z: float,
		cell: float, height_at: Callable) -> bool:
	if heights.size() != (columns + 1) * (rows + 1):
		return false
	for spot: Vector2i in [Vector2i(0, 0), Vector2i(columns / 2, rows / 2), Vector2i(columns / 3, rows * 2 / 3),
			Vector2i(columns * 3 / 5, rows / 4), Vector2i(columns * 7 / 10, rows * 3 / 5), Vector2i(columns / 2, rows * 3 / 4),
			Vector2i(columns, rows)]:
		var height: float = height_at.call(origin_x + spot.x * cell, origin_z + spot.y * cell)
		if absf(heights[spot.y * (columns + 1) + spot.x] - height) > 0.001:
			return false
	return true
