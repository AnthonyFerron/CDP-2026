@tool
class_name MaraisTerrain
extends StaticBody3D
## Sol du Marais : un fond de vase sous l'eau, des îlots plats et des berges qui ferment la zone.

## Position (x, z), rayon et hauteur de chaque îlot. Les quatre premiers portent le parcours.
const ISLANDS: Array[Vector4] = [
	Vector4(0.0, 56.0, 13.0, 0.4),
	Vector4(-20.0, 22.0, 9.0, 0.4),
	Vector4(16.0, 0.0, 17.0, 0.4),
	Vector4(0.0, -36.0, 13.0, 0.4),
	Vector4(-36.0, -4.0, 6.0, 0.3),
	Vector4(34.0, -30.0, 6.0, 0.3),
	Vector4(-30.0, -44.0, 5.0, 0.3),
	Vector4(36.0, 32.0, 5.0, 0.3),
	Vector4(-40.0, 40.0, 6.0, 0.3),
]
## Pontons entre les îlots du parcours : début (x, z) et fin (x, z).
const BOARDWALKS: Array[Vector4] = [
	Vector4(-3.0, 48.0, -18.0, 27.0),
	Vector4(-16.0, 19.0, 6.0, 4.0),
	Vector4(8.5, -10.0, 3.0, -28.0),
]
const WATER_LEVEL := 0.0
const DECK_HEIGHT := 0.35
## Fond de vase des eaux profondes, où le joueur s'enlise.
const BED_HEIGHT := -1.6
## Part du rayon d'un îlot qui reste parfaitement plate.
const FLAT_RATIO := 0.65
const SIZE := 180.0
const CELL_SIZE := 1.5
const PLAY_RADIUS := 66.0
const BANK_WIDTH := 10.0
const BANK_HEIGHT := 7.0

const COLOR_MUD := Color(0.13, 0.11, 0.08)
const COLOR_SILT := Color(0.2, 0.19, 0.13)
const COLOR_MOSS := Color(0.16, 0.24, 0.12)
const COLOR_GRASS := Color(0.22, 0.3, 0.15)
const COLOR_BANK := Color(0.14, 0.17, 0.11)

@export var ground_material: Material

var _relief := FastNoiseLite.new()


## Hauteurs aux sommets de la grille du maillage.
var _heights := PackedFloat32Array()
var _cells := 0


func _ready() -> void:
	_relief.seed = 4040
	_relief.frequency = 0.05
	_build()


func height_at(x: float, z: float) -> float:
	var height := BED_HEIGHT + _relief.get_noise_2d(x, z) * 0.25
	for island in ISLANDS:
		var ratio := Vector2(x - island.x, z - island.y).length() / island.z
		var rise := 1.0 - smoothstep(FLAT_RATIO, 1.25, ratio)
		var top := island.w + (_relief.get_noise_2d(z, x) * 0.35 if ratio > FLAT_RATIO else 0.0)
		height = maxf(height, lerpf(BED_HEIGHT, top, rise))
	var distance := Vector2(x, z).length()
	return height + BANK_HEIGHT * smoothstep(PLAY_RADIUS, PLAY_RADIUS + BANK_WIDTH, distance)


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


## Renvoie la couleur d'une face selon sa hauteur : vase, limon, mousse, herbe ou berge.
func _face_color(x: float, z: float, height: float) -> Color:
	var variation := _relief.get_noise_2d(x * 2.0, z * 2.0) * 0.5 + 0.5
	var color := COLOR_MUD.lerp(COLOR_SILT, smoothstep(-1.0, -0.1, height))
	color = color.lerp(COLOR_MOSS, smoothstep(-0.05, 0.25, height))
	color = color.lerp(COLOR_GRASS, smoothstep(0.3, 0.45, height) * variation)
	var distance := Vector2(x, z).length()
	return color.lerp(COLOR_BANK, smoothstep(PLAY_RADIUS, PLAY_RADIUS + BANK_WIDTH, distance))


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
			var center_height := (points[0].y + points[1].y + points[2].y + points[3].y) * 0.25
			var color := _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5, center_height)
			for triangle: Array in [[0, 1, 2], [1, 3, 2]]:
				var a := points[triangle[0]]
				var b := points[triangle[1]]
				var c := points[triangle[2]]
				var normal := (c - a).cross(b - a).normalized()
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
