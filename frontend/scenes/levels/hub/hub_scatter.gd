@tool
class_name HubScatter
extends Node3D
## Habille le hub : arbres, buissons, rochers, et des fleurs dont le nombre suit les livres rapportés.
## Les placements sont reproductibles et les petits détails disparaissent au loin.

@export var terrain: HubTerrain
@export var tree_models: Array[PackedScene]
@export var bush_models: Array[PackedScene]
@export var rock_models: Array[PackedScene]
@export var flower_models: Array[PackedScene]
@export var tree_count := 220
@export var border_tree_count := 130
@export var bush_count := 380
@export var rock_count := 110
@export var flower_count := 1500
@export var detail_range := 70.0

var _rng := RandomNumberGenerator.new()
var _flowers: Array[MultiMesh] = []


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5800
	_scatter(tree_models, tree_count, Vector2(3.2, 5.0), 0.5, true)
	_add_border_trees()
	_scatter(bush_models, bush_count, Vector2(3.0, 5.0), 0.2, false)
	_scatter(rock_models, rock_count, Vector2(2.0, 4.0), 0.4, true)
	_flowers = _scatter(flower_models, flower_count, Vector2(2.0, 3.0), 0.05, false)
	set_life(0.0)


## Affiche une part des fleurs, de 0 (aucune) à 1 (toutes).
func set_life(life: float) -> void:
	for multimesh in _flowers:
		multimesh.visible_instance_count = int(multimesh.instance_count * clampf(life, 0.0, 1.0))


func _is_free(spot: Vector2, margin: float) -> bool:
	if terrain.flat_mask(spot.x, spot.y) > 0.2 or spot.length() > HubTerrain.PLAY_RADIUS:
		return false
	if HubTerrain.castle_distance(spot) < 6.0 + margin or spot.distance_to(HubTerrain.BUNKER) < 14.0:
		return false
	for target: Vector2 in HubTerrain.destinations():
		if spot.distance_to(target) < 6.0 + margin:
			return false
	return true


func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, radius: float, solid: bool) -> Array[MultiMesh]:
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
		var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * HubTerrain.PLAY_RADIUS
		if not _is_free(spot, 1.0):
			continue
		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)
		var origin := Vector3(spot.x, terrain.height_at(spot.x, spot.y) - 0.05, spot.y)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
		groups[placed % groups.size()].append(Transform3D(basis, origin))
		if solid:
			var shape := CylinderShape3D.new()
			shape.radius = radius * scale_factor * 0.6
			shape.height = 3.0
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = origin + Vector3.UP * 1.5
			body.add_child(collision)
		placed += 1
	var multimeshes: Array[MultiMesh] = []
	for index in models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		multimeshes.append(_add_multimesh(_load_mesh(models[index]), transforms, solid).multimesh)
	return multimeshes


func _add_border_trees() -> void:
	var groups: Array[Array] = []
	for model in tree_models:
		groups.append([])
	for i in border_tree_count:
		var angle := TAU * i / border_tree_count + _rng.randf_range(-0.04, 0.04)
		var spot := Vector2.from_angle(angle) * (HubTerrain.PLAY_RADIUS + _rng.randf_range(1.0, 8.0))
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(4.5, 6.5))
		groups[i % groups.size()].append(Transform3D(basis, Vector3(spot.x, terrain.height_at(spot.x, spot.y) - 0.1, spot.y)))
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
