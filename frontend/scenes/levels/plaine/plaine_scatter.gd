@tool
class_name PlaineScatter
extends Node3D
## Habille la Plaine : herbe brûlée, roches, arbres morts, lanternes, et lave dans les cratères.
## Les placements sont reproductibles et l'herbe disparaît au loin pour alléger le rendu.

signal lava_touched(body: Node3D)

const SMOKING_CRATERS := 4
const LIT_CRATERS := 4
## Lanternes du chemin : position (x, z), et si elles sont renversées.
const LANTERNS: Array[Vector3] = [
	Vector3(-3.2, 18.0, 0.0),
	Vector3(3.2, 25.0, 1.0),
	Vector3(-3.2, 32.0, 0.0),
	Vector3(3.4, 39.0, 0.0),
	Vector3(-3.4, 45.0, 1.0),
]

@export var terrain: PlaineTerrain
@export var grass_models: Array[PackedScene]
@export var small_rock_models: Array[PackedScene]
@export var large_rock_models: Array[PackedScene]
@export var lantern_model: PackedScene
@export var lava_material: Material
@export var lava_sound: AudioStream
@export var grass_count := 1500
@export var small_rock_count := 220
@export var large_rock_count := 26
@export var dead_tree_count := 26
@export var border_rock_count := 46
## Distance à laquelle les petits détails disparaissent.
@export var detail_range := 60.0

## Bassins de lave : centre de la surface et rayon.
var lava_pools: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 2026
	_scatter_grass()
	_scatter_small_rocks()
	_scatter_large_rocks()
	_scatter_dead_trees()
	_add_border_rocks()
	_add_lanterns()
	_add_crater_effects()


func is_near_lava(point: Vector3, margin: float) -> bool:
	for pool in lava_pools:
		var center: Vector3 = pool.center
		if Vector2(point.x - center.x, point.z - center.z).length() < pool.radius + margin:
			return true
	return false


func _scatter_grass() -> void:
	var soot := _flat_material(Color(0.07, 0.06, 0.065))
	var rust := _flat_material(Color(0.36, 0.13, 0.05))
	for model_index in grass_models.size():
		var mesh := _load_mesh(grass_models[model_index])
		var share := grass_count / grass_models.size()
		var burnt: Array[Transform3D] = []
		var glowing: Array[Transform3D] = []
		for i in share:
			var spot := _random_spot(0.0)
			var scale_factor := _rng.randf_range(2.5, 5.0)
			var item := _ground_transform(spot, scale_factor)
			if _rng.randf() < 0.22:
				glowing.append(item)
			else:
				burnt.append(item)
		_add_multimesh(mesh, burnt, soot)
		_add_multimesh(mesh, glowing, rust)


func _scatter_small_rocks() -> void:
	var material := _flat_material(Color(0.2, 0.18, 0.2))
	var count := small_rock_count / small_rock_models.size()
	var body := StaticBody3D.new()
	body.name = "SmallRocks"
	add_child(body)
	for model in small_rock_models:
		var mesh := _load_mesh(model)
		var size := mesh.get_aabb().size
		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(0.3), _rng.randf_range(1.5, 4.0))
			items.append(item)
			# Les cailloux assez hauts pour gêner le pas ont une collision à leur taille ; les plus plats se franchissent.
			var real := size * item.basis.get_scale()
			if real.y < 0.25:
				continue
			var shape := BoxShape3D.new()
			shape.size = real * 0.85
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.transform = Transform3D(item.basis.orthonormalized(), item.origin + Vector3.UP * shape.size.y * 0.5)
			body.add_child(collision)
		_add_multimesh(_load_mesh(model), items, material)


func _scatter_large_rocks() -> void:
	var material := _flat_material(Color(0.17, 0.15, 0.17))
	var count := large_rock_count / large_rock_models.size()
	var body := StaticBody3D.new()
	body.name = "LargeRocks"
	add_child(body)
	for model in large_rock_models:
		var mesh := _load_mesh(model)
		var size := mesh.get_aabb().size
		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(1.1), _rng.randf_range(5.0, 9.0))
			items.append(item)
			var shape := BoxShape3D.new()
			shape.size = size * item.basis.get_scale() * 0.8
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.transform = Transform3D(
				item.basis.orthonormalized(), item.origin + Vector3.UP * shape.size.y * 0.5
			)
			body.add_child(collision)
		var instance := _add_multimesh(mesh, items, material)
		instance.visibility_range_end = 0.0


func _scatter_dead_trees() -> void:
	var material := _flat_material(Color(0.08, 0.06, 0.06))
	var meshes: Array[ArrayMesh] = [_dead_tree_mesh(), _dead_tree_mesh(), _dead_tree_mesh()]
	var body := StaticBody3D.new()
	body.name = "DeadTrees"
	add_child(body)
	var items: Array[Array] = [[], [], []]
	for i in dead_tree_count:
		var spot := _random_spot(1.0)
		var item := _ground_transform(spot, _rng.randf_range(0.9, 1.5))
		items[i % meshes.size()].append(item)
		var shape := CylinderShape3D.new()
		shape.radius = 0.4
		shape.height = 3.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = item.origin + Vector3.UP * 1.5
		body.add_child(collision)
	for index in meshes.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		var instance := _add_multimesh(meshes[index], transforms, material)
		instance.visibility_range_end = 0.0


