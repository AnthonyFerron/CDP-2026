@tool
class_name HubTerrain
extends StaticBody3D
## Sol du hub : le village de Codia sur un plateau aplani, au fond d'une vallée qui s'ouvre vers l'est, où la
## rivière descend des montagnes du nord-est et passe entre le village et le bunker. Des chemins mènent aux
## portails, au château au nord, au bunker à l'est, et des ruelles aux lieux qui entourent le village.

## Portails : position (x, z) de chaque zone, sur un cercle autour du village.
const PORTALS := {
	&"plaine": Vector2(-38.0, -38.0),
	&"desert": Vector2(38.0, -38.0),
	&"marais": Vector2(38.0, 38.0),
	&"village": Vector2(-38.0, 38.0),
}
## Porte du château, et rectangle de son enceinte (x, z, largeur, profondeur).
const CASTLE_GATE := Vector2(0.0, -50.0)
const CASTLE_AREA := Rect2(-25.0, -95.0, 50.0, 45.0)
const BUNKER := Vector2(78.0, 0.0)
## Bâtiments et lieux, comme dans tools/build_hub.py : (x, z, rayon) d'un replat sans arbres.
const LANDMARKS: Array[Vector3] = [
	# École, taverne, chapelle, forge, ferme et mine.
	Vector3(0.0, 60.0, 10.0), Vector3(-60.0, 0.0, 10.0), Vector3(-54.0, -30.0, 11.0),
	Vector3(55.0, 18.0, 8.0), Vector3(50.0, 64.0, 14.0), Vector3(84.0, -40.0, 13.0),
	# Lavoir, boulangerie, moulin, caserne et sa cour, écuries, scriptorium, herboristerie, tour de Merlon.
	Vector3(54.0, 6.5, 5.0), Vector3(52.0, 34.0, 7.0), Vector3(61.0, 48.0, 7.5), Vector3(-48.0, -66.0, 11.0),
	Vector3(-68.0, -46.0, 9.0), Vector3(-74.0, -16.0, 7.0), Vector3(-60.0, 30.0, 8.0), Vector3(-70.0, 58.0, 7.0),
	# Halle du marché, verger.
	Vector3(-24.0, 66.0, 8.0), Vector3(14.0, 82.0, 12.0),
]
## Enclos autour des bâtiments, où le sol reste plat comme sous un lieu, sans en écarter les arbres : (x, z, rayon).
## L'enclos des écuries royales (tools/build_hub.py : furnish_stables) court jusqu'à 12,7 m du centre des écuries,
## dans la pente qui suivait leur replat : ses barrières traversaient le sol.
const YARDS: Array[Vector3] = [Vector3(-74.5, -45.0, 9.0)]
## Chemins qui mènent à l'école et à la taverne.
const LANES: Array[Vector2] = [Vector2(0.0, 55.0), Vector2(-53.0, 0.0)]
## Ruelles qui partent d'un chemin vers les lieux du pourtour : chaque tracé est une suite de points.
const ALLEYS := [
	[Vector2(-28.0, -28.0), Vector2(-41.0, -49.0), Vector2(-48.0, -61.6)],
	[Vector2(-41.0, -49.0), Vector2(-61.6, -44.0)],
	[Vector2(-47.0, -2.0), Vector2(-58.0, -9.0), Vector2(-69.6, -14.0)],
	[Vector2(-29.0, 29.0), Vector2(-55.6, 32.0)],
	[Vector2(-55.6, 32.0), Vector2(-54.0, 36.0), Vector2(-62.0, 48.0), Vector2(-67.6, 53.4)],
	[Vector2(-5.0, 52.0), Vector2(-17.0, 58.0), Vector2(-24.0, 61.0)],
	[Vector2(2.0, 52.0), Vector2(8.6, 55.0), Vector2(12.0, 72.0)],
	[Vector2(31.0, 31.0), Vector2(47.6, 36.0)],
	[Vector2(47.6, 36.0), Vector2(46.5, 40.0), Vector2(52.0, 46.0), Vector2(56.6, 50.0)],
	[Vector2(71.0, 0.0), Vector2(74.0, -14.0), Vector2(78.5, -31.0)],
	[Vector2(70.5, -66.0), Vector2(76.0, -52.0), Vector2(79.5, -38.0)],
	[Vector2(6.0, -46.5), Vector2(29.0, -47.5), Vector2(31.0, -52.0)],
	[Vector2(39.0, -44.0), Vector2(42.0, -52.0)],
]
## Allées gravillonnées du jardin du roi, à l'est du château.
const PARK_AREA := Rect2(29.0, -90.0, 23.0, 38.0)
const PARK_ALLEYS := [
	[Vector2(42.0, -52.0), Vector2(42.0, -64.0)],
	[Vector2(42.0, -76.0), Vector2(42.0, -88.4)],
	[Vector2(31.0, -52.0), Vector2(31.0, -88.0), Vector2(41.0, -88.0)],
	[Vector2(30.0, -70.0), Vector2(36.0, -70.0)],
	[Vector2(48.0, -70.0), Vector2(55.0, -66.0)],
]
## Rond-point de la statue, au croisement des allées : centre et rayon.
const PARK_CIRCLE := Vector3(42.0, -70.0, 6.0)

