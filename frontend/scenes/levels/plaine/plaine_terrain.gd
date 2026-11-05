@tool
class_name PlaineTerrain
extends StaticBody3D
## Sol de la Plaine : relief brûlé, cratères de lave, coulée sous le pont, chemin, replats du champ de bataille
## et remparts naturels qui ferment la zone.

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
## Trous d'obus de la guerre contre Vibelandia, sans lave : position (x, z), rayon et profondeur.
## Ils creusent aussi les replats, mais restent à l'écart du chemin, des ruines et du décor posé.
const IMPACTS: Array[Vector4] = [
	Vector4(-36.0, 40.0, 4.0, 1.2), Vector4(-40.0, 2.0, 3.5, 1.0), Vector4(-38.0, -32.0, 4.0, 1.3),
	Vector4(-6.0, -52.0, 4.0, 1.2), Vector4(6.0, -38.0, 3.5, 1.0), Vector4(36.0, -28.0, 4.0, 1.2),
	Vector4(48.0, 16.0, 4.5, 1.4), Vector4(38.0, 44.0, 3.5, 1.0), Vector4(-22.0, 2.0, 3.0, 0.9),
	Vector4(24.0, 8.0, 3.5, 1.1), Vector4(-52.0, 6.0, 3.5, 1.0), Vector4(54.0, -18.0, 3.5, 1.1),
	Vector4(-12.0, 56.0, 3.0, 0.9), Vector4(10.0, 58.0, 3.0, 0.9),
]
## Part du rayon d'un cratère recouverte par la lave.
const LAVA_RATIO := 0.6
const SIZE := 170.0
const CELL_SIZE := 1.25
## Rayon de la zone jouable, au-delà duquel le sol remonte.
const PLAY_RADIUS := 68.0
const BORDER_WIDTH := 9.0
const BORDER_HEIGHT := 16.0
## Mur invisible au pied des remparts : rien ne se joue au-delà, et la pente ne doit pas mener hors du monde.
const LIMIT_RADIUS := 66.5
const LIMIT_HEIGHT := 70.0
const RUINS_RADIUS := 24.0
const PATH_HALF_WIDTH := 5.0
## Chemin de cendre tassée entre le portail et la porte de la bibliothèque.
const TRAIL_START := 9.0
const TRAIL_END := 54.0
const TRAIL_HALF_WIDTH := 1.9

## Coulée de lave qui relie deux cratères et coupe le chemin sous le pont de pierre : points (x, z) de son lit.
## Le lit traverse le chemin en ligne droite, d'ouest en est, sous le pont, et ses deux bouts entrent dans les lacs.
const LAVA_FLOW: Array[Vector2] = [
	Vector2(23.2, 26.45), Vector2(21.0, 26.8), Vector2(14.0, 29.2), Vector2(6.5, 29.5), Vector2(-6.5, 29.5),
	Vector2(-13.5, 27.2), Vector2(-22.0, 21.0), Vector2(-24.9, 19.6),
]
const FLOW_HALF_WIDTH := 3.2
const FLOW_DEPTH := 1.6
## Hauteur de la lave au-dessus du fond du lit : elle en occupe le milieu.
const FLOW_LAVA_RISE := 0.7
## Longueur, au-delà du bord d'un lac, sur laquelle la coulée rejoint son niveau.
const FLOW_JOIN := 3.0

const COLOR_ASH := Color(0.2, 0.18, 0.2)
const COLOR_SOOT := Color(0.11, 0.095, 0.11)
const COLOR_CRATER := Color(0.22, 0.09, 0.07)
const COLOR_BORDER := Color(0.26, 0.23, 0.28)
const COLOR_TRAIL := Color(0.3, 0.26, 0.25)
## Bruit du relief.
const RELIEF_SEED := 2026
const RELIEF_FREQUENCY := 0.035
## Écart toléré entre une hauteur recalculée et celle du sol calculé d'avance : le bruit peut différer d'un
## processeur à l'autre de quelques millionièmes, pas d'un millimètre.
const BAKE_TOLERANCE := 0.001

