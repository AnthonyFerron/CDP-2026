@tool
class_name DesertTerrain
extends StaticBody3D
## Sol du Désert : des dunes ondulées, une esplanade plate autour du sanctuaire et des crêtes qui ferment la zone.

## Sables mouvants : position (x, z) et rayon.
const QUICKSANDS: Array[Vector3] = [
	Vector3(-20.0, 26.0, 4.5),
	Vector3(22.0, 8.0, 5.0),
	Vector3(-26.0, -14.0, 4.0),
	Vector3(18.0, -30.0, 4.5),
]
## Esplanade du sanctuaire : centre (x, z) et rayon.
const PLAZA := Vector3(0.0, -6.0, 20.0)
## Chemin du portail jusqu'à l'arche d'entrée.
const PATH_HALF_WIDTH := 4.0
const PATH_START := 14.0
const PATH_END := 54.0
const SIZE := 170.0
const CELL_SIZE := 1.25
const PLAY_RADIUS := 64.0
const BORDER_WIDTH := 10.0
const BORDER_HEIGHT := 14.0
## Limite invisible que le joueur ne peut franchir, au pied des crêtes : ni en marchant, ni en sautant.
const LIMIT_RADIUS := 66.5
## Replats du décor, comme dans tools/build_desert.py : centre (x, z) et rayon. Le sol y reste plat, à la hauteur 0,
## et le décor éparpillé s'en écarte.
const SITES: Array[Vector3] = [
	Vector3(-36.0, -30.0, 9.0),  # campement de la caravane
	Vector3(0.0, -31.0, 9.0),  # sanctuaire englouti
	Vector3(40.0, -2.0, 10.0),  # oasis asséchée
	Vector3(-34.0, 30.0, 7.0),  # tête de la statue
	Vector3(-30.0, -2.5, 7.0),  # citerne
	Vector3(38.0, 30.0, 6.0),  # poste de garde
	Vector3(-22.0, -48.0, 6.0),  # colonnade engloutie
	Vector3(24.0, -44.0, 6.0),  # porte des vents
	Vector3(-24.0, 48.0, 6.0),  # tombes des caravaniers
	Vector3(26.0, 50.0, 6.0),  # bête des sables
]
## Bassin asséché de l'oasis : centre (x, z), demi-axes (x, z), et sa profondeur.
const POND := Vector4(41.0, -3.0, 5.0, 3.8)
const POND_DEPTH := 0.7
## Fosse de la citerne, calée sur la grille du maillage : ses bords tombent d'une case, sous les murs épais.
const CISTERN := Rect2(-33.75, -5.0, 7.5, 5.0)
const CISTERN_DEPTH := 1.6

const COLOR_SAND := Color(0.82, 0.62, 0.36)
const COLOR_SHADE := Color(0.7, 0.5, 0.28)
const COLOR_PATH := Color(0.72, 0.55, 0.36)
const COLOR_RIDGE := Color(0.78, 0.55, 0.32)
const COLOR_MUD := Color(0.5, 0.36, 0.24)

@export var ground_material: Material

var _dunes := FastNoiseLite.new()


## Hauteurs aux sommets de la grille du maillage.
var _heights := PackedFloat32Array()
var _cells := 0


func _ready() -> void:
	_dunes.seed = 5814
	_dunes.frequency = 0.02
	_dunes.fractal_octaves = 3
	_build()


func height_at(x: float, z: float) -> float:
	# Dunes allongées par le vent, plus du bruit pour casser la régularité.
	var wave := sin(x * 0.11 + z * 0.05 + _dunes.get_noise_2d(x, z) * 2.5) * 0.5 + 0.5
	var height := wave * wave * 2.6 + _dunes.get_noise_2d(z * 1.7, x * 1.7) * 0.6
	height *= 1.0 - _flat_mask(x, z)
	height -= POND_DEPTH * (1.0 - smoothstep(0.55, 1.0, _pond_ratio(x, z)))
	if _in_cistern(x, z):
		height -= CISTERN_DEPTH
	for sand in QUICKSANDS:
		var ratio := Vector2(x - sand.x, z - sand.y).length() / sand.z
		height -= 0.5 * (1.0 - smoothstep(0.6, 1.2, ratio))
	var distance := Vector2(x, z).length()
	return height + BORDER_HEIGHT * smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance)


## Hauteur du sol tel qu'il est maillé, à l'interpolation de ses triangles : c'est sur elle que le décor se pose.
func surface_height(x: float, z: float) -> float:
	if _heights.is_empty():
		return height_at(x, z)
	return GridHeight.sample(_heights, _cells, SIZE, CELL_SIZE, x, z)