## Le village occupe ce rayon autour du feu de camp ; une rue en fait le tour entre ses deux rangs de maisons.
const VILLAGE_RADIUS := 46.0
const RING_STREET := 31.0
const PATH_HALF_WIDTH := 1.6
## Grille du maillage : coin nord-ouest, nombre de cases, plus large à l'est où la vallée s'ouvre.
const GRID_ORIGIN := Vector2(-140.0, -140.0)
const COLUMNS := 152
const ROWS := 140
const CELL_SIZE := 2.0
## Forme de la vallée : distance de la limite au feu de camp tous les 30 degrés, depuis l'ouest (-180°) en
## passant par le nord. Les montagnes montent à partir de BORDER_GAP avant la limite.
const EXTENT: Array[float] = [106.0, 106.0, 106.0, 106.0, 114.0, 122.0, 126.0, 122.0, 112.0, 106.0, 106.0, 106.0]
const BORDER_GAP := 6.0
## Plus petits rayons du plateau et de la limite, à l'ouest et au nord.
const PLAY_RADIUS := 100.0
const LIMIT_RADIUS := 106.0
const BORDER_WIDTH := 30.0
const BORDER_HEIGHT := 30.0

## Rivière : points de son tracé (x, z, demi-largeur de l'eau), de sa source dans les montagnes du nord-est à
## sa sortie au sud-est. La roue du moulin (MILL_WHEEL de tools/build_hub.py) tourne dans son courant, à z = 48.
const RIVER: Array[Vector3] = [
	Vector3(51.0, -127.0, 2.6), Vector3(53.0, -115.0, 3.0), Vector3(56.0, -104.0, 3.6), Vector3(60.0, -92.0, 4.0),
	Vector3(63.0, -78.0, 4.4), Vector3(63.0, -66.0, 4.0), Vector3(61.0, -52.0, 4.6), Vector3(60.0, -38.0, 4.8),
	Vector3(61.0, -24.0, 4.5), Vector3(62.0, -12.0, 4.0), Vector3(63.4, 0.0, 3.6), Vector3(65.0, 10.0, 3.8),
	Vector3(68.0, 20.0, 4.2), Vector3(71.0, 32.0, 4.6), Vector3(74.0, 42.0, 4.8), Vector3(73.6, 48.0, 5.4),
	Vector3(77.0, 56.0, 4.6), Vector3(85.0, 70.0, 5.0), Vector3(95.0, 84.0, 5.0), Vector3(108.0, 96.0, 4.8),
	Vector3(122.0, 104.0, 4.4), Vector3(136.0, 106.0, 4.0),
]
## Niveau de l'eau, profondeur au milieu du lit, et largeur des berges en pente douce.
const WATER_LEVEL := -1.1
const RIVER_DEPTH := 1.3
const BANK_WIDTH := 3.0
## Étang du jardin du roi : (x, z, rayon), son niveau et sa profondeur.
const PONDS: Array[Vector3] = [Vector3(47.4, -84.8, 3.2)]
const POND_LEVEL := -0.6
const POND_DEPTH := 0.7
## Berge de l'étang, plus courte que celle de la rivière : le jardin reste plat jusqu'à ses haies.
const POND_BANK := 1.5
## Ponts : (x, z, cap du tablier en degrés, longueur, largeur). Les berges y restent ouvertes, le tablier et ses
## parapets les relient. Mêmes valeurs dans tools/build_hub.py.
const BRIDGES := [[63.25, 0.0, 0.0, 15.5, 5.0], [63.0, -66.0, 0.0, 15.0, 3.0]]

