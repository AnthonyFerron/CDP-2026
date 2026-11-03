@tool
class_name VillageTerrain
extends StaticBody3D
## Sol du Village : un replat pour le bourg, un ruisseau à l'ouest, la colline du moulin et des coteaux autour.

## Ruisseau : position x de son lit, demi-largeur et profondeur.
const STREAM_X := -38.0
const STREAM_HALF_WIDTH := 3.0
const STREAM_DEPTH := 1.4
## Colline du moulin à vent : centre (x, z), rayon et hauteur.
const MILL_HILL := Vector4(30.0, -30.0, 12.0, 4.0)
## Bourg : zone plate qui porte les maisons, en x et en z.
const TOWN_MIN := Vector2(-34.0, -36.0)
const TOWN_MAX := Vector2(34.0, 46.0)
## Rues pavées : la grande rue du portail à l'hôtel de ville, et la rue du pont.
const MAIN_STREET_HALF_WIDTH := 2.6
const WEST_STREET_Z := 6.0
const SQUARE := Vector3(0.0, -2.0, 11.0)
const SIZE := 170.0
const CELL_SIZE := 1.25
const PLAY_RADIUS := 64.0
const BORDER_WIDTH := 10.0
const BORDER_HEIGHT := 10.0

const COLOR_GRASS := Color(0.32, 0.36, 0.18)
const COLOR_DRY := Color(0.42, 0.38, 0.22)
const COLOR_DIRT := Color(0.36, 0.28, 0.2)
const COLOR_COBBLE := Color(0.4, 0.38, 0.36)
const COLOR_BANK := Color(0.3, 0.27, 0.2)
const COLOR_HILL := Color(0.3, 0.34, 0.2)

@export var ground_material: Material

var _relief := FastNoiseLite.new()


## Hauteurs aux sommets de la grille du maillage.
var _heights := PackedFloat32Array()
var _cells := 0


func _ready() -> void:
	_relief.seed = 5815
	_relief.frequency = 0.025
	_build()


func height_at(x: float, z: float) -> float:
	var height := (_relief.get_noise_2d(x, z) * 0.5 + 0.5) * 2.2
	height *= 1.0 - _town_mask(x, z)
	var hill := Vector2(x - MILL_HILL.x, z - MILL_HILL.y).length() / MILL_HILL.z
	height = maxf(height, MILL_HILL.w * (1.0 - smoothstep(0.35, 1.0, hill)))
	var bank := absf(x - STREAM_X)
	height -= STREAM_DEPTH * (1.0 - smoothstep(STREAM_HALF_WIDTH * 0.6, STREAM_HALF_WIDTH + 1.5, bank))
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


func stream_mask(x: float) -> float:
	return 1.0 - smoothstep(STREAM_HALF_WIDTH, STREAM_HALF_WIDTH + 1.5, absf(x - STREAM_X))


## Vaut 1 dans le bourg et sur les rues, où le sol reste plat.
func _town_mask(x: float, z: float) -> float:
	var outside := maxf(maxf(TOWN_MIN.x - x, x - TOWN_MAX.x), maxf(TOWN_MIN.y - z, z - TOWN_MAX.y))
	var town := 1.0 - smoothstep(0.0, 8.0, outside)
	var road := (1.0 - smoothstep(MAIN_STREET_HALF_WIDTH + 1.0, MAIN_STREET_HALF_WIDTH + 6.0, absf(x))) * smoothstep(70.0, 60.0, z)
	return maxf(town, road)


## Vaut 1 sur les pavés de la grande rue, de la rue du pont et de la place.
func cobble_mask(x: float, z: float) -> float:
	var wobble := _relief.get_noise_2d(x * 5.0, z * 5.0) * 0.4
	var main := (1.0 - smoothstep(MAIN_STREET_HALF_WIDTH - 0.3, MAIN_STREET_HALF_WIDTH + 0.3, absf(x) + wobble))
	main *= smoothstep(64.0, 58.0, z) * smoothstep(-22.0, -18.0, z)
	var west := (1.0 - smoothstep(1.8, 2.4, absf(z - WEST_STREET_Z) + wobble)) * smoothstep(-44.0, -40.0, x) * smoothstep(0.0, -4.0, x)
	var square := 1.0 - smoothstep(SQUARE.z - 0.5, SQUARE.z + 0.5, Vector2(x - SQUARE.x, z - SQUARE.y).length() + wobble)
	return maxf(maxf(main, west), square)


func _face_color(x: float, z: float, height: float) -> Color:
	var noise := _relief.get_noise_2d(z * 2.5, x * 2.5) * 0.5 + 0.5
	var color := COLOR_GRASS.lerp(COLOR_DRY, noise)
	color = color.lerp(COLOR_DIRT, _town_mask(x, z) * 0.6 * (1.0 - noise * 0.5))
	color = color.lerp(COLOR_COBBLE, cobble_mask(x, z))
	color = color.lerp(COLOR_BANK, stream_mask(x) * smoothstep(0.2, -0.6, height))
	var distance := Vector2(x, z).length()
	return color.lerp(COLOR_HILL, smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance))


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
			var center := (points[0].y + points[1].y + points[2].y + points[3].y) * 0.25
			var color := _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5, center)
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
