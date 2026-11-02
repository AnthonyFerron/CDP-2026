@tool
class_name PlaineTerrain
extends StaticBody3D
## Sol de la Plaine : relief brûlé, cratères et remparts naturels qui ferment la zone.

## Position (x, z), rayon et profondeur de chaque cratère.
const CRATERS: Array[Vector4] = [
	Vector4(-28.0, 18.0, 10.0, 3.0),
	Vector4(26.0, 26.0, 8.0, 2.4),
	Vector4(38.0, -6.0, 11.0, 3.2),
	Vector4(-44.0, -14.0, 9.0, 2.6),
	Vector4(-20.0, -38.0, 12.0, 3.4),
	Vector4(22.0, -42.0, 9.0, 2.6),
	Vector4(-50.0, 28.0, 7.0, 2.0),
]
const SIZE := 170.0
const CELL_SIZE := 1.25
## Rayon de la zone jouable, au-delà duquel le sol remonte.
const PLAY_RADIUS := 68.0
const BORDER_WIDTH := 9.0
const BORDER_HEIGHT := 16.0
const RUINS_RADIUS := 24.0
const PATH_HALF_WIDTH := 5.0

const COLOR_ASH := Color(0.2, 0.18, 0.2)
const COLOR_SOOT := Color(0.11, 0.095, 0.11)
const COLOR_CRATER := Color(0.25, 0.1, 0.075)
const COLOR_BORDER := Color(0.26, 0.23, 0.28)

@export var ground_material: Material

var _relief := FastNoiseLite.new()
var _cracks := FastNoiseLite.new()


func _ready() -> void:
	_relief.seed = 2026
	_relief.frequency = 0.035
	_cracks.seed = 7
	_cracks.frequency = 0.06
	_cracks.fractal_octaves = 2
	_build()


func height_at(x: float, z: float) -> float:
	var height := _relief.get_noise_2d(x, z) * 0.8
	for crater in CRATERS:
		height += _crater_profile(x, z, crater)
	height *= 1.0 - _flat_mask(x, z)
	var distance := Vector2(x, z).length()
	return height + BORDER_HEIGHT * smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance)


func _crater_profile(x: float, z: float, crater: Vector4) -> float:
	var ratio := Vector2(x - crater.x, z - crater.y).length() / crater.z
	var bowl := -crater.w * (1.0 - ratio * ratio) if ratio < 1.0 else 0.0
	var rim := crater.w * 0.35 * exp(-pow((ratio - 1.0) / 0.25, 2.0))
	return bowl + rim


## Vaut 1 sous les ruines et sur le chemin du portail, où le sol doit rester plat.
func _flat_mask(x: float, z: float) -> float:
	var ruins := 1.0 - smoothstep(RUINS_RADIUS, RUINS_RADIUS + 8.0, Vector2(x, z).length())
	var path := 1.0 - smoothstep(PATH_HALF_WIDTH, PATH_HALF_WIDTH + 4.0, absf(x))
	return maxf(ruins, path if z > 0.0 else 0.0)


## Renvoie la couleur d'une face, avec les braises dans le canal alpha.
func _color_at(x: float, z: float) -> Color:
	var color := COLOR_SOOT.lerp(COLOR_ASH, _relief.get_noise_2d(z, x) * 0.5 + 0.5)
	var ember := 0.0
	for crater in CRATERS:
		var ratio := Vector2(x - crater.x, z - crater.y).length() / crater.z
		if ratio < 1.15:
			color = color.lerp(COLOR_CRATER, smoothstep(1.15, 0.8, ratio))
		ember = maxf(ember, smoothstep(0.42, 0.08, ratio))

	var distance := Vector2(x, z).length()
	var open_ground := (1.0 - _flat_mask(x, z)) * smoothstep(PLAY_RADIUS, PLAY_RADIUS - 10.0, distance)
	var crack := smoothstep(0.02, 0.0, absf(_cracks.get_noise_2d(x, z)))
	ember = maxf(ember, crack * open_ground * 0.18)

	color = color.lerp(COLOR_BORDER, smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance))
	color.a = ember
	return color


func _build() -> void:
	var cells := int(SIZE / CELL_SIZE)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(cells * cells * 6)
	normals.resize(cells * cells * 6)
	colors.resize(cells * cells * 6)

	var heights := PackedFloat32Array()
	heights.resize((cells + 1) * (cells + 1))
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
			var a := Vector3(x, heights[first], z)
			var b := Vector3(x + CELL_SIZE, heights[first + 1], z)
			var c := Vector3(x, heights[first + cells + 1], z + CELL_SIZE)
			var d := Vector3(x + CELL_SIZE, heights[first + cells + 2], z + CELL_SIZE)
			var color := _color_at(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5)
			for triangle: PackedVector3Array in [
				PackedVector3Array([a, b, c]), PackedVector3Array([b, d, c])
			]:
				var normal := (triangle[2] - triangle[0]).cross(triangle[1] - triangle[0]).normalized()
				for vertex in triangle:
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

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