const COLOR_GRASS := Color(0.3, 0.42, 0.18)
const COLOR_GRASS_DARK := Color(0.2, 0.3, 0.13)
const COLOR_PATH := Color(0.42, 0.33, 0.22)
const COLOR_GRAVEL := Color(0.6, 0.55, 0.45)
const COLOR_LAWN := Color(0.32, 0.47, 0.2)
const COLOR_HILL := Color(0.26, 0.33, 0.17)
const COLOR_ROCK := Color(0.4, 0.38, 0.36)
const COLOR_BANK := Color(0.37, 0.31, 0.21)
const COLOR_BED := Color(0.24, 0.21, 0.15)
## Sol sous les planchers des bâtiments : entre les lattes, on voit une terre sombre et non l'herbe.
const COLOR_FLOOR := Color(0.16, 0.11, 0.08)
## Emprise des maisons et des bâtiments (tools/build_hub.py : house_layout, LANDMARKS, QUARTERS).
const BUILDING_FLOORS: Array[Rect2] = [
	Rect2(-13.2, -26.2, 8, 8), Rect2(5.2, -26.2, 8, 8), Rect2(18.2, -13.2, 8, 8), Rect2(18.2, 5.2, 8, 8), Rect2(4.2, 18.6, 8, 8),
	Rect2(-12.2, 18.6, 8, 8), Rect2(-26.6, 4.2, 8, 8), Rect2(-26.6, -12.2, 8, 8), Rect2(-20.5, -39.1, 12, 8), Rect2(8.5, -39.1, 12, 8),
	Rect2(31.1, -18.5, 8, 8), Rect2(29.1, 10.5, 12, 8), Rect2(7.7, 32.1, 8, 8), Rect2(-15.7, 30.1, 8, 12), Rect2(-40.1, 7.7, 8, 8),
	Rect2(-40.1, -17.7, 8, 12), Rect2(-6, 56, 12, 8), Rect2(-66, -4, 12, 8), Rect2(-60, -36, 8, 12), Rect2(51, 14, 8, 8),
	Rect2(40, 60, 8, 8), Rect2(48, 30, 8, 8), Rect2(57, 44, 8, 8), Rect2(-74, -50, 12, 8), Rect2(-54, -70, 12, 8),
	Rect2(-64, 26, 8, 8), Rect2(-78, -20, 8, 8),
	# Salle de l'observatoire, tour tournée de 45 degrés : une croix sur les cinq sommets du terrain (tous les 2 m) qui
	# sont sous son plancher, jusqu'aux coins de la salle.
	Rect2(-72.3, 57.7, 4.6, 0.6), Rect2(-70.3, 55.7, 0.6, 4.6),
]

@export var ground_material: Material

var _relief := FastNoiseLite.new()
var _peaks := FastNoiseLite.new()
## Hauteurs aux sommets de la grille du maillage, pour retrouver la hauteur exacte du sol affiché.
var _heights := PackedFloat32Array()
## Distance de chaque sommet au bord de l'eau la plus proche : négative dans l'eau.
var _shore := PackedFloat32Array()

## Tracé de la rivière échantillonné tous les mètres et demi : (x, z, demi-largeur).
static var _river_samples := PackedVector3Array()


func _ready() -> void:
	_relief.seed = 5800
	_relief.frequency = 0.03
	_peaks.seed = 5801
	_peaks.frequency = 0.035
	_build()
	_build_limit()


## Distance de la limite au feu de camp dans la direction donnée (angle de atan2(z, x)).
static func limit_radius(angle: float) -> float:
	var steps := fposmod(rad_to_deg(angle) + 180.0, 360.0) / 30.0
	var index := int(steps) % EXTENT.size()
	var blend := (1.0 - cos((steps - floorf(steps)) * PI)) * 0.5
	return lerpf(EXTENT[index], EXTENT[(index + 1) % EXTENT.size()], blend)


## Rayon du plateau jouable, où les montagnes commencent à monter.
static func play_radius(angle: float) -> float:
	return limit_radius(angle) - BORDER_GAP


## Vrai si le point est dans la vallée, à margin près de la limite.
static func inside_limit(point: Vector2, margin := 0.0) -> bool:
	return point.length() < limit_radius(point.angle()) - margin