## Hauteur où poser le pied d'un objet : le sol maillé, un peu plus bas sur une pente pour ne jamais flotter.
func footing_height(x: float, z: float) -> float:
	if _heights.is_empty():
		return height_at(x, z)
	return surface_height(x, z) - 0.6 * GridHeight.slope(_heights, _cells, SIZE, CELL_SIZE, x, z)


## Vaut 1 sur l'esplanade, le chemin bordé d'obélisques et les replats du décor, où le sol reste plat.
func _flat_mask(x: float, z: float) -> float:
	var plaza := 1.0 - smoothstep(PLAZA.z, PLAZA.z + 8.0, Vector2(x - PLAZA.x, z - PLAZA.y).length())
	for site in SITES:
		plaza = maxf(plaza, 1.0 - smoothstep(site.z, site.z + 6.0, Vector2(x - site.x, z - site.y).length()))
	var path := 1.0 - smoothstep(PATH_HALF_WIDTH + 3.5, PATH_HALF_WIDTH + 8.0, absf(x))
	path *= smoothstep(PATH_START - 6.0, PATH_START, z) * smoothstep(PATH_END + 6.0, PATH_END, z)
	return maxf(plaza, path)


## Distance relative au centre du bassin de l'oasis : 1 sur son bord.
func _pond_ratio(x: float, z: float) -> float:
	return Vector2((x - POND.x) / POND.z, (z - POND.y) / POND.w).length()


func _in_cistern(x: float, z: float) -> bool:
	return x > CISTERN.position.x - 0.01 and x < CISTERN.end.x + 0.01 and z > CISTERN.position.y - 0.01 and z < CISTERN.end.y + 0.01


func _face_color(x: float, z: float, normal: Vector3) -> Color:
	var color := COLOR_SHADE.lerp(COLOR_SAND, clampf(normal.dot(Vector3(0.4, 0.9, 0.2).normalized()), 0.0, 1.0))
	var path := 1.0 - smoothstep(2.2, 3.4, absf(x + sin(z * 0.2) * 0.6))
	path *= smoothstep(PATH_START, PATH_START + 2.0, z) * smoothstep(PATH_END, PATH_END - 3.0, z)
	color = color.lerp(COLOR_PATH, path * 0.8)
	# Boue craquelée au fond du bassin de l'oasis et de la citerne.
	color = color.lerp(COLOR_MUD, (1.0 - smoothstep(0.7, 1.05, _pond_ratio(x, z))) * 0.85)
	if _in_cistern(x, z):
		color = COLOR_MUD
	var distance := Vector2(x, z).length()
	return color.lerp(COLOR_RIDGE, smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance))


func _build() -> void:
	var cells := int(SIZE / CELL_SIZE)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for array: Variant in [vertices, normals, colors]:
		array.resize(cells * cells * 6)

	var heights := PackedFloat32Array()
	heights.resize((cells + 1) * (cells + 1))
	_cells = cells
	for row in cells + 1:
		for column in cells + 1:
			heights[row * (cells + 1) + column] = height_at(
				column * CELL_SIZE - SIZE * 0.5, row * CELL_SIZE - SIZE * 0.5
			)

	var index := 0
	for row in cells:
		for column in cells:
			var x := column * CELL_SIZE - SIZE * 0.5
			var z := row * CELL_SIZE - SIZE * 0.5
			var first := row * (cells + 1) + column
			var points: Array[Vector3] = [
				Vector3(x, heights[first], z),
				Vector3(x + CELL_SIZE, heights[first + 1], z),
				Vector3(x, heights[first + cells + 1], z + CELL_SIZE),
				Vector3(x + CELL_SIZE, heights[first + cells + 2], z + CELL_SIZE),
			]
			for triangle: Array in [[0, 1, 2], [1, 3, 2]]:
				var a := points[triangle[0]]
				var b := points[triangle[1]]
				var c := points[triangle[2]]
				var normal := (c - a).cross(b - a).normalized()
				var color := _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5, normal)
				for vertex in [a, b, c]:
					vertices[index] = vertex
					normals[index] = normal
					colors[index] = color
					index += 1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, ground_material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	_heights = heights
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	_build_limit()


## Mur invisible en anneau, haut de 40 m, au pied des crêtes : on ne sort pas de la zone, même en sautant d'un rocher.
func _build_limit() -> void:
	var segments := 72
	var length := TAU * LIMIT_RADIUS / segments + 0.5
	for index in segments:
		var angle := TAU * index / segments
		var shape := BoxShape3D.new()
		shape.size = Vector3(length, 40.0, 1.0)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = Vector3(cos(angle) * LIMIT_RADIUS, 15.0, sin(angle) * LIMIT_RADIUS)
		collision.rotation.y = -angle + PI * 0.5
		add_child(collision)