## Remparts : de hauts rochers sur le pourtour, pour que la zone ne s'arrête pas sur une pente nue.
func _add_border_rocks() -> void:
	var material := _flat_material(Color(0.16, 0.14, 0.16))
	var items: Array[Array] = []
	items.resize(large_rock_models.size())
	for list in items:
		list.assign([])
	for i in border_rock_count:
		var angle := TAU * i / border_rock_count + _rng.randf_range(-0.04, 0.04)
		var distance := PlaineTerrain.PLAY_RADIUS + _rng.randf_range(1.5, 7.0)
		var spot := Vector2.from_angle(angle) * distance
		var item := _ground_transform(spot, _rng.randf_range(9.0, 16.0))
		item.origin.y -= 0.6
		items[i % items.size()].append(item)
	for index in large_rock_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		var instance := _add_multimesh(_load_mesh(large_rock_models[index]), transforms, material)
		instance.visibility_range_end = 0.0


## Lanternes le long du chemin : certaines tiennent encore debout et brillent, d'autres sont tombées.
func _add_lanterns() -> void:
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.6, 0.25)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.55, 0.2)
	glow.emission_energy_multiplier = 3.0
	var bulb := SphereMesh.new()
	bulb.radius = 0.13
	bulb.height = 0.26
	bulb.material = glow
	var lanterns := Node3D.new()
	lanterns.name = "Lanterns"
	add_child(lanterns)
	var body := StaticBody3D.new()
	body.name = "LanternPosts"
	add_child(body)
	for spot in LANTERNS:
		var lantern: Node3D = lantern_model.instantiate()
		var ground := terrain.footing_height(spot.x, spot.y)
		var fallen := spot.z > 0.5
		lantern.scale = Vector3.ONE * 2.2
		lantern.rotation.y = 0.0 if spot.x < 0.0 else PI
		if fallen:
			lantern.rotation = Vector3(0.0, _rng.randf_range(0.0, TAU), deg_to_rad(84.0))
			ground += 0.25
		lantern.position = Vector3(spot.x, ground, spot.y)
		lanterns.add_child(lantern)
		# Le poteau du lampadaire, debout ou couché, a sa collision.
		var shape := BoxShape3D.new()
		var collision := CollisionShape3D.new()
		collision.shape = shape
		if fallen:
			# Couché par une rotation autour de z : le poteau s'étend vers -x, dans le cap du lampadaire.
			var heading := Basis(Vector3.UP, lantern.rotation.y)
			shape.size = Vector3(3.4, 0.5, 0.5)
			collision.transform = Transform3D(heading, Vector3(spot.x, ground, spot.y) + heading * Vector3(-1.7, 0.0, 0.0))
		else:
			shape.size = Vector3(0.5, 3.4, 0.5)
			collision.position = Vector3(spot.x, ground + 1.7, spot.y)
		body.add_child(collision)
		if not fallen:
			var light := MeshInstance3D.new()
			light.mesh = bulb
			light.position = Vector3(spot.x, ground + 3.0, spot.y)
			add_child(light)


func _add_crater_effects() -> void:
	var smoke_texture := _smoke_texture()
	var ember_material := _ember_material()
	for index in PlaineTerrain.CRATERS.size():
		var crater := PlaineTerrain.CRATERS[index]
		var center := Vector3(crater.x, terrain.height_at(crater.x, crater.y), crater.y)
		var radius := crater.z * PlaineTerrain.LAVA_RATIO
		var surface := _lava_level(crater, radius)
		var pool := Vector3(crater.x, surface, crater.y)
		lava_pools.append({center = pool, radius = radius})
		add_child(_lava_surface(pool, radius))
		add_child(_lava_hazard(pool, radius))
		add_child(_embers(pool, radius, ember_material))
		if lava_sound:
			var rumble := AudioStreamPlayer3D.new()
			rumble.stream = lava_sound
			rumble.position = pool
			rumble.unit_size = radius
			rumble.max_distance = radius * 4.0
			rumble.volume_db = -4.0
			rumble.autoplay = not Engine.is_editor_hint()
			add_child(rumble)
		if index < LIT_CRATERS:
			var light := FlickeringLight.new()
			light.light_color = Color(1.0, 0.36, 0.1)
			light.light_energy = 3.0
			light.omni_range = crater.z * 1.5
			light.flicker = 0.18
			light.speed = 2.0
			light.position = pool + Vector3.UP * 2.0
			add_child(light)
		if index < SMOKING_CRATERS:
			add_child(_smoke(center, crater.z * 0.3, smoke_texture))


## Hauteur de la lave : juste sous le sol au bord du bassin, pour qu'elle ne flotte pas au-dessus.
func _lava_level(crater: Vector4, radius: float) -> float:
	var lowest := INF
	for i in 12:
		var edge := Vector2.from_angle(TAU * i / 12.0) * radius
		lowest = minf(lowest, terrain.height_at(crater.x + edge.x, crater.y + edge.y))
	return lowest - 0.08