## Tracé de la rivière, lissé : un point tous les mètres et demi environ, avec la demi-largeur de l'eau.
static func river_samples() -> PackedVector3Array:
	if not _river_samples.is_empty():
		return _river_samples
	var samples := PackedVector3Array()
	for index in RIVER.size() - 1:
		var p0 := RIVER[maxi(index - 1, 0)]
		var p1 := RIVER[index]
		var p2 := RIVER[index + 1]
		var p3 := RIVER[mini(index + 2, RIVER.size() - 1)]
		var steps := maxi(int(Vector2(p2.x - p1.x, p2.y - p1.y).length() / 1.5), 1)
		for step in steps:
			var t := float(step) / steps
			var point := Vector2(p1.x, p1.y).bezier_interpolate(
				Vector2(p1.x, p1.y) + (Vector2(p2.x, p2.y) - Vector2(p0.x, p0.y)) / 6.0,
				Vector2(p2.x, p2.y) - (Vector2(p3.x, p3.y) - Vector2(p1.x, p1.y)) / 6.0,
				Vector2(p2.x, p2.y), t)
			samples.append(Vector3(point.x, point.y, lerpf(p1.z, p2.z, t)))
	var last := RIVER[RIVER.size() - 1]
	samples.append(last)
	_river_samples = samples
	return samples


## Rectangle d'un pont dans son repère : centre, direction du tablier, demi-longueur et demi-largeur.
static func bridge_contains(bridge: Array, point: Vector2, margin := 0.0) -> bool:
	var axis := Vector2.from_angle(-deg_to_rad(bridge[2]))
	var offset := point - Vector2(bridge[0], bridge[1])
	return absf(offset.dot(axis)) <= bridge[3] * 0.5 + margin and absf(offset.dot(axis.orthogonal())) <= bridge[4] * 0.5 + margin


## Hauteur du relief, continue, sans la rivière ; le sol affiché la suit par triangles, voir surface_height.
func height_at(x: float, z: float) -> float:
	var height := (_relief.get_noise_2d(x, z) * 0.5 + 0.5) * 1.6
	height *= 1.0 - flat_mask(x, z)
	var point := Vector2(x, z)
	var play := play_radius(point.angle())
	var rise := smoothstep(play, play + BORDER_WIDTH, point.length())
	return height + BORDER_HEIGHT * rise * rise * (0.65 + 0.7 * (_peaks.get_noise_2d(x, z) * 0.5 + 0.5))


## Hauteur du sol tel qu'il est maillé, à la même interpolation que ses triangles : c'est sur elle
## que le décor se pose, sans flotter au-dessus d'une pente.
func surface_height(x: float, z: float) -> float:
	if _heights.is_empty():
		return height_at(x, z)
	return _sample(_heights, x, z)


## Pente du sol affiché au point donné : 0 à plat, 1 pour 45 degrés.
func slope_at(x: float, z: float) -> float:
	if _heights.is_empty():
		return 0.0
	var dx := _sample(_heights, x + 0.5, z) - _sample(_heights, x - 0.5, z)
	var dz := _sample(_heights, x, z + 0.5) - _sample(_heights, x, z - 0.5)
	return Vector2(dx, dz).length()


## Distance au bord de l'eau (rivière ou étang) : négative dans l'eau, grande loin de toute eau.
func shore_distance(x: float, z: float) -> float:
	if _shore.is_empty():
		return 1000.0
	return _sample(_shore, x, z)


## Valeur d'un champ porté par les sommets de la grille, interpolée comme les triangles du maillage.
func _sample(field: PackedFloat32Array, x: float, z: float) -> float:
	var gx := clampf((x - GRID_ORIGIN.x) / CELL_SIZE, 0.0, COLUMNS - 0.001)
	var gz := clampf((z - GRID_ORIGIN.y) / CELL_SIZE, 0.0, ROWS - 0.001)
	var column := int(gx)
	var row := int(gz)
	var u := gx - column
	var v := gz - row
	var first := row * (COLUMNS + 1) + column
	var h0 := field[first]
	var h1 := field[first + 1]
	var h2 := field[first + COLUMNS + 1]
	var h3 := field[first + COLUMNS + 2]
	if u + v <= 1.0:
		return h0 + u * (h1 - h0) + v * (h2 - h0)
	return h3 + (1.0 - u) * (h2 - h3) + (1.0 - v) * (h1 - h3)