@export var ground_material: Material
## Sol calculé d'avance (tools/bake_plaine.gd). Sans lui, ou s'il ne correspond plus aux réglages, le sol est
## calculé au chargement.
@export var bake: PlaineBake

var _relief := FastNoiseLite.new()
## Niveau de la lave de chaque cratère, calé sur son bord : la coulée s'y raccorde.
var _pool_levels: Array[float] = []


## Hauteurs aux sommets de la grille du maillage.
var _heights := PackedFloat32Array()
var _cells := 0


func _ready() -> void:
	_relief.seed = RELIEF_SEED
	_relief.frequency = RELIEF_FREQUENCY
	_pool_levels.clear()
	for crater in CRATERS:
		_pool_levels.append(_pool_level(crater))
	if is_baked():
		_build_baked()
	else:
		if bake:
			push_warning("Plaine : sol calculé d'avance périmé, relancer tools/bake_plaine.gd")
		_build()
	_build_limit()


## Empreinte des réglages dont découle le sol : si l'un change, le sol calculé d'avance est périmé.
static func settings_signature() -> String:
	return var_to_str([CRATERS, IMPACTS, LAVA_RATIO, SIZE, CELL_SIZE, PLAY_RADIUS, BORDER_WIDTH, BORDER_HEIGHT,
		RUINS_RADIUS, PATH_HALF_WIDTH, TRAIL_START, TRAIL_END, TRAIL_HALF_WIDTH, LAVA_FLOW, FLOW_HALF_WIDTH, FLOW_DEPTH,
		FLOW_LAVA_RISE, FLOW_JOIN, COLOR_ASH, COLOR_SOOT, COLOR_CRATER, COLOR_BORDER, COLOR_TRAIL, SITES, RELIEF_SEED,
		RELIEF_FREQUENCY]).md5_text()


## Vrai si le sol calculé d'avance correspond aux réglages et au relief : même empreinte, même niveau de lave dans
## chaque cratère, et mêmes hauteurs en quelques points de la grille.
func is_baked() -> bool:
	var cells := int(SIZE / CELL_SIZE)
	if not bake or not bake.ground or bake.terrain_signature != settings_signature():
		return false
	if bake.heights.size() != (cells + 1) * (cells + 1) or bake.pool_levels.size() != CRATERS.size():
		return false
	for index in CRATERS.size():
		if absf(bake.pool_levels[index] - crater_lava_level(index)) > BAKE_TOLERANCE:
			return false
	for spot: Vector2i in [Vector2i(0, 0), Vector2i(cells / 2, cells / 2), Vector2i(cells / 3, cells * 2 / 3),
			Vector2i(cells * 3 / 5, cells / 4), Vector2i(cells * 7 / 10, cells * 3 / 5), Vector2i(cells / 2, cells * 3 / 4)]:
		var height := height_at(spot.x * CELL_SIZE - SIZE * 0.5, spot.y * CELL_SIZE - SIZE * 0.5)
		if absf(bake.heights[spot.y * (cells + 1) + spot.x] - height) > BAKE_TOLERANCE:
			return false
	return true


func height_at(x: float, z: float) -> float:
	var height := _carve_flow(x, z, base_height_at(x, z))
	for impact in IMPACTS:
		height += _crater_profile(x, z, impact)
	return height


## Part du rayon d'un trou d'obus où rien ne doit être posé : son fond et ses pentes.
static func impact_ratio(x: float, z: float) -> float:
	var best := INF
	for impact in IMPACTS:
		best = minf(best, Vector2(x - impact.x, z - impact.y).length() / impact.z)
	return best


## Hauteur du sol sans le lit de la coulée : sert à caler la lave des cratères sur leur bord.
func base_height_at(x: float, z: float) -> float:
	var height := _relief.get_noise_2d(x, z) * 0.8
	for crater in CRATERS:
		height += _crater_profile(x, z, crater)
	height *= 1.0 - _flat_mask(x, z)
	var distance := Vector2(x, z).length()
	return height + BORDER_HEIGHT * smoothstep(PLAY_RADIUS, PLAY_RADIUS + BORDER_WIDTH, distance)


