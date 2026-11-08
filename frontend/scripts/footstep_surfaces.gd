class_name FootstepSurfaces
extends RefCounted
## Sol sous les pas du joueur : du bois (planchers, ponts, pontons, estrades) ou de la pierre (château, crypte, cave,
## dallages, pavés), d'après des zones posées pour chaque lieu. Le joueur (Player) la demande à chaque pas, et non à
## chaque image : quelques dizaines de tests de boîtes et de disques, sans aucune requête physique. Hors des zones, le
## lieu garde ses propres pas (Player.footstep_sounds : herbe, cendre, sable, boue, éclaboussures).
##
## Les zones reprennent les constantes des lieux quand elles existent (HubTerrain, MaraisTerrain, VillageTerrain) ;
## sinon, les valeurs des générateurs (tools/build_<lieu>.py), citées à chaque zone. L'intérieur de chaque lieu,
## posé sous la carte (y = -40), a sa propre surface. Voir docs/sons.md.

const WOOD := &"wood"
const STONE := &"stone"
## Sous cette hauteur, le joueur est dans l'intérieur du lieu, posé sous la carte.
const INSIDE_BELOW := -20.0
## Côté d'une case des maisons et des salles (WALL_SCALE de tools/build_plaine.py).
const TILE := 4.0
## Maisons du Village : centre (x, z) et taille en cases, comme HOUSES de tools/build_village.py.
const VILLAGE_HOUSES: Array[Vector4] = [
	Vector4(-10, 30, 2, 2), Vector4(-10, 20, 2, 2), Vector4(10, 30, 2, 2), Vector4(10, 20, 2, 2),
	Vector4(-17, -6, 2, 3), Vector4(17, -6, 2, 3), Vector4(-20, 14, 2, 2), Vector4(-28, -2, 2, 2),
	Vector4(21, 12, 2, 2), Vector4(-12, -18, 2, 2), Vector4(12, -18, 2, 2), Vector4(-31, -14, 2, 2),
]

## Surface de tout l'intérieur, si aucune zone ne la précise.
var inside := &""
var zones: Array[Zone] = []


## Surfaces du lieu dont level est la scène principale, ou null si le lieu n'en a pas (menus, scènes de test).
static func for_level(level: Node) -> FootstepSurfaces:
	if not level:
		return null
	return for_scene(level.scene_file_path)


static func for_scene(path: String) -> FootstepSurfaces:
	var surfaces := FootstepSurfaces.new()
	match path.get_file().get_basename():
		"hub":
			surfaces._hub()
		"plaine":
			surfaces._plaine()
		"desert":
			surfaces._desert()
		"marais":
			surfaces._marais()
		"village":
			surfaces._village()
		_:
			return null
	return surfaces


## Surface sous des pieds posés en point (position du joueur), ou &"" pour le sol propre au lieu. books : livres
## posés au hub, pour les ouvrages reconstruits d'un autre matériau.
func at(point: Vector3, books := 0) -> StringName:
	for zone in zones:
		if zone.has(point, books):
			return zone.surface
	return inside if point.y < INSIDE_BELOW else &""


## Hub : l'abri du bunker, les planchers des maisons, les ponts, le château, le lavoir et le kiosque du jardin.
func _hub() -> void:
	# Abri des survivants, sous le bunker : plancher de planches (tools/build_hub.py : build_shelter).
	inside = WOOD
	# Grand pont du chemin du bunker : planches jetées sur les piles effondrées, puis pont de pierre au premier livre
	# (build_bridges). Passerelle de bois du jardin du roi, en ruine ou reconstruite.
	var great: Array = HubTerrain.BRIDGES[0]
	zones.append(Zone.box(WOOD, great[0], great[1], great[3] + 0.6, great[4], -1.5, 2.5, great[2]).before_books(1))
	zones.append(Zone.box(STONE, great[0], great[1], great[3] + 0.6, great[4], -1.5, 2.5, great[2]).after_books(1))
	var footbridge: Array = HubTerrain.BRIDGES[1]
	zones.append(Zone.box(WOOD, footbridge[0], footbridge[1], footbridge[3] + 0.6, footbridge[4], -1.5, 2.5, footbridge[2]))
	# Estrade de pierre du kiosque à musique (build_park), dallage du lavoir (build_lavoir).
	zones.append(Zone.box(STONE, 36.0, -82.0, 5.0, 4.4, -0.5, 1.5))
	zones.append(Zone.box(STONE, 54.0, 6.5, 2.0 * TILE, TILE, -0.5, 1.5))
	# Salle des veilleurs de l'observatoire, tour tournée de 45 degrés (build_observatory : OBSERVATORY, TOWER_YAW).
	zones.append(Zone.box(WOOD, -70.0, 58.0, 2.0 * 0.465 * 4.6, 2.0 * 0.465 * 4.6, -1.0, 9.0, 45.0))
	# Planchers de toutes les maisons et de tous les bâtiments, rez-de-chaussée et étage (house_floor).
	for floor_area in HubTerrain.BUILDING_FLOORS:
		zones.append(Zone.rect(WOOD, floor_area, -1.0, 9.0))
	# Cour pavée du château, donjon et salle du trône dallés (hub_terrain.gd : path_mask, build_castle).
	zones.append(Zone.rect(STONE, HubTerrain.CASTLE_AREA, -1.0, 30.0))