## Destinations reliées au feu de camp par un chemin.
static func destinations() -> Array:
	return PORTALS.values() + [CASTLE_GATE, BUNKER] + LANES


static var _segments: Array[PackedVector2Array] = []


## Tronçons des ruelles du village (ou des allées du jardin), à plat : chaque paire de points est un tronçon.
static func alley_segments(park := false) -> PackedVector2Array:
	if _segments.is_empty():
		for alleys: Array in [ALLEYS, PARK_ALLEYS]:
			var segments := PackedVector2Array()
			for alley: Array in alleys:
				for index in alley.size() - 1:
					segments.append(alley[index])
					segments.append(alley[index + 1])
			_segments.append(segments)
	return _segments[1 if park else 0]


## Distance d'un point au rectangle de l'enceinte du château, nulle à l'intérieur.
static func castle_distance(point: Vector2) -> float:
	var closest := point.clamp(CASTLE_AREA.position, CASTLE_AREA.end)
	return point.distance_to(closest)


## Distance d'un point à la ruelle la plus proche, plafonnée à limit : les tronçons lointains sont écartés d'emblée.
static func alley_distance(point: Vector2, park := false, limit := 12.0) -> float:
	var best := limit
	var segments := alley_segments(park)
	for index in range(0, segments.size(), 2):
		var a := segments[index]
		var b := segments[index + 1]
		if point.x < minf(a.x, b.x) - best or point.x > maxf(a.x, b.x) + best \
				or point.y < minf(a.y, b.y) - best or point.y > maxf(a.y, b.y) + best:
			continue
		best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)))
	return best


## Vaut 1 sur le village, les chemins, les abords des portails, du château, du bunker et des lieux, où le sol reste plat.
func flat_mask(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var mask := 1.0 - smoothstep(VILLAGE_RADIUS, VILLAGE_RADIUS + 8.0, point.length())
	mask = maxf(mask, 1.0 - smoothstep(3.0, 10.0, castle_distance(point)))
	for landmark in LANDMARKS:
		mask = maxf(mask, 1.0 - smoothstep(landmark.z, landmark.z + 6.0, point.distance_to(Vector2(landmark.x, landmark.y))))
	for yard in YARDS:
		mask = maxf(mask, 1.0 - smoothstep(yard.z, yard.z + 6.0, point.distance_to(Vector2(yard.x, yard.y))))
	for target: Vector2 in destinations():
		mask = maxf(mask, 1.0 - smoothstep(5.0, 11.0, point.distance_to(target)))
		var along := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, target)
		mask = maxf(mask, 1.0 - smoothstep(PATH_HALF_WIDTH + 1.0, PATH_HALF_WIDTH + 5.0, point.distance_to(along)))
	if mask < 1.0:
		mask = maxf(mask, 1.0 - smoothstep(PATH_HALF_WIDTH + 1.0, PATH_HALF_WIDTH + 4.0, alley_distance(point, false, 6.0)))
	if mask < 1.0 and PARK_AREA.grow(4.0).has_point(point):
		mask = maxf(mask, 1.0 - smoothstep(0.0, 4.0, _rect_distance(PARK_AREA, point)))
	return mask


static func _rect_distance(rect: Rect2, point: Vector2) -> float:
	return point.distance_to(point.clamp(rect.position, rect.end))


## Vaut 1 sur les chemins de terre battue.
func path_mask(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var mask := 0.0
	var wobble := _relief.get_noise_2d(x * 4.0, z * 4.0) * 0.5
	for target: Vector2 in destinations():
		var along := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, target)
		mask = maxf(mask, 1.0 - smoothstep(PATH_HALF_WIDTH - 0.4, PATH_HALF_WIDTH + 0.4, point.distance_to(along) + wobble))
	mask = maxf(mask, 1.0 - smoothstep(PATH_HALF_WIDTH - 0.4, PATH_HALF_WIDTH + 0.4, absf(point.length() - RING_STREET) + wobble))
	mask = maxf(mask, 1.0 - smoothstep(4.5, 5.5, point.length()))
	mask = maxf(mask, 1.0 - smoothstep(1.0, 1.8, alley_distance(point, false, 3.0) + wobble))
	# Cour pavée du château.
	if CASTLE_AREA.has_point(point):
		mask = maxf(mask, 0.85)
	return mask


