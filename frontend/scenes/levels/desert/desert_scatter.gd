@tool
class_name DesertScatter
extends Node3D
## Habille le Désert : cactus, rochers, colonnes renversées, épaves de guerre et sables mouvants.
## Les placements sont reproductibles et les petits détails disparaissent au loin.

@export var terrain: DesertTerrain
@export var cactus_models: Array[PackedScene]
@export var rock_models: Array[PackedScene]
@export var ruin_models: Array[PackedScene]
@export var wreck_models: Array[PackedScene]
@export var quicksand_material: Material
@export var cactus_count := 90
@export var rock_count := 140
@export var ruin_count := 18
@export var border_rock_count := 44
## Distance à laquelle les petits détails disparaissent.
@export var detail_range := 70.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5814
	# Rayons de collision à l'échelle 1 : tige des cactus, corps des rochers, colonnes et briques couchées.
	_scatter(cactus_models, cactus_count, Vector2(3.0, 5.0), true, 0.17)
	_scatter(rock_models, rock_count, Vector2(2.0, 5.0), true, 0.3)
	_scatter(ruin_models, ruin_count, Vector2(2.5, 3.5), true, 0.32, true)
	_add_wrecks()
	_add_border_rocks()
	_add_quicksands()


## Point libre : hors de l'esplanade, du chemin et des sables mouvants.
func is_free(spot: Vector2, margin: float) -> bool:
	if spot.distance_to(Vector2(DesertTerrain.PLAZA.x, DesertTerrain.PLAZA.y)) < DesertTerrain.PLAZA.z + 4.0 + margin:
		return false
	if absf(spot.x) < DesertTerrain.PATH_HALF_WIDTH + 2.0 + margin and spot.y > DesertTerrain.PATH_START - 6.0:
		return false
	for sand in DesertTerrain.QUICKSANDS:
		if spot.distance_to(Vector2(sand.x, sand.y)) < sand.z + 1.5 + margin:
			return false
	return true


func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, radius: float, tilted := false) -> void:
	var body: StaticBody3D
	if solid:
		body = StaticBody3D.new()
		add_child(body)
	var groups: Array[Array] = []
	for model in models:
		groups.append([])
	var placed := 0
	for attempt in count * 10:
		if placed >= count:
			break
		var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * DesertTerrain.PLAY_RADIUS
		if not is_free(spot, 0.5):
			continue
		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU)
		if tilted:
			basis = basis * Basis(Vector3.FORWARD, deg_to_rad(_rng.randf_range(70.0, 90.0)))
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.15, spot.y)
		if tilted:
			origin.y += 0.3 * scale_factor
		groups[placed % groups.size()].append(Transform3D(basis.scaled(Vector3.ONE * scale_factor), origin))
		if solid:
			var shape := CylinderShape3D.new()
			shape.radius = radius * scale_factor
			shape.height = 2.5
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = origin + Vector3.UP * 1.0
			body.add_child(collision)
		placed += 1
	for index in models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(_load_mesh(models[index]), transforms)


## Épaves de machines de siège, restes de la guerre, posées à des endroits fixes.
func _add_wrecks() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	for spot: Vector3 in [Vector3(26.0, 32.0, 40.0), Vector3(-30.0, 4.0, 200.0), Vector3(30.0, -18.0, 120.0), Vector3(-14.0, -38.0, 300.0)]:
		var model: PackedScene = wreck_models[int(spot.z) % wreck_models.size()]
		var wreck: Node3D = model.instantiate()
		wreck.position = Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.1, spot.y)
		wreck.rotation.y = deg_to_rad(spot.z)
		wreck.scale = Vector3.ONE * 4.5
		add_child(wreck)
		var shape := BoxShape3D.new()
		shape.size = Vector3(6.0, 1.6, 6.0)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = wreck.position + Vector3.UP * 0.8
		body.add_child(collision)


func _add_border_rocks() -> void:
	var items: Array[Array] = []
	for model in rock_models:
		items.append([])
	for i in border_rock_count:
		var angle := TAU * i / border_rock_count + _rng.randf_range(-0.05, 0.05)
		var spot := Vector2.from_angle(angle) * (DesertTerrain.PLAY_RADIUS + _rng.randf_range(2.0, 8.0))
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(12.0, 20.0))
		# Ces rochers sont énormes : enfoncés d'un dixième de leur taille pour ne pas flotter au-dessus des pentes.
		var sink := basis.get_scale().x * 0.12
		items[i % items.size()].append(Transform3D(basis, Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - sink, spot.y)))
	for index in rock_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		var instance := _add_multimesh(_load_mesh(rock_models[index]), transforms)
		instance.visibility_range_end = 0.0


func _add_quicksands() -> void:
	for sand in DesertTerrain.QUICKSANDS:
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE * sand.z * 2.2
		plane.material = quicksand_material
		var surface := MeshInstance3D.new()
		surface.mesh = plane
		# Le disque affleure au bord du creux, pour remplir la cuvette de sable meuble.
		var rim := INF
		for i in 12:
			var edge := Vector2.from_angle(TAU * i / 12.0) * sand.z * 1.05
			rim = minf(rim, terrain.height_at(sand.x + edge.x, sand.y + edge.y))
		surface.position = Vector3(sand.x, rim - 0.12, sand.y)
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(surface)


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