## Distance horizontale au milieu du lit de la coulée.
static func flow_distance(x: float, z: float) -> float:
	return Vector2(x, z).distance_to(flow_nearest(x, z))


## Point du milieu du lit le plus proche.
static func flow_nearest(x: float, z: float) -> Vector2:
	var point := Vector2(x, z)
	var best := INF
	var nearest := LAVA_FLOW[0]
	for index in LAVA_FLOW.size() - 1:
		var a := LAVA_FLOW[index]
		var b := LAVA_FLOW[index + 1]
		var t := clampf((point - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var candidate := a.lerp(b, t)
		if point.distance_to(candidate) < best:
			best = point.distance_to(candidate)
			nearest = candidate
	return nearest


## Niveau de la lave d'un cratère : juste sous le point le plus bas de son bassin, au bord de la lave.
func _pool_level(crater: Vector4) -> float:
	var lowest := INF
	for i in 12:
		var edge := Vector2.from_angle(TAU * i / 12.0) * crater.z * LAVA_RATIO
		lowest = minf(lowest, base_height_at(crater.x + edge.x, crater.y + edge.y))
	return lowest - 0.08


## Niveau de la lave du cratère donné (index dans CRATERS).
func crater_lava_level(index: int) -> float:
	if _pool_levels.is_empty():
		return _pool_level(CRATERS[index])
	return _pool_levels[index]


## Hauteur de la lave de la coulée en un point de son milieu : au milieu de son lit, et au niveau du lac à
## l'approche d'un cratère, un peu au-dessus de lui sur son bord pour en couvrir la croûte, un peu en dessous
## au large pour disparaître sous sa surface.
func flow_lava_height(x: float, z: float) -> float:
	var lava := base_height_at(x, z) - FLOW_DEPTH + FLOW_LAVA_RISE
	for index in CRATERS.size():
		var crater := CRATERS[index]
		var radius := crater.z * LAVA_RATIO
		var distance := Vector2(x - crater.x, z - crater.y).length()
		if distance > radius + FLOW_JOIN:
			continue
		var level := crater_lava_level(index)
		var near := lerpf(level - 0.05, level + 0.03, smoothstep(radius - 0.9, radius - 0.3, distance))
		lava = lerpf(near, lava, smoothstep(radius + 0.3, radius + FLOW_JOIN, distance))
	return lava


## Demi-largeur de la lave dans le lit, là où elle affleure les berges.
static func flow_lava_half_width() -> float:
	return FLOW_HALF_WIDTH * sqrt(FLOW_LAVA_RISE / FLOW_DEPTH)


## Lit en creux de la coulée, creusé sous sa ligne de lave : son fond est à FLOW_LAVA_RISE sous la lave, et ses
## berges remontent au-dessus d'elle, jusque dans les lacs où elle se jette. Il ne remblaie jamais le sol.
func _carve_flow(x: float, z: float, ground: float) -> float:
	var nearest := flow_nearest(x, z)
	var ratio := Vector2(x, z).distance_to(nearest) / FLOW_HALF_WIDTH
	if ratio >= 1.0:
		return ground
	var bed := flow_lava_height(nearest.x, nearest.y) - FLOW_LAVA_RISE
	return minf(ground, bed + FLOW_DEPTH * ratio * ratio)


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


## Replat du campement des soldats, au bord du chemin : (x, z, rayon), comme dans tools/build_plaine.py.
const CAMP := Vector3(14.0, 42.0, 7.0)
## Replats du champ de bataille, où le décor est posé à plat : (x, z, rayon), comme SITES dans tools/build_plaine.py.
const SITES: Array[Vector3] = [
	CAMP,
	Vector3(22.5, 50.5, 4.5),  # Tombes des défenseurs, derrière le camp.
	Vector3(-14.0, 39.0, 6.5),  # Engins de siège brisés.
	Vector3(-23.0, 52.0, 7.5),  # Tour de guet effondrée.
	Vector3(17.0, -22.0, 5.0),  # Batterie de balistes, derrière la bibliothèque.
]


## Vaut 1 sous les ruines, sur le chemin du portail et sur les replats, où le sol doit rester plat.
func _flat_mask(x: float, z: float) -> float:
	var ruins := 1.0 - smoothstep(RUINS_RADIUS, RUINS_RADIUS + 8.0, Vector2(x, z).length())
	for site in SITES:
		ruins = maxf(ruins, 1.0 - smoothstep(site.z, site.z + 5.0, Vector2(x - site.x, z - site.y).length()))
	var path := 1.0 - smoothstep(PATH_HALF_WIDTH, PATH_HALF_WIDTH + 4.0, absf(x))
	return maxf(ruins, path if z > 0.0 else 0.0)


## Renvoie la couleur d'une face : cendre, fond de cratère, chemin ou rempart.
func _face_color(x: float, z: float) -> Color:
	var color := COLOR_SOOT.lerp(COLOR_ASH, _relief.get_noise_2d(z, x) * 0.5 + 0.5)
	for crater in CRATERS:
		var ratio := Vector2(x - crater.x, z - crater.y).length() / crater.z
		if ratio < 1.15:
			color = color.lerp(COLOR_CRATER, smoothstep(1.15, 0.75, ratio))
	var bed := flow_distance(x, z) / FLOW_HALF_WIDTH
	if bed < 1.3:
		color = color.lerp(COLOR_CRATER, smoothstep(1.3, 0.8, bed))
	# Les trous d'obus sont noircis, plus sombres au fond.
	var impact := impact_ratio(x, z)
	if impact < 1.3:
		color = color.lerp(COLOR_SOOT * 0.6, smoothstep(1.3, 0.3, impact))
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
	# La coulée chauffe ses berges et y fait courir des veines de braise.
	var lava_edge := flow_lava_half_width() / FLOW_HALF_WIDTH
	var bed := flow_distance(x, z) / FLOW_HALF_WIDTH
	glow = maxf(glow, smoothstep(lava_edge + 0.45, lava_edge - 0.05, bed))
	var heat := 0.8 * (1.0 - smoothstep(1.0, 2.2, bed))
	cracks = maxf(cracks, heat) * smoothstep(lava_edge, lava_edge + 0.2, bed)
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
	_heights = heights
	_add_ground(mesh, vertices)


## Le sol calculé d'avance : ses hauteurs, son maillage, et sa collision tirée des sommets du maillage.
func _build_baked() -> void:
	_cells = int(SIZE / CELL_SIZE)
	_heights = bake.heights
	var mesh := bake.ground
	# Dans l'éditeur, le matériau se pose sur une copie : la ressource calculée d'avance reste sans matériau.
	if Engine.is_editor_hint():
		mesh = mesh.duplicate()
	_add_ground(mesh, mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])


func _add_ground(mesh: ArrayMesh, vertices: PackedVector3Array) -> void:
	mesh.surface_set_material(0, ground_material)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)


## Hauteurs de la grille du sol, telles que le terrain les a calculées ou lues (pour tools/bake_plaine.gd).
func grid_heights() -> PackedFloat32Array:
	return _heights


## Mur invisible en cercle au pied des remparts, comme celui du hub : des panneaux qui se chevauchent, assez hauts
## pour qu'aucun saut, même depuis un toit ou un rocher, ne passe par-dessus.
func _build_limit() -> void:
	var segments := 72
	var length := TAU * LIMIT_RADIUS / segments + 0.6
	for index in segments:
		var angle := TAU * index / segments
		var shape := BoxShape3D.new()
		shape.size = Vector3(length, LIMIT_HEIGHT, 1.0)
		var collision := CollisionShape3D.new()
		collision.name = "Limit%d" % index
		collision.shape = shape
		collision.position = Vector3(cos(angle) * LIMIT_RADIUS, LIMIT_HEIGHT * 0.5 - 15.0, sin(angle) * LIMIT_RADIUS)
		collision.rotation.y = -angle + PI * 0.5
		add_child(collision)
