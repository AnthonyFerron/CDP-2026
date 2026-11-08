@tool
class_name VillageTerrain
extends StaticBody3D
## Sol du Village : un replat pour le bourg, un ruisseau à l'ouest, la colline du moulin et des coteaux autour.

## Ruisseau : position x de son lit, demi-largeur et profondeur.
const STREAM_X := -38.0
const STREAM_HALF_WIDTH := 3.0
const STREAM_DEPTH := 1.4
## Distances au centre (m) entre lesquelles le lit remonte à la rencontre du talus, à ses deux bouts.
const STREAM_END := Vector2(60.0, 68.0)
## Talus élargi le long du ruisseau (m).
const STREAM_BORDER_WIDEN := 3.0
## Berges au sud du pont, adoucies : part de la profondeur du lit selon la distance au milieu du lit (m), entre ces
## points. Maillée tous les 1,25 m, la berge d'origine passait d'un coup du plat à 32°, sur 1,4 m de haut : le joueur
## qui y quittait le sol (un saut, un pas sur le bord) ne la rattrapait plus avant le fond du lit, 1,2 m plus bas.
## Elle descend ici à 20° au plus (24° à l'ouest, où le vallon remonte), et reste au-dessus de l'eau jusqu'au bord de
## son plan (3,75 m du milieu du lit). Le lit garde sa profondeur au milieu, et l'eau son plan.
const SOFT_BANK := [Vector2(0.5, 1.0), Vector2(1.75, 0.76), Vector2(3.0, 0.48), Vector2(4.25, 0.15), Vector2(5.5, 0.0)]
## Rangées z où les berges s'adoucissent : de rien à z = 10 (le pilier de la porte de l'ouest et les culées du pont,
## plus au nord, gardent leur berge) à tout à z = 11,25.
const SOFT_BANK_Z := Vector2(10.0, 11.25)
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
## Limite invisible que le joueur ne peut franchir, à mi-hauteur du talus qui ferme la zone : ni en marchant, ni en
## sautant depuis un mur, un toit ou une charrette. Le portail, à 63 m du centre, reste en deçà. À 72 m, aux deux
## bouts du ruisseau, où le talus est plus doux, on montait en courant et en sautant jusqu'à 8 m de haut, derrière
## les arbres de la bordure : de là, on voyait le talus nu et le bord du monde. À 70 m, on s'arrête à mi-pente, l'œil
## sous la crête.
const LIMIT_RADIUS := 70.0
const LIMIT_SEGMENTS := 72

const COLOR_GRASS := Color(0.32, 0.36, 0.18)
const COLOR_DRY := Color(0.42, 0.38, 0.22)
const COLOR_DIRT := Color(0.36, 0.28, 0.2)
const COLOR_COBBLE := Color(0.4, 0.38, 0.36)
const COLOR_BANK := Color(0.3, 0.27, 0.2)
const COLOR_HILL := Color(0.3, 0.34, 0.2)

@export var ground_material: Material
## Hauteurs et couleurs du sol calculées d'avance (tools/bake_lieux.gd, village_bake.res). Sans elles, ou si elles ne
## correspondent plus aux réglages, le sol est calculé au chargement, comme avant.
@export var bake: LevelBake

## Nom du sol dans le calcul d'avance du lieu.
const BAKE_PART := "village/sol"

var _relief := FastNoiseLite.new()
## Vrai si le sol vient du calcul d'avance : le décor dispersé peut alors lire le sien.
var baked := false


## Hauteurs aux sommets de la grille du maillage.
var _heights := PackedFloat32Array()
var _cells := 0


func _ready() -> void:
	_relief.seed = 5815
	_relief.frequency = 0.025
	_build()
	_build_limit()


func height_at(x: float, z: float) -> float:
	var height := (_relief.get_noise_2d(x, z) * 0.5 + 0.5) * 2.2
	height *= 1.0 - _town_mask(x, z)
	var hill := Vector2(x - MILL_HILL.x, z - MILL_HILL.y).length() / MILL_HILL.z
	height = maxf(height, MILL_HILL.w * (1.0 - smoothstep(0.35, 1.0, hill)))
	var bank := absf(x - STREAM_X)
	# Hors du bourg, les ondulations du sol remontaient le fond du lit au-dessus de l'eau : le ruisseau s'arrêtait à sec
	# bien avant le talus (au nord, dès z = -40). Il coule maintenant au fond d'un vallon aux pentes douces (le relief
	# s'efface sur 7 m de part et d'autre), et ne rejoint la pente qu'au talus.
	height -= maxf(height, 0.0) * (1.0 - smoothstep(STREAM_HALF_WIDTH, STREAM_HALF_WIDTH + 7.0, bank))
	var distance := Vector2(x, z).length()
	# Aux deux bouts, le lit remonte à la rencontre du talus : creusé à pleine profondeur, la pente de sa berge ouest
	# s'ajoutait à celle du talus (jusqu'à 55°), et le joueur glissait de la berge jusqu'au fond, 1,2 à 1,9 m plus bas.
	# L'eau rejoint toujours le talus (jusqu'à 65 m du centre).
	var depth := STREAM_DEPTH * (1.0 - smoothstep(STREAM_END.x, STREAM_END.y, distance))
	var bed := 1.0 - smoothstep(STREAM_HALF_WIDTH * 0.6, STREAM_HALF_WIDTH + 1.5, bank)
	bed = lerpf(bed, _soft_bank(bank), smoothstep(SOFT_BANK_Z.x, SOFT_BANK_Z.y, z))
	height -= depth * bed
	# Le long du ruisseau, le pied du talus monte plus doucement : sa pente et celle des berges ne s'additionnent plus
	# au-delà de 45°, d'où le joueur glissait jusqu'au fond du lit.
	var width := BORDER_WIDTH + STREAM_BORDER_WIDEN * (1.0 - smoothstep(STREAM_HALF_WIDTH + 2.0, STREAM_HALF_WIDTH + 11.0, bank))
	return height + BORDER_HEIGHT * smoothstep(PLAY_RADIUS, PLAY_RADIUS + width, distance)


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


## Part de la profondeur du lit sur une berge adoucie, à bank mètres du milieu du lit.
func _soft_bank(bank: float) -> float:
	if bank <= SOFT_BANK[0].x:
		return SOFT_BANK[0].y
	for index in range(1, SOFT_BANK.size()):
		var high: Vector2 = SOFT_BANK[index]
		if bank < high.x:
			var low: Vector2 = SOFT_BANK[index - 1]
			return lerpf(low.y, high.y, (bank - low.x) / (high.x - low.x))
	return 0.0


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
			var center := (heights[first] + heights[first + 1] + heights[first + cells + 1] + heights[first + cells + 2]) * 0.25
			colors[row * cells + column] = _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5, center)
	return [heights, TerrainGrid.colors_to_bytes(colors)]


## Anneau de murs invisibles, hauts et épais, tout autour du village.
func _build_limit() -> void:
	var length := TAU * LIMIT_RADIUS / LIMIT_SEGMENTS + 0.6
	for index in LIMIT_SEGMENTS:
		var angle := TAU * index / LIMIT_SEGMENTS
		var shape := BoxShape3D.new()
		shape.size = Vector3(length, 80.0, 1.5)
		var collision := CollisionShape3D.new()
		collision.name = "Limit%d" % index
		collision.shape = shape
		collision.position = Vector3(cos(angle) * LIMIT_RADIUS, 25.0, sin(angle) * LIMIT_RADIUS)
		collision.rotation.y = -angle + PI * 0.5
		add_child(collision)
