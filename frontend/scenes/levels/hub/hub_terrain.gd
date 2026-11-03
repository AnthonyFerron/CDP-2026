@tool
class_name HubTerrain
extends StaticBody3D
## Sol du hub : un plateau en légères collines autour du camp, des chemins vers les portails et le fort.

## Portails : position (x, z) de chaque zone, sur un cercle autour du camp.
const PORTALS := {
	&"plaine": Vector2(-17.0, -17.0),
	&"desert": Vector2(17.0, -17.0),
	&"marais": Vector2(17.0, 17.0),
	&"village": Vector2(-17.0, 17.0),
}
const FORT := Vector2(0.0, -40.0)
const CAMP_RADIUS := 13.0
const PATH_HALF_WIDTH := 1.6
const SIZE := 150.0
const CELL_SIZE := 1.25
const PLAY_RADIUS := 52.0
const BORDER_WIDTH := 10.0
const BORDER_HEIGHT := 9.0

const COLOR_GRASS := Color(0.3, 0.42, 0.18)
const COLOR_GRASS_DARK := Color(0.2, 0.3, 0.13)
const COLOR_PATH := Color(0.42, 0.33, 0.22)
const COLOR_HILL := Color(0.26, 0.33, 0.17)

@export var ground_material: Material

var _relief := FastNoiseLite.new()


func _ready() -> void:
	_relief.seed = 5800
	_relief.frequency = 0.03
	_build()


func height_at(x: float, z: float) -> float:
	var height := (_relief.get_noise_2d(x, z) * 0.5 + 0.5) * 1.6
	height *= 1.0 - flat_mask(x, z)
	var distance := Vector2(x, z).length()
	return height + BORDER_HEIGHT * smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance)


## Vaut 1 sur le camp, les chemins, les abords des portails et du fort, où le sol reste plat.
func flat_mask(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var mask := 1.0 - smoothstep(CAMP_RADIUS, CAMP_RADIUS + 6.0, point.length())
	for target: Vector2 in PORTALS.values() + [FORT]:
		mask = maxf(mask, 1.0 - smoothstep(4.0, 9.0, point.distance_to(target)))
		var along := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, target)
		mask = maxf(mask, 1.0 - smoothstep(PATH_HALF_WIDTH + 1.0, PATH_HALF_WIDTH + 5.0, point.distance_to(along)))
	return mask


## Vaut 1 sur les chemins de terre battue.
func path_mask(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var mask := 0.0
	for target: Vector2 in PORTALS.values() + [FORT]:
		var along := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, target)
		var wobble := _relief.get_noise_2d(x * 4.0, z * 4.0) * 0.5
		mask = maxf(mask, 1.0 - smoothstep(PATH_HALF_WIDTH - 0.4, PATH_HALF_WIDTH + 0.4, point.distance_to(along) + wobble))
	mask = maxf(mask, 1.0 - smoothstep(4.5, 5.5, point.length()))
	return mask


func _face_color(x: float, z: float) -> Color:
	var color := COLOR_GRASS_DARK.lerp(COLOR_GRASS, _relief.get_noise_2d(z * 2.0, x * 2.0) * 0.5 + 0.5)
	color = color.lerp(COLOR_PATH, path_mask(x, z))
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
			var color := _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5)
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

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