## Vaut 1 sur les allées gravillonnées du jardin.
func gravel_mask(x: float, z: float) -> float:
	var point := Vector2(x, z)
	if not PARK_AREA.grow(2.0).has_point(point):
		return 0.0
	var mask := 1.0 - smoothstep(0.9, 1.5, alley_distance(point, true, 2.0))
	var circle := absf(point.distance_to(Vector2(PARK_CIRCLE.x, PARK_CIRCLE.y)) - PARK_CIRCLE.z)
	return maxf(mask, 1.0 - smoothstep(0.9, 1.5, circle))


func _face_color(x: float, z: float, height: float, shore: float) -> Color:
	var point := Vector2(x, z)
	var color := COLOR_GRASS_DARK.lerp(COLOR_GRASS, _relief.get_noise_2d(z * 2.0, x * 2.0) * 0.5 + 0.5)
	if PARK_AREA.has_point(point):
		color = COLOR_LAWN.lerp(COLOR_GRASS, _relief.get_noise_2d(z * 3.0, x * 3.0) * 0.25 + 0.25)
		color = color.lerp(COLOR_GRAVEL, gravel_mask(x, z))
	color = color.lerp(COLOR_PATH, path_mask(x, z))
	# Terre sombre seulement sur les cases du maillage (2 m) entièrement sous un bâtiment, murs compris : une case
	# à cheval sur un mur gardait sa terre sombre au-dehors, en bande noire de 0,8 m le long de la façade.
	var cell := Rect2(point - Vector2.ONE * CELL_SIZE * 0.5, Vector2.ONE * CELL_SIZE)
	for floor_area in BUILDING_FLOORS:
		if floor_area.grow(0.3).encloses(cell):
			color = COLOR_FLOOR
			break
	var play := play_radius(point.angle())
	color = color.lerp(COLOR_HILL, smoothstep(play, play + 10.0, point.length()))
	# Roche nue en haut des montagnes.
	color = color.lerp(COLOR_ROCK, smoothstep(12.0, 24.0, height))
	# Berges de terre et lit de la rivière.
	color = color.lerp(COLOR_BANK, 1.0 - smoothstep(0.4, 2.4, shore))
	return color.lerp(COLOR_BED, 1.0 - smoothstep(-1.2, -0.2, shore))


## Creuse un lit dans le sol : le fond sous l'eau, puis une berge qui remonte jusqu'au sol naturel ; en
## montagne, la berge s'élargit en vallée.
static func carve(natural: float, distance: float, half_width: float, level: float, depth: float, bank_width := BANK_WIDTH) -> float:
	if distance < half_width:
		var t := distance / half_width
		return minf(natural, level - depth * (1.0 - t * t))
	var bank := bank_width + minf(0.6 * maxf(natural - 1.0, 0.0), 12.0)
	if distance < half_width + bank:
		return minf(natural, lerpf(level, natural, smoothstep(half_width, half_width + bank, distance)))
	return natural


func _build() -> void:
	var stride := COLUMNS + 1
	var heights := PackedFloat32Array()
	heights.resize(stride * (ROWS + 1))
	var shore := PackedFloat32Array()
	shore.resize(heights.size())
	shore.fill(1000.0)
	for row in ROWS + 1:
		for column in stride:
			heights[row * stride + column] = height_at(GRID_ORIGIN.x + column * CELL_SIZE, GRID_ORIGIN.y + row * CELL_SIZE)
	_carve_waters(heights, shore)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for array: Variant in [vertices, normals, colors]:
		array.resize(COLUMNS * ROWS * 6)
	var index := 0
	for row in ROWS:
		for column in COLUMNS:
			var x := GRID_ORIGIN.x + column * CELL_SIZE
			var z := GRID_ORIGIN.y + row * CELL_SIZE
			var first := row * stride + column
			var corners: Array[int] = [first, first + 1, first + stride, first + stride + 1]
			var points: Array[Vector3] = [
				Vector3(x, heights[first], z),
				Vector3(x + CELL_SIZE, heights[first + 1], z),
				Vector3(x, heights[first + stride], z + CELL_SIZE),
				Vector3(x + CELL_SIZE, heights[first + stride + 1], z + CELL_SIZE),
			]
			var average := 0.0
			var wet := 0.0
			for corner in corners:
				average += heights[corner] * 0.25
				wet += shore[corner] * 0.25
			var color := _face_color(x + CELL_SIZE * 0.5, z + CELL_SIZE * 0.5, average, wet)
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
	_shore = shore
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)