func _lava_surface(center: Vector3, radius: float) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * radius * 2.0
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	plane.material = lava_material
	var surface := MeshInstance3D.new()
	surface.mesh = plane
	surface.position = center
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return surface


func _lava_hazard(center: Vector3, radius: float) -> Area3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius * 0.92
	shape.height = 3.4
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var area := Area3D.new()
	area.position = center + Vector3.DOWN * 1.3
	area.add_child(collision)
	area.body_entered.connect(func(body: Node3D) -> void: lava_touched.emit(body))
	return area


func _embers(center: Vector3, radius: float, material: Material) -> CPUParticles3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	gradient.set_color(1, Color(1.0, 0.2, 0.05, 0.0))
	var embers := CPUParticles3D.new()
	embers.mesh = quad
	embers.position = center + Vector3.UP * 0.2
	embers.amount = 18
	embers.lifetime = 3.5
	embers.preprocess = 3.5
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = radius * 0.8
	embers.direction = Vector3.UP
	embers.spread = 25.0
	embers.gravity = Vector3(0.3, 0.4, 0.0)
	embers.initial_velocity_min = 0.6
	embers.initial_velocity_max = 1.8
	embers.color_ramp = gradient
	return embers


func _ember_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(2.5, 1.4, 0.6)
	return material


func _smoke(center: Vector3, radius: float, texture: Texture2D) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(5.0, 5.0)
	quad.material = material

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.3, 0.26, 0.28, 0.0))
	gradient.set_color(1, Color(0.2, 0.18, 0.2, 0.0))
	gradient.add_point(0.2, Color(0.28, 0.24, 0.26, 0.4))

	var smoke := CPUParticles3D.new()
	smoke.mesh = quad
	smoke.position = center
	smoke.amount = 12
	smoke.lifetime = 12.0
	smoke.preprocess = 12.0
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = radius
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.gravity = Vector3.ZERO
	smoke.initial_velocity_min = 1.0
	smoke.initial_velocity_max = 1.8
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 2.2
	smoke.color_ramp = gradient
	return smoke


func _smoke_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


## Tire un point libre : ni sur les ruines, ni sur le chemin, ni au fond d'un cratère.
func _random_spot(crater_margin: float) -> Vector2:
	var spot := Vector2.ZERO
	for attempt in 40:
		spot = Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * PlaineTerrain.PLAY_RADIUS
		if _is_free(spot, crater_margin):
			break
	return spot


func _is_free(spot: Vector2, crater_margin: float) -> bool:
	if absf(spot.x) < 15.0 and absf(spot.y) < 15.0:
		return false
	if absf(spot.x) < 4.5 and spot.y > 0.0:
		return false
	for crater in PlaineTerrain.CRATERS:
		if Vector2(spot.x - crater.x, spot.y - crater.y).length() < crater.z * crater_margin:
			return false
	return true


func _ground_transform(spot: Vector2, scale_factor: float) -> Transform3D:
	var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
	return Transform3D(basis, Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.05, spot.y))


func _add_multimesh(
	mesh: Mesh, transforms: Array[Transform3D], material: Material
) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
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


func _dead_tree_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := _rng.randf_range(5.0, 7.5)
	var lean := Vector3(_rng.randf_range(-0.5, 0.5), 0.0, _rng.randf_range(-0.5, 0.5))
	var top := Vector3.UP * height + lean
	_add_limb(tool, Vector3.ZERO, top, 0.42, 0.1)
	for i in _rng.randi_range(4, 6):
		var start := top * _rng.randf_range(0.45, 0.95)
		var angle := _rng.randf() * TAU
		var reach := _rng.randf_range(1.4, 2.8)
		var tip := start + Vector3(cos(angle) * reach, reach * 0.8, sin(angle) * reach)
		_add_limb(tool, start, tip, 0.16, 0.03)
		var side := tip.lerp(start, 0.4)
		_add_limb(tool, side, side + Vector3(-sin(angle), 0.8, cos(angle)), 0.07, 0.02)
	tool.generate_normals()
	return tool.commit()


func _add_limb(tool: SurfaceTool, start: Vector3, end: Vector3, radius: float, tip_radius: float) -> void:
	const SIDES := 5
	var axis := (end - start).normalized()
	var reference := Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var side_a := axis.cross(reference).normalized()
	var side_b := axis.cross(side_a)
	for i in SIDES:
		var angle_a := TAU * i / SIDES
		var angle_b := TAU * (i + 1) / SIDES
		var direction_a := side_a * cos(angle_a) + side_b * sin(angle_a)
		var direction_b := side_a * cos(angle_b) + side_b * sin(angle_b)
		var low_a := start + direction_a * radius
		var low_b := start + direction_b * radius
		var high_a := end + direction_a * tip_radius
		var high_b := end + direction_b * tip_radius
		for vertex in [low_a, high_a, low_b, low_b, high_a, high_b]:
			tool.add_vertex(vertex)