## Plaine : le pont de pierre sur la coulée de lave, et la bibliothèque souterraine.
func _plaine() -> void:
	# Archives, escalier oublié et salle du livre : dallage de pierre (library_floor.gdshader, build_interior, passage).
	inside = STONE
	# Pont de trois travées de 4,16 m, centré en x = 0 et z = 29,5 (tools/build_plaine.py : bridge, BRIDGE_Z).
	zones.append(Zone.box(STONE, 0.0, 29.5, 4.0, 3.0 * 1.04 * 4.0, -1.5, 2.5))


## Désert : la salle des colonnes dallée, la citerne et la cave des archives.
func _desert() -> void:
	# Cave des archives, taillée dans la pierre (tools/build_desert.py : build_cellar).
	inside = STONE
	# Dallage de la salle des colonnes : cases de 4 m de x = -10 à 10 et de z = -16 à 4 (build_monument).
	zones.append(Zone.box(STONE, 0.0, -6.0, 5.0 * TILE, 5.0 * TILE, -1.0, 3.0))
	# Citerne (CISTERN_RECT, -33,75 à -26,25 en x, -5 à 0 en z) : l'escalier de pierre contre le mur sud, du fond
	# jusqu'au palier (cistern_stairs), puis la margelle de 1,25 m qui en fait le tour, à 1 m du sol.
	zones.append(Zone.box(STONE, -30.1, -4.475, 3.5, 1.05, -2.0, 1.6))
	zones.append(Zone.box(STONE, -30.0, -2.5, 7.5 + 2.5, 5.0 + 2.5, 0.8, 2.5))


## Marais : les pontons et le débarcadère, les dalles du cimetière, de la chapelle et du chemin de la crypte, et la
## crypte.
func _marais() -> void:
	# Long escalier, salle du mécanisme, tombeaux et couloirs : pierre (tools/build_marais.py : build_crypt_underground).
	inside = STONE
	# Pontons de planches, au-dessus de l'eau (marais_scatter.gd : PLANK_WIDTH de 2,4 m), et l'ancien débarcadère de
	# l'arrivée, de 2 m de large (build_arrival). Dans l'eau, sous leur tablier, les pas restent des éclaboussures.
	for walk in MaraisTerrain.BOARDWALKS:
		zones.append(Zone.lane(WOOD, Vector2(walk.x, walk.y), Vector2(walk.z, walk.w), 1.2, -0.1, 1.5))
	zones.append(Zone.lane(WOOD, Vector2(7.6, 53.2), Vector2(14.2, 51.2), 1.0, -0.1, 1.5))
	# Allée dallée du cimetière, de la grille à la tombe du gardien (build_cemetery), et chemin de dalles du ponton à
	# la porte de la crypte (build_crypt).
	zones.append(Zone.lane(STONE, Vector2(8.8, 1.6), Vector2(20.4, 1.6), 0.75, -0.1, 1.5))
	zones.append(Zone.lane(STONE, Vector2(2.6, -29.4), Vector2(0.2, -34.8), 0.75, -0.1, 1.5))
	# Nef de la chapelle en ruine, de -39,8 à -32,2 en x et de -5,8 à -2,2 en z, entre ses dalles (build_chapel).
	zones.append(Zone.box(STONE, -36.0, -4.0, 7.6, 3.6, -0.1, 1.5))


