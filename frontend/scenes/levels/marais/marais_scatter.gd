@tool
class_name MaraisScatter
extends Node3D
## Habille le Marais : pontons, arbres, roseaux, nénuphars, buissons, champignons et troncs noyés.
## Les placements sont reproductibles et les petits détails disparaissent au loin.

## Zones gardées libres autour des lieux du parcours : position (x, z) et rayon.
const RESERVED: Array[Vector3] = [
	Vector3(0.0, 58.0, 7.0),
	Vector3(-20.0, 22.0, 6.5),
	Vector3(16.0, 0.0, 11.5),
	Vector3(0.0, -35.0, 10.0),
]
const PLANK_WIDTH := 2.4
const PLANK_STEP := 1.2

@export var terrain: MaraisTerrain
@export var tree_models: Array[PackedScene]
@export var reed_model: PackedScene
@export var lily_models: Array[PackedScene]
@export var bush_model: PackedScene
@export var mushroom_model: PackedScene
@export var log_model: PackedScene
@export var plank_model: PackedScene
@export var post_model: PackedScene
@export var island_tree_count := 70
@export var bank_tree_count := 60
@export var reed_count := 520
@export var lily_count := 260
@export var bush_count := 160
@export var mushroom_count := 70
@export var log_count := 14
## Distance à laquelle les petits détails disparaissent.
@export var detail_range := 55.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 4040
	_build_boardwalks()
	_scatter_trees()
	_scatter_by_height(reed_model, reed_count, -0.9, 0.05, Vector2(2.0, 3.2), 0.0, _flat_material(Color(0.2, 0.26, 0.1)))
	_scatter_lilies()
	_scatter_by_height(bush_model, bush_count, 0.25, 1.0, Vector2(3.0, 5.0), 0.0)
	_scatter_by_height(mushroom_model, mushroom_count, 0.25, 1.0, Vector2(2.5, 4.0), 0.0)
	_scatter_logs()


## Distance au ponton le plus proche, à plat.
func distance_to_boardwalk(point: Vector2) -> float:
	var nearest := INF
	for walk in MaraisTerrain.BOARDWALKS:
		var start := Vector2(walk.x, walk.y)
		var end := Vector2(walk.z, walk.w)
		nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, end)))
	return nearest


func _build_boardwalks() -> void:
	var body := StaticBody3D.new()
	body.name = "Boardwalks"
	add_child(body)
	var wood := _flat_material(Color(0.3, 0.2, 0.12))
	for walk in MaraisTerrain.BOARDWALKS:
		var start := Vector3(walk.x, 0.0, walk.y)
		var end := Vector3(walk.z, 0.0, walk.w)
		var direction := (end - start).normalized()
		var length := start.distance_to(end)
		var yaw := atan2(direction.x, direction.z)
		var across := direction.cross(Vector3.UP)
		var count := int(length / PLANK_STEP) + 1
		for i in count:
			var plank: Node3D = plank_model.instantiate()
			plank.position = start + direction * (i * PLANK_STEP) + Vector3.UP * (MaraisTerrain.DECK_HEIGHT - 0.1)
			plank.position.y += _rng.randf_range(-0.03, 0.03)
			plank.rotation.y = yaw + PI * 0.5 + deg_to_rad(_rng.randf_range(-3.0, 3.0))
			plank.scale = Vector3.ONE * PLANK_WIDTH
			body.add_child(plank)
			for mesh: MeshInstance3D in plank.find_children("*", "MeshInstance3D", true, false):
				mesh.material_override = wood
			if i % 3 == 0:
				for side in [-1.0, 1.0]:
					var post: Node3D = post_model.instantiate()
					post.position = plank.position + across * side * (PLANK_WIDTH * 0.5 - 0.1)
					post.position.y = MaraisTerrain.BED_HEIGHT - 0.2
					post.scale = Vector3(0.45, 2.1, 0.45)
					body.add_child(post)
		var shape := BoxShape3D.new()
		shape.size = Vector3(PLANK_WIDTH, 0.3, length + PLANK_STEP)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = Transform3D(
			Basis(Vector3.UP, yaw), (start + end) * 0.5 + Vector3.UP * (MaraisTerrain.DECK_HEIGHT - 0.15)
		)
		body.add_child(collision)


