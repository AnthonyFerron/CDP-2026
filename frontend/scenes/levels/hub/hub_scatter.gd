@tool
class_name HubScatter
extends Node3D
## Habille le hub : arbres, buissons, rochers, et des fleurs dont le nombre suit les livres rapportés.
## Les placements sont reproductibles, posés sur le sol tel qu'il est maillé, et les petits détails
## disparaissent au loin.

@export var terrain: HubTerrain
@export var tree_models: Array[PackedScene]
@export var bush_models: Array[PackedScene]
@export var rock_models: Array[PackedScene]
@export var flower_models: Array[PackedScene]
## Rayon du tronc de chaque arbre, et de chaque rocher, à l'échelle 1 : leur collision.
@export var tree_radii: Array[float] = [0.07, 0.07, 0.08, 0.06, 0.06]
@export var rock_radii: Array[float] = [0.34, 0.52]
@export var tree_count := 240
@export var forest_tree_count := 420
@export var bush_count := 380
@export var rock_count := 110
@export var flower_count := 1500
@export var detail_range := 70.0
## Côté des cases de la grille qui découpe les petits détails : chaque case a son propre MultiMesh, et sa propre
## distance de visibilité, mesurée jusqu'à elle et non jusqu'au milieu de la carte.
@export var chunk_size := 32.0

var _rng := RandomNumberGenerator.new()
var _flowers: Array[MultiMesh] = []


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5800
	_scatter(tree_models, tree_count, Vector2(4.0, 5.4), tree_radii, 0.45, 0.12)
	_add_forest()
	_scatter(bush_models, bush_count, Vector2(3.0, 5.0), [], 0.7, 0.05)
	_scatter(rock_models, rock_count, Vector2(2.0, 4.0), rock_radii, 0.7, 0.1)
	_flowers = _scatter(flower_models, flower_count, Vector2(2.0, 3.0), [], 0.6, 0.0)
	set_life(0.0)


## Affiche une part des fleurs, de 0 (aucune) à 1 (toutes).
func set_life(life: float) -> void:
	for multimesh in _flowers:
		multimesh.visible_instance_count = int(multimesh.instance_count * clampf(life, 0.0, 1.0))


func _is_free(spot: Vector2, margin: float) -> bool:
	if not HubTerrain.inside_limit(spot, 2.0) or terrain.flat_mask(spot.x, spot.y) > 0.2:
		return false
	if HubTerrain.castle_distance(spot) < 6.0 + margin or spot.distance_to(HubTerrain.BUNKER) < 14.0:
		return false
	# Ni dans la rivière ni sur ses berges, ni dans le jardin du roi, dont les arbres sont plantés en allées.
	if terrain.shore_distance(spot.x, spot.y) < 3.5 + margin or HubTerrain.PARK_AREA.grow(3.0 + margin).has_point(spot):
		return false
	for bridge: Array in HubTerrain.BRIDGES:
		if HubTerrain.bridge_contains(bridge, spot, 3.0 + margin):
			return false
	if HubTerrain.alley_distance(spot, false, 4.0) < 3.0 + margin:
		return false
	for target: Vector2 in HubTerrain.destinations():
		if spot.distance_to(target) < 6.0 + margin:
			return false
	for landmark in HubTerrain.LANDMARKS:
		if spot.distance_to(Vector2(landmark.x, landmark.y)) < landmark.z + margin:
			return false
	return true


## Disperse des modèles sur le plateau. Un rayon par modèle leur donne une collision à leur taille ;
## sans rayon, ils se traversent. Les pentes trop fortes sont évitées, et chaque pied s'enfonce un peu
## pour ne jamais flotter.
func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, radii: Array, max_slope: float, sink: float) -> Array[MultiMesh]:
	var body: StaticBody3D
	if not radii.is_empty():
		body = StaticBody3D.new()
		add_child(body)
	var groups: Array[Array] = []
	# Hauteur de chaque modèle : la collision d'un rocher s'arrête à son sommet (celle d'un arbre, à 3 m).
	var heights: Array[float] = []
	for model in models:
		groups.append([])
		heights.append(_load_mesh(model).get_aabb().size.y if body else 0.0)
	var placed := 0
	for attempt in count * 12:
		if placed >= count:
			break
		var angle := _rng.randf() * TAU
		var spot := Vector2.from_angle(angle) * sqrt(_rng.randf()) * HubTerrain.limit_radius(angle)
		if not _is_free(spot, 1.0):
			continue
		var slope := terrain.slope_at(spot.x, spot.y)
		if slope > max_slope:
			continue
		var model := placed % groups.size()
		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)
		var ground := terrain.surface_height(spot.x, spot.y)
		var origin := Vector3(spot.x, ground - sink * scale_factor - slope * 0.6, spot.y)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
		groups[model].append(Transform3D(basis, origin))
		if body:
			var shape := CylinderShape3D.new()
			shape.radius = float(radii[model % radii.size()]) * scale_factor
			shape.height = clampf(heights[model] * scale_factor, 0.6, 3.0)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = Vector3(spot.x, ground + shape.height * 0.5, spot.y)
			body.add_child(collision)
		placed += 1
	var multimeshes: Array[MultiMesh] = []
	for index in models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		multimeshes.append_array(_add_multimeshes(_load_mesh(models[index]), transforms, body != null))
	return multimeshes


## Forêt sur les pentes des montagnes, au-delà de la limite du joueur : elle ferme l'horizon.
func _add_forest() -> void:
	var groups: Array[Array] = []
	for model in tree_models:
		groups.append([])
	var placed := 0
	for attempt in forest_tree_count * 6:
		if placed >= forest_tree_count:
			break
		var angle := _rng.randf() * TAU
		var spot := Vector2.from_angle(angle) * _rng.randf_range(HubTerrain.limit_radius(angle) + 1.0, HubTerrain.play_radius(angle) + 24.0)
		if terrain.slope_at(spot.x, spot.y) > 1.0 or terrain.shore_distance(spot.x, spot.y) < 2.5:
			continue
		var scale_factor := _rng.randf_range(4.5, 6.5)
		var ground := terrain.surface_height(spot.x, spot.y) - 0.2 * scale_factor
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
		groups[placed % groups.size()].append(Transform3D(basis, Vector3(spot.x, ground, spot.y)))
		placed += 1
	for index in tree_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(_load_mesh(tree_models[index]), transforms, true)


## Place les instances d'un modèle : d'un seul MultiMesh s'il reste toujours visible (arbres, rochers), sinon par
## cases de chunk_size mètres, chacune effacée au loin selon sa propre distance à la caméra. Renvoie les MultiMesh.
func _add_multimeshes(mesh: Mesh, transforms: Array[Transform3D], always_visible: bool) -> Array[MultiMesh]:
	var result: Array[MultiMesh] = []
	if always_visible:
		result.append(_add_multimesh(mesh, transforms, true).multimesh)
		return result
	var cells := {}
	for transform in transforms:
		var cell := Vector2i(floori(transform.origin.x / chunk_size), floori(transform.origin.z / chunk_size))
		if not cells.has(cell):
			var list: Array[Transform3D] = []
			cells[cell] = list
		cells[cell].append(transform)
	for cell: Vector2i in cells:
		result.append(_add_multimesh(mesh, cells[cell], false).multimesh)
	return result


func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], always_visible: bool) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	if not always_visible:
		instance.visibility_range_end = detail_range
		instance.visibility_range_end_margin = 10.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance


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