## Creuse la rivière et les étangs dans les hauteurs des sommets. Chaque tronçon ne mesure que les sommets
## de son voisinage, et chaque sommet n'est creusé qu'une fois, d'après l'eau la plus proche.
## Retient aussi la distance de chaque sommet au bord de l'eau.
func _carve_waters(heights: PackedFloat32Array, shore: PackedFloat32Array) -> void:
	var stride := COLUMNS + 1
	var nearest := PackedFloat32Array()
	nearest.resize(heights.size())
	nearest.fill(1000.0)
	var half_widths := PackedFloat32Array()
	half_widths.resize(heights.size())
	var ponds := PackedByteArray()
	ponds.resize(heights.size())
	var samples := river_samples()
	for index in samples.size() - 1:
		var a := Vector2(samples[index].x, samples[index].y)
		var b := Vector2(samples[index + 1].x, samples[index + 1].y)
		# Portée du creusement : la berge s'élargit en montagne, où le sol naturel est haut.
		var middle := (a + b) * 0.5
		var play := play_radius(middle.angle())
		var rise := smoothstep(play, play + BORDER_WIDTH, middle.length() + 12.0)
		var reach := maxf(samples[index].z, samples[index + 1].z) + BANK_WIDTH + minf(0.6 * (1.6 + BORDER_HEIGHT * 1.4 * rise * rise), 12.0) + 2.0
		var area := Rect2(a, Vector2.ZERO).expand(b).grow(reach)
		var span := b - a
		var length_squared := maxf(span.length_squared(), 0.0001)
		for row in range(_row(area.position.y), _row(area.end.y) + 1):
			for column in range(_column(area.position.x), _column(area.end.x) + 1):
				var point := GRID_ORIGIN + Vector2(column, row) * CELL_SIZE
				var t := clampf((point - a).dot(span) / length_squared, 0.0, 1.0)
				var distance := point.distance_to(a + span * t)
				var vertex := row * stride + column
				if distance < nearest[vertex]:
					nearest[vertex] = distance
					half_widths[vertex] = lerpf(samples[index].z, samples[index + 1].z, t)
					ponds[vertex] = 0
	for pond in PONDS:
		var center := Vector2(pond.x, pond.y)
		var area := Rect2(center, Vector2.ZERO).grow(pond.z + POND_BANK + 2.0)
		for row in range(_row(area.position.y), _row(area.end.y) + 1):
			for column in range(_column(area.position.x), _column(area.end.x) + 1):
				var vertex := row * stride + column
				var distance := (GRID_ORIGIN + Vector2(column, row) * CELL_SIZE).distance_to(center)
				if distance - pond.z < nearest[vertex] - half_widths[vertex]:
					nearest[vertex] = distance
					half_widths[vertex] = pond.z
					ponds[vertex] = 1
	for vertex in heights.size():
		if nearest[vertex] >= 1000.0:
			continue
		var pond := ponds[vertex] == 1
		heights[vertex] = carve(heights[vertex], nearest[vertex], half_widths[vertex],
			POND_LEVEL if pond else WATER_LEVEL, POND_DEPTH if pond else RIVER_DEPTH, POND_BANK if pond else BANK_WIDTH)
		shore[vertex] = nearest[vertex] - half_widths[vertex]


func _column(x: float) -> int:
	return clampi(int(roundf((x - GRID_ORIGIN.x) / CELL_SIZE)), 0, COLUMNS)


func _row(z: float) -> int:
	return clampi(int(roundf((z - GRID_ORIGIN.y) / CELL_SIZE)), 0, ROWS)


## Mur invisible au pied des montagnes, sur tout le tour de la vallée : le joueur ne peut pas les gravir
## jusqu'au bord du monde.
func _build_limit() -> void:
	var segments := 96
	for index in segments:
		var angle_a := TAU * index / segments
		var angle_b := TAU * (index + 1) / segments
		var a := Vector2.from_angle(angle_a) * limit_radius(angle_a)
		var b := Vector2.from_angle(angle_b) * limit_radius(angle_b)
		var shape := BoxShape3D.new()
		shape.size = Vector3(a.distance_to(b) + 0.6, 40.0, 1.0)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var middle := (a + b) * 0.5
		collision.position = Vector3(middle.x, 15.0, middle.y)
		collision.rotation.y = -(b - a).angle()
		add_child(collision)