func _scatter_trees() -> void:
	var body := StaticBody3D.new()
	body.name = "Trees"
	add_child(body)
	var groups: Array[Array] = []
	for model in tree_models:
		groups.append([])
	var placed := 0
	for attempt in island_tree_count * 20:
		if placed >= island_tree_count:
			break
		var spot := _random_spot(MaraisTerrain.PLAY_RADIUS)
		if terrain.height_at(spot.x, spot.y) < 0.2 or _is_reserved(spot, 2.0):
			continue
		var item := _ground_transform(spot, _rng.randf_range(3.2, 4.8))
		groups[placed % groups.size()].append(item)
		var shape := CylinderShape3D.new()
		shape.radius = 0.45
		shape.height = 4.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = item.origin + Vector3.UP * 2.0
		body.add_child(collision)
		placed += 1
	# Le joueur peut gravir la berge : ses arbres ont aussi leur collision au tronc.
	for i in bank_tree_count:
		var angle := TAU * i / bank_tree_count + _rng.randf_range(-0.05, 0.05)
		var spot := Vector2.from_angle(angle) * (MaraisTerrain.PLAY_RADIUS + _rng.randf_range(3.0, 9.0))
		var item := _ground_transform(spot, _rng.randf_range(4.5, 6.5))
		groups[i % groups.size()].append(item)
		var shape := CylinderShape3D.new()
		shape.radius = 0.5
		shape.height = 4.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = item.origin + Vector3.UP * 2.0
		body.add_child(collision)
	for index in tree_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		var mesh := _load_mesh(tree_models[index])
		var instance := _add_multimesh(mesh, transforms)
		instance.visibility_range_end = 0.0


func _scatter_by_height(
	model: PackedScene, count: int, low: float, high: float, scale_range: Vector2, sink: float, material: Material = null
) -> void:
	var items: Array[Transform3D] = []
	for attempt in count * 6:
		if items.size() >= count:
			break
		var spot := _random_spot(MaraisTerrain.PLAY_RADIUS)
		var height := terrain.height_at(spot.x, spot.y)
		if height < low or height > high or _is_reserved(spot, 0.5) or distance_to_boardwalk(spot) < 1.8:
			continue
		var item := _ground_transform(spot, _rng.randf_range(scale_range.x, scale_range.y))
		item.origin.y -= sink
		items.append(item)
	var instance := _add_multimesh(_load_mesh(model), items)
	instance.material_override = material


func _scatter_lilies() -> void:
	var per_model := lily_count / lily_models.size()
	for model in lily_models:
		var items: Array[Transform3D] = []
		for attempt in per_model * 6:
			if items.size() >= per_model:
				break
			var spot := _random_spot(MaraisTerrain.PLAY_RADIUS)
			if terrain.height_at(spot.x, spot.y) > -0.5 or distance_to_boardwalk(spot) < 1.5:
				continue
			var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(3.0, 5.0))
			items.append(Transform3D(basis, Vector3(spot.x, MaraisTerrain.WATER_LEVEL - 0.03, spot.y)))
		_add_multimesh(_load_mesh(model), items)


func _scatter_logs() -> void:
	var items: Array[Transform3D] = []
	for attempt in log_count * 20:
		if items.size() >= log_count:
			break
		var spot := _random_spot(MaraisTerrain.PLAY_RADIUS - 4.0)
		if terrain.height_at(spot.x, spot.y) > -0.8 or distance_to_boardwalk(spot) < 3.5:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(_rng.randf_range(-12.0, 12.0)))
		items.append(Transform3D(basis.scaled(Vector3.ONE * _rng.randf_range(3.0, 4.5)), Vector3(spot.x, -0.55, spot.y)))
	var instance := _add_multimesh(_load_mesh(log_model), items)
	instance.visibility_range_end = 0.0


func _is_reserved(spot: Vector2, margin: float) -> bool:
	for zone in RESERVED:
		if spot.distance_to(Vector2(zone.x, zone.y)) < zone.z + margin:
			return true
	return distance_to_boardwalk(spot) < 2.5 + margin


func _random_spot(radius: float) -> Vector2:
	return Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * radius


func _ground_transform(spot: Vector2, scale_factor: float) -> Transform3D:
	var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
	return Transform3D(basis, Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.05, spot.y))


func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = detail_range
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


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