## Village : les planchers des maisons, le pont du ruisseau, les rues pavées, la mairie et sa salle secrète.
func _village() -> void:
	# Mairie, sous la carte : planchers de bois de l'accueil et du bureau, escalier de bois (write_village_tscn.py).
	inside = WOOD
	# Salle secrète, derrière la bibliothèque du bureau : dalle de pierre (SecretFloor, de -16,3 à -8 en x, de -4,3 à
	# 4,3 en z, au niveau du bureau, à 4,5 m au-dessus du rez-de-chaussée).
	zones.append(Zone.box(STONE, -12.15, 0.0, 8.3, 8.6, -40.0 + 3.5, -40.0 + 7.0))
	# Pont de bois en travers du ruisseau, avec ses rampes jusqu'à la rue (tools/build_village.py : build_mills).
	zones.append(Zone.box(WOOD, -38.0, 6.0, 8.0, 5.2, -1.5, 1.5))
	for house in VILLAGE_HOUSES:
		zones.append(Zone.box(WOOD, house.x, house.y, house.z * TILE, house.w * TILE, -1.0, 9.0))
	# Pavés de la place, de la grande rue et de la rue du pont (village_terrain.gd : cobble_mask).
	var square := VillageTerrain.SQUARE
	zones.append(Zone.disc(STONE, square.x, square.y, square.z, -1.0, 2.0))
	var half := VillageTerrain.MAIN_STREET_HALF_WIDTH
	zones.append(Zone.box(STONE, 0.0, 20.5, 2.0 * half, 81.0, -1.0, 2.0))
	zones.append(Zone.box(STONE, -22.0, VillageTerrain.WEST_STREET_Z, 40.0, 4.2, -1.0, 2.0))


## Zone au sol : une boîte tournée, un disque ou une bande le long d'un segment, entre deux hauteurs des pieds.
class Zone:
	var surface: StringName
	var center := Vector2.ZERO
	## Demi-côtés de la boîte, dans son repère.
	var half := Vector2.ZERO
	var cos_yaw := 1.0
	var sin_yaw := 0.0
	## Rayon du disque, ou demi-largeur de la bande ; 0 pour une boîte.
	var radius := 0.0
	## Bout de la bande, depuis center ; nul pour un disque.
	var segment := Vector2.ZERO
	var low := -INF
	var high := INF
	## La zone ne vaut qu'entre ces nombres de livres posés au hub (from inclus, until exclu).
	var from_books := 0
	var until_books := 1 << 30

	static func box(kind: StringName, x: float, z: float, width: float, depth: float, bottom: float, top: float,
			degrees := 0.0) -> Zone:
		var zone := Zone.new()
		zone.surface = kind
		zone.center = Vector2(x, z)
		zone.half = Vector2(width, depth) * 0.5
		zone.cos_yaw = cos(deg_to_rad(degrees))
		zone.sin_yaw = sin(deg_to_rad(degrees))
		zone.low = bottom
		zone.high = top
		return zone

	static func rect(kind: StringName, area: Rect2, bottom: float, top: float) -> Zone:
		var middle := area.get_center()
		return box(kind, middle.x, middle.y, area.size.x, area.size.y, bottom, top)

	static func disc(kind: StringName, x: float, z: float, size: float, bottom: float, top: float) -> Zone:
		var zone := box(kind, x, z, 0.0, 0.0, bottom, top)
		zone.radius = size
		return zone

	static func lane(kind: StringName, from: Vector2, to: Vector2, half_width: float, bottom: float, top: float) -> Zone:
		var zone := disc(kind, from.x, from.y, half_width, bottom, top)
		zone.segment = to - from
		return zone

	func before_books(count: int) -> Zone:
		until_books = count
		return self

	func after_books(count: int) -> Zone:
		from_books = count
		return self

	func has(point: Vector3, books: int) -> bool:
		if point.y < low or point.y > high or books < from_books or books >= until_books:
			return false
		var offset := Vector2(point.x, point.z) - center
		if radius > 0.0:
			if segment != Vector2.ZERO:
				offset -= segment * clampf(offset.dot(segment) / segment.length_squared(), 0.0, 1.0)
			return offset.length_squared() <= radius * radius
		# Dans le repère de la boîte, tournée de son cap autour de l'axe vertical (comme Basis(Vector3.UP, cap)).
		var along := offset.x * cos_yaw - offset.y * sin_yaw
		var across := offset.x * sin_yaw + offset.y * cos_yaw
		return absf(along) <= half.x and absf(across) <= half.y
