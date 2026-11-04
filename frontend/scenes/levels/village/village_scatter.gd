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

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5815
	_scatter(grass_models, grass_count, Vector2(2.5, 4.5), 0.0, false)
	_scatter(rubble_models, rubble_count, Vector2(1.5, 3.0), 0.0, false)
	# Collision au tronc des arbres et au corps des rochers, à l'échelle 1.
	_scatter(tree_models, tree_count, Vector2(3.5, 5.5), 0.08, true)
	_scatter(rock_models, rock_count, Vector2(2.0, 4.0), 0.4, true)
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


## Disperse des modèles ; un rayon non nul leur donne une collision de ce rayon, à l'échelle 1.
func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, radius: float, outside_town: bool) -> void:
	var solid := radius > 0.0
	var body: StaticBody3D
	if solid:
		body = StaticBody3D.new()
		add_child(body)
	var groups: Array[Array] = []
	for model in models:
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
			var shape := CylinderShape3D.new()
			shape.radius = radius * scale_factor
			shape.height = 3.0
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = origin + Vector3.UP * 1.5
			body.add_child(collision)
		placed += 1
	for index in models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(_load_mesh(models[index]), transforms, solid)


func _add_border_trees() -> void:
	# Le joueur peut gravir le talus : les arbres de la bordure ont aussi leur collision au tronc.
	var body := StaticBody3D.new()
	body.name = "BorderTrees"
	add_child(body)
	var groups: Array[Array] = []
	for model in tree_models:
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
		var shape := CylinderShape3D.new()
		shape.radius = 0.08 * scale_factor
		shape.height = 4.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = origin + Vector3.UP * 2.0
		body.add_child(collision)
	for index in tree_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(_load_mesh(tree_models[index]), transforms, true)


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
