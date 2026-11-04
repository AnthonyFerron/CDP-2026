@tool
class_name VillageScatter
extends Node3D
## Habille le Village : herbe folle et gravats dans les rues, arbres, rochers et buissons autour du bourg.
## Les placements sont reproductibles et les petits détails disparaissent au loin.

@export var terrain: VillageTerrain
@export var grass_models: Array[PackedScene]
@export var rubble_models: Array[PackedScene]
@export var tree_models: Array[PackedScene]
@export var rock_models: Array[PackedScene]
@export var grass_count := 900
@export var rubble_count := 160
@export var tree_count := 70
@export var border_tree_count := 60
@export var rock_count := 40
@export var detail_range := 55.0

## Côté des cases de détails qui s'effacent au loin, et largeur du fondu, en mètres.
const CHUNK_SIZE := 32.0
const FADE_MARGIN := 6.0
## Ce que le joueur peut toucher d'un arbre ou d'un rocher : ses sommets entre ANKLE et TOUCH_HEIGHT, en mètres.
## Leur emprise devient une colonne de collision haute de SOLID_TOP, qu'on ne traverse pas et où l'on ne grimpe pas.
const ANKLE := 0.3
const TOUCH_HEIGHT := 2.2
const SOLID_TOP := 3.2

var _rng := RandomNumberGenerator.new()
var _vertices := {}


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5815
	_scatter(grass_models, grass_count, Vector2(2.5, 4.5), 0.0, false)
	# Sans collision, les gravats restent sous la cheville (0,3 m au plus) : on marche dessus sans les traverser.
	_scatter(rubble_models, rubble_count, Vector2(0.45, 0.6), 0.0, false)
	# Les arbres et les rochers ont la collision de ce qu'on en touche : le tronc, mais aussi les branches basses des
	# pins et le feuillage des arbres grêles, à hauteur de tête.
	_scatter(tree_models, tree_count, Vector2(3.5, 5.5), true, true)
	_scatter(rock_models, rock_count, Vector2(2.0, 4.0), true, true)
	_add_border_trees()


func _is_free(spot: Vector2, outside_town: bool) -> bool:
	if spot.length() > VillageTerrain.PLAY_RADIUS:
		return false
	if terrain.cobble_mask(spot.x, spot.y) > 0.15 or terrain.stream_mask(spot.x) > 0.1:
		return false
	if Vector2(spot.x - VillageTerrain.MILL_HILL.x, spot.y - VillageTerrain.MILL_HILL.y).length() < 4.0:
		return false
	if outside_town:
		var town_min := VillageTerrain.TOWN_MIN - Vector2(2.0, 2.0)
		var town_max := VillageTerrain.TOWN_MAX + Vector2(2.0, 10.0)
		if spot.x > town_min.x and spot.x < town_max.x and spot.y > town_min.y and spot.y < town_max.y:
			return false
	return true


## Disperse des modèles, avec ou sans collision.
func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, outside_town: bool) -> void:
	var body: StaticBody3D
	if solid:
		body = StaticBody3D.new()
		add_child(body)
	var meshes: Array[Mesh] = []
	var groups: Array[Array] = []
	for model in models:
		meshes.append(_load_mesh(model))
		groups.append([])
	var placed := 0
	for attempt in count * 12:
		if placed >= count:
			break
		var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * VillageTerrain.PLAY_RADIUS
		if not _is_free(spot, outside_town):
			continue
		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.05, spot.y)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
		groups[placed % groups.size()].append(Transform3D(basis, origin))
		if solid:
			_add_solid(body, meshes[placed % meshes.size()], Transform3D(basis, origin))
		placed += 1
	for index in models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(meshes[index], transforms, solid)


func _add_border_trees() -> void:
	# Le joueur peut gravir le talus : les arbres de la bordure ont aussi leur collision au tronc.
	var body := StaticBody3D.new()
	body.name = "BorderTrees"
	add_child(body)
	var meshes: Array[Mesh] = []
	var groups: Array[Array] = []
	for model in tree_models:
		meshes.append(_load_mesh(model))
		groups.append([])
	for i in border_tree_count:
		var angle := TAU * i / border_tree_count + _rng.randf_range(-0.05, 0.05)
		var spot := Vector2.from_angle(angle) * (VillageTerrain.PLAY_RADIUS + _rng.randf_range(1.0, 8.0))
		# Même ordre de tirage qu'avant : l'orientation, puis la taille.
		var yaw := _rng.randf() * TAU
		var scale_factor := _rng.randf_range(5.0, 7.0)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_factor)
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.1, spot.y)
		groups[i % groups.size()].append(Transform3D(basis, origin))
		_add_solid(body, meshes[i % meshes.size()], Transform3D(basis, origin))
	for index in tree_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(meshes[index], transforms, true)


## Collision d'un arbre ou d'un rocher posé par placement : l'emprise de ses sommets entre ANKLE et TOUCH_HEIGHT,
## dressée en colonne jusqu'à SOLID_TOP. Un cylindre au tronc laissait entrer dans les branches basses des pins, qui
## tombent jusqu'au sol, et dans le feuillage des arbres grêles ; plus large, il aurait fait des murs invisibles.
func _add_solid(body: StaticBody3D, mesh: Mesh, placement: Transform3D) -> void:
	if not _vertices.has(mesh):
		var all := PackedVector3Array()
		for surface in mesh.get_surface_count():
			all.append_array(mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
		_vertices[mesh] = all
	var points := PackedVector3Array()
	for vertex: Vector3 in _vertices[mesh]:
		var point := placement.basis * vertex
		# Sous la cheville, les bords plats des rochers s'enjambent comme les gravats.
		if point.y >= ANKLE and point.y < TOUCH_HEIGHT:
			points.append(Vector3(point.x, -0.5, point.z))
			points.append(Vector3(point.x, SOLID_TOP, point.z))
	if points.size() < 8:
		return
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = placement.origin
	body.add_child(collision)


## Pose des copies d'un maillage. Les détails qui s'effacent au loin sont découpés en cases de CHUNK_SIZE mètres :
## Godot mesure la distance d'effacement jusqu'au centre de chaque MultiMesh, et un seul MultiMesh pour toute la
## carte s'effacerait d'un coup, même sous les pieds du joueur, dès qu'il s'éloigne du centre.
func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], always_visible: bool) -> void:
	if always_visible:
		_add_chunk(mesh, transforms, false)
		return
	var chunks := {}
	for transform in transforms:
		var key := Vector2i(floori(transform.origin.x / CHUNK_SIZE), floori(transform.origin.z / CHUNK_SIZE))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(transform)
	for key: Vector2i in chunks:
		var chunk: Array[Transform3D] = []
		chunk.assign(chunks[key])
		_add_chunk(mesh, chunk, true)


func _add_chunk(mesh: Mesh, transforms: Array[Transform3D], fades: bool) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	if fades:
		instance.visibility_range_end = detail_range
		instance.visibility_range_end_margin = FADE_MARGIN
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)


func _load_mesh(model: PackedScene) -> Mesh:
	var scene := model.instantiate()
	var mesh := _find_mesh(scene)
	scene.free()
	return mesh


func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return node.mesh
	for child in node.get_children():
		var mesh := _find_mesh(child)
		if mesh:
			return mesh
	return null
