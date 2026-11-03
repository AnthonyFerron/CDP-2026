@tool
class_name PlaineTerrain
extends StaticBody3D
## Sol de la Plaine : relief brûlé, cratères de lave, chemin et remparts naturels qui ferment la zone.

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
## Part du rayon d'un cratère recouverte par la lave.
const LAVA_RATIO := 0.6
const SIZE := 170.0
const CELL_SIZE := 1.25
## Rayon de la zone jouable, au-delà duquel le sol remonte.
const PLAY_RADIUS := 68.0
const BORDER_WIDTH := 9.0
const BORDER_HEIGHT := 16.0
const RUINS_RADIUS := 24.0
const PATH_HALF_WIDTH := 5.0
## Chemin de cendre tassée entre le portail et la porte de la bibliothèque.
const TRAIL_START := 9.0
const TRAIL_END := 54.0
const TRAIL_HALF_WIDTH := 1.9

const COLOR_ASH := Color(0.2, 0.18, 0.2)
const COLOR_SOOT := Color(0.11, 0.095, 0.11)
const COLOR_CRATER := Color(0.22, 0.09, 0.07)
const COLOR_BORDER := Color(0.26, 0.23, 0.28)
const COLOR_TRAIL := Color(0.3, 0.26, 0.25)

@export var ground_material: Material

var _relief := FastNoiseLite.new()


## Hauteurs aux sommets de la grille du maillage.
var _heights := PackedFloat32Array()
var _cells := 0


func _ready() -> void:
	_relief.seed = 2026
	_relief.frequency = 0.035
	_build()


func height_at(x: float, z: float) -> float:
	var height := _relief.get_noise_2d(x, z) * 0.8
	for crater in CRATERS:
		height += _crater_profile(x, z, crater)
	height *= 1.0 - _flat_mask(x, z)
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


func _crater_profile(x: float, z: float, crater: Vector4) -> float:
	var ratio := Vector2(x - crater.x, z - crater.y).length() / crater.z
	var bowl := -crater.w * (1.0 - ratio * ratio) if ratio < 1.0 else 0.0
	var rim := crater.w * 0.35 * exp(-pow((ratio - 1.0) / 0.25, 2.0))
	return bowl + rim


## Vaut 1 sous les ruines et sur le chemin du portail, où le sol doit rester plat.
## Replat du campement des soldats, au bord du chemin : (x, z, rayon), comme dans tools/build_plaine.py.
const CAMP := Vector3(14.0, 42.0, 7.0)


func _flat_mask(x: float, z: float) -> float:
	var ruins := 1.0 - smoothstep(RUINS_RADIUS, RUINS_RADIUS + 8.0, Vector2(x, z).length())
	ruins = maxf(ruins, 1.0 - smoothstep(CAMP.z, CAMP.z + 5.0, Vector2(x - CAMP.x, z - CAMP.y).length()))
	var path := 1.0 - smoothstep(PATH_HALF_WIDTH, PATH_HALF_WIDTH + 4.0, absf(x))
	return maxf(ruins, path if z > 0.0 else 0.0)


## Renvoie la couleur d'une face : cendre, fond de cratère, chemin ou rempart.
func _face_color(x: float, z: float) -> Color:
	var color := COLOR_SOOT.lerp(COLOR_ASH, _relief.get_noise_2d(z, x) * 0.5 + 0.5)
	for crater in CRATERS:
		var ratio := Vector2(x - crater.x, z - crater.y).length() / crater.z
		if ratio < 1.15:
			color = color.lerp(COLOR_CRATER, smoothstep(1.15, 0.75, ratio))
	var wander := absf(x + sin(z * 0.15) * 0.8)
	var trail := (1.0 - smoothstep(TRAIL_HALF_WIDTH, TRAIL_HALF_WIDTH + 1.0, wander))
	trail *= smoothstep(TRAIL_START, TRAIL_START + 2.0, z) * smoothstep(TRAIL_END, TRAIL_END - 3.0, z)
	color = color.lerp(COLOR_TRAIL, trail * (0.75 + _relief.get_noise_2d(x * 3.0, z * 3.0) * 0.25))
	var distance := Vector2(x, z).length()
	return color.lerp(COLOR_BORDER, smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance))


## Renvoie, pour un sommet, où les veines de braise sont permises et la lueur de la lave voisine.
func _vertex_glow(x: float, z: float) -> Vector2:
	var distance := Vector2(x, z).length()
	var cracks := (1.0 - _flat_mask(x, z)) * smoothstep(PLAY_RADIUS, PLAY_RADIUS - 10.0, distance)
	var glow := 0.0
	for crater in CRATERS:
		var ratio := Vector2(x - crater.x, z - crater.y).length() / crater.z
		glow = maxf(glow, smoothstep(LAVA_RATIO + 0.3, LAVA_RATIO - 0.05, ratio))
		cracks *= smoothstep(LAVA_RATIO * 0.9, LAVA_RATIO + 0.15, ratio)
	return Vector2(cracks, glow)


func _build() -> void:
	var cells := int(SIZE / CELL_SIZE)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for array: Variant in [vertices, normals, colors, uvs]:
		array.resize(cells * cells * 6)

	var heights := PackedFloat32Array()
	var glows := PackedVector2Array()
	heights.resize((cells + 1) * (cells + 1))
	_cells = cells
	glows.resize((cells + 1) * (cells + 1))
	for row in cells + 1:
		for column in cells + 1:
			var x := column * CELL_SIZE - SIZE * 0.5
			var z := row * CELL_SIZE - SIZE * 0.5
			heights[row * (cells + 1) + column] = height_at(x, z)
			glows[row * (cells + 1) + column] = _vertex_glow(x, z)

	var index := 0
	for row in cells:
		for column in cells:
			var x := column * CELL_SIZE - SIZE * 0.5
			var z := row * CELL_SIZE - SIZE * 0.5
			var first := row * (cells + 1) + column
			var corners: Array[int] = [first, first + 1, first + cells + 1, first + cells + 2]
			var points: Array[Vector3] = [
				Vector3(x, heights[first], z),
				Vector3(x + CELL_SIZE, heights[first + 1], z),
				Vector3(x, heights[first + cells + 1], z + CELL_SIZE),
				Vector3(x + CELL_SIZE, heights[first + cells + 2], z + CELL_SIZE),
			]
			var color := _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5)
			for triangle: Array in [[0, 1, 2], [1, 3, 2]]:
				var a := points[triangle[0]]
				var b := points[triangle[1]]
				var c := points[triangle[2]]
				var normal := (c - a).cross(b - a).normalized()
				for corner: int in triangle:
					var glow := glows[corners[corner]]
					vertices[index] = points[corner]
					normals[index] = normal
					colors[index] = Color(color, glow.x)
					uvs[index] = Vector2(glow.y, 0.0)
					index += 1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
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
