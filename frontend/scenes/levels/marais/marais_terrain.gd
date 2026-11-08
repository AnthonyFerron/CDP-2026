@tool
class_name MaraisTerrain
extends StaticBody3D
## Sol du Marais : un fond de vase sous l'eau, des îlots plats et des berges qui ferment la zone.

## Position (x, z), rayon et hauteur de chaque îlot. Les quatre premiers portent le parcours : l'arrivée,
## le campement du gardien, le cimetière et la crypte. Les autres se voient depuis les pontons : la chapelle
## en ruine, le bosquet mort, les pierres levées, la dernière maison de Brumeval et le débarcadère.
const ISLANDS: Array[Vector4] = [
	Vector4(0.0, 56.0, 13.0, 0.4),
	Vector4(-20.0, 22.0, 9.0, 0.4),
	Vector4(16.0, 0.0, 19.0, 0.4),
	Vector4(0.0, -36.0, 16.0, 0.4),
	Vector4(-36.0, -4.0, 9.5, 0.3),
	Vector4(34.0, -30.0, 6.0, 0.3),
	Vector4(-30.0, -44.0, 6.5, 0.3),
	Vector4(36.0, 32.0, 6.0, 0.3),
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
## Limite invisible au pied de la berge : on ne quitte pas le Marais, même en sautant depuis un objet.
const LIMIT_RADIUS := 68.5

const COLOR_MUD := Color(0.13, 0.11, 0.08)
const COLOR_SILT := Color(0.2, 0.19, 0.13)
const COLOR_MOSS := Color(0.16, 0.24, 0.12)
const COLOR_GRASS := Color(0.22, 0.3, 0.15)
const COLOR_BANK := Color(0.14, 0.17, 0.11)

@export var ground_material: Material
## Hauteurs et couleurs du sol calculées d'avance (tools/bake_lieux.gd, marais_bake.res). Sans elles, ou si elles ne
## correspondent plus aux réglages, le sol est calculé au chargement, comme avant.
@export var bake: LevelBake

## Nom du sol dans le calcul d'avance du lieu.
const BAKE_PART := "marais/sol"

var _relief := FastNoiseLite.new()
## Vrai si le sol vient du calcul d'avance.
var baked := false


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
		# Le relief des berges naît doucement au bord du replat, sans marche sous ce qui y est posé.
		var top := island.w + _relief.get_noise_2d(z, x) * 0.35 * smoothstep(FLAT_RATIO, FLAT_RATIO + 0.2, ratio)
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
	_cells = cells
	var signature := LevelBake.signature_of(self)
	var scripts: Array[Script] = [get_script()]
	var grid: Variant = bake.data(BAKE_PART, signature, scripts) if bake else null
	baked = grid != null and TerrainGrid.spot_check(grid[0], cells, cells, -SIZE * 0.5, -SIZE * 0.5, CELL_SIZE, height_at)
	if grid != null and not baked:
		push_warning("Calcul d'avance « %s » périmé (relief changé), relancer tools/bake_lieux.gd" % BAKE_PART)
	if not baked:
		grid = _compute_grid(cells)
		LevelBake.record(BAKE_PART, signature, scripts, grid)
	var heights: PackedFloat32Array = grid[0]
	var surface := TerrainGrid.assemble(heights, grid[1], cells, cells, -SIZE * 0.5, -SIZE * 0.5, CELL_SIZE)
	var vertices: PackedVector3Array = surface[0]

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = surface[1]
	arrays[Mesh.ARRAY_COLOR] = surface[2]
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


## Ce que le chargement calculait : la hauteur de chaque sommet de la grille et la couleur de chaque case (octets
## RGBA8, TerrainGrid). C'est la partie lente, calculée d'avance par tools/bake_lieux.gd.
func _compute_grid(cells: int) -> Array:
	var heights := PackedFloat32Array()
	heights.resize((cells + 1) * (cells + 1))
	for row in cells + 1:
		for column in cells + 1:
			heights[row * (cells + 1) + column] = height_at(
				column * CELL_SIZE - SIZE * 0.5, row * CELL_SIZE - SIZE * 0.5
			)
	var colors := PackedColorArray()
	colors.resize(cells * cells)
	for row in cells:
		for column in cells:
			var x := column * CELL_SIZE - SIZE * 0.5
			var z := row * CELL_SIZE - SIZE * 0.5
			var first := row * (cells + 1) + column
			var center_height := (heights[first] + heights[first + 1] + heights[first + cells + 1] + heights[first + cells + 2]) * 0.25
			colors[row * cells + column] = _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5, center_height)
	return [heights, TerrainGrid.colors_to_bytes(colors)]


## Mur invisible en cercle, de la vase jusqu'à 35 m de haut : les pas comme les sauts s'y arrêtent.
func _build_limit() -> void:
	var segments := 72
	var length := TAU * LIMIT_RADIUS / segments + 0.5
	for index in segments:
		var angle := TAU * index / segments
		var shape := BoxShape3D.new()
		shape.size = Vector3(length, 40.0, 1.0)
		var limit := CollisionShape3D.new()
		limit.name = "Limit%d" % index
		limit.shape = shape
		limit.position = Vector3(cos(angle) * (LIMIT_RADIUS + 0.5), 15.0, sin(angle) * (LIMIT_RADIUS + 0.5))
		limit.rotation.y = -angle + PI * 0.5
		add_child(limit)
