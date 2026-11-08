class_name HubWildlife
extends Node3D
## La faune qui revient au hub avec les livres posés : au troisième livre, des poissons sautent dans la rivière
## redevenue vive et des libellules rasent l'eau ; au quatrième, des papillons volent au-dessus du jardin du roi et
## des berges fleuries. Le hub sinistré n'en a aucune.
##
## Les insectes volent dans leur shader (hub_insect.gdshader) : un MultiMesh par case de 64 m et par espèce, effacé
## au-delà de RANGE mètres, sans ombre ni calcul du processeur. Le poisson est un seul modèle Kenney, montré le temps
## d'un saut, près de l'auditeur.

@export var terrain: HubTerrain
@export var insect_shader: Shader
@export var fish_model: PackedScene

## Cases des essaims : larges, le jardin du roi tient dans deux, un appel de dessin chacune.
const CELL := 64.0
const RANGE := 50.0
const BUTTERFLY_COUNT := 60
## Parterres du jardin du roi (tools/build_hub.py, build_park) : la plupart des papillons y butinent.
const FLOWER_BEDS: Array[Vector2] = [Vector2(36.0, -58.0), Vector2(36.0, -64.0), Vector2(48.0, -58.0), Vector2(48.0, -64.0), Vector2(47.6, -76.4)]
const DRAGONFLY_COUNT := 56
## Tronçon de la rivière où volent les libellules : du jardin du roi au moulin (z, en mètres), où passe le joueur.
const DRAGONFLY_REACH := Vector2(-95.0, 50.0)
const BUTTERFLY_COLORS: Array[Color] = [Color(0.98, 0.84, 0.3), Color(0.97, 0.96, 0.9), Color(0.98, 0.55, 0.22), Color(0.5, 0.66, 0.98)]
const DRAGONFLY_COLORS: Array[Color] = [Color(0.16, 0.32, 0.95), Color(0.92, 0.26, 0.2), Color(0.12, 0.62, 0.32)]
## Vie du hub (livres posés sur quatre) où chaque espèce revient.
const FISH_LIFE := 0.75
const DRAGONFLY_LIFE := 0.75
const BUTTERFLY_LIFE := 1.0
## Attente entre deux sauts de poisson (s), distance à l'auditeur du point où il saute (m), et durée du saut (s).
const LEAP_WAIT := Vector2(2.5, 6.0)
const LEAP_REACH := Vector2(5.0, 22.0)
const LEAP_TIME := 0.85

var _butterflies: Array[MultiMeshInstance3D] = []
var _dragonflies: Array[MultiMeshInstance3D] = []
var _fish: Node3D
var _life := 0.0
var _rng := RandomNumberGenerator.new()
var _wait := 2.0
var _leap := -1.0
var _leap_from := Vector3.ZERO
var _leap_dir := Vector3.FORWARD


func _ready() -> void:
	_rng.seed = 5840
	if insect_shader:
		_butterflies = _swarm(_butterfly_mesh(), _butterfly_spots(), BUTTERFLY_COLORS, 13.0, 0.7, Vector2(0.5, 1.3))
		_dragonflies = _swarm(_dragonfly_mesh(), _dragonfly_spots(), DRAGONFLY_COLORS, 42.0, 0.55, Vector2(0.9, 1.6))
	if fish_model:
		_fish = fish_model.instantiate() as Node3D
		_fish.scale = Vector3.ONE * 0.9
		_fish.visible = false
		add_child(_fish)
	_rng.randomize()
	set_life(0.0)


## Vie du hub, de 0 à 1 : chaque espèce revient à son palier.
func set_life(life: float) -> void:
	_life = life
	_show(_butterflies, 1.0 if life >= BUTTERFLY_LIFE - 0.01 else 0.0)
	_show(_dragonflies, 1.0 if life >= 0.99 else (0.5 if life >= DRAGONFLY_LIFE - 0.01 else 0.0))
	set_process(_fish != null and life >= FISH_LIFE - 0.01)
	if not is_processing() and _fish:
		_fish.visible = false
		_leap = -1.0


func _show(instances: Array[MultiMeshInstance3D], share: float) -> void:
	for instance in instances:
		var count := int(instance.multimesh.instance_count * share)
		instance.multimesh.visible_instance_count = count
		instance.visible = count > 0


## Papillons : au-dessus des pelouses et des parterres du jardin du roi, et sur les berges, du côté du village.
func _butterfly_spots() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var park := HubTerrain.PARK_AREA.grow(-1.5)
	for index in BUTTERFLY_COUNT * 3 / 4:
		var point := Vector2(_rng.randf_range(park.position.x, park.end.x), _rng.randf_range(park.position.y, park.end.y))
		if index % 2 == 0:
			point = FLOWER_BEDS[index / 2 % FLOWER_BEDS.size()] + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-2.5, 2.5))
		spots.append(_ground(point))
	var samples := HubTerrain.river_samples()
	while spots.size() < BUTTERFLY_COUNT:
		var sample := samples[_rng.randi_range(8, samples.size() / 2)]
		var side := -1.0 if _rng.randf() < 0.7 else 1.0
		var point := Vector2(sample.x, sample.y) + Vector2(side * (sample.z + _rng.randf_range(3.0, 8.0)), _rng.randf_range(-1.0, 1.0))
		if HubTerrain.inside_limit(point, 4.0):
			spots.append(_ground(point))
	return spots


## Libellules : au ras de l'eau de la rivière, dans la vallée, et sur l'étang du jardin.
func _dragonfly_spots() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var reach: Array[Vector3] = []
	for sample in HubTerrain.river_samples():
		if sample.y > DRAGONFLY_REACH.x and sample.y < DRAGONFLY_REACH.y:
			reach.append(sample)
	for index in DRAGONFLY_COUNT - 8:
		var sample := reach[_rng.randi() % reach.size()]
		var across := _rng.randf_range(-0.6, 0.6) * sample.z
		spots.append(Vector3(sample.x + across, HubTerrain.WATER_LEVEL - 0.2, sample.y))
	var pond: Vector3 = HubTerrain.PONDS[0]
	for index in 8:
		var point := Vector2(pond.x, pond.y) + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * pond.z * 0.6
		spots.append(Vector3(point.x, HubTerrain.POND_LEVEL - 0.2, point.y))
	return spots


func _ground(point: Vector2) -> Vector3:
	return Vector3(point.x, terrain.surface_height(point.x, point.y) if terrain else 0.0, point.y)


## Un essaim : une copie par place, rangées par cases ; chaque copie a sa couleur, sa phase, son rayon, sa vitesse et
## sa hauteur de vol (heights : de .. à, en mètres au-dessus de sa place).
func _swarm(mesh: Mesh, spots: Array[Vector3], colors: Array[Color], flap_speed: float, radius: float, heights: Vector2) -> Array[MultiMeshInstance3D]:
	var material := ShaderMaterial.new()
	material.shader = insect_shader
	material.set_shader_parameter("flap_speed", flap_speed)
	mesh.surface_set_material(0, material)
	var cells := {}
	for spot in spots:
		var cell := Vector2i(floori(spot.x / CELL), floori(spot.z / CELL))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(spot)
	var result: Array[MultiMeshInstance3D] = []
	for cell: Vector2i in cells:
		var list: Array = cells[cell]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.use_custom_data = true
		multimesh.mesh = mesh
		multimesh.instance_count = list.size()
		var bounds := AABB(list[0], Vector3.ZERO)
		for index in list.size():
			var spot: Vector3 = list[index]
			bounds = bounds.expand(spot)
			multimesh.set_instance_transform(index, Transform3D(Basis(), spot))
			multimesh.set_instance_color(index, colors[_rng.randi() % colors.size()])
			multimesh.set_instance_custom_data(index, Color(_rng.randf(), radius * _rng.randf_range(0.6, 1.6),
				_rng.randf_range(0.5, 1.1), _rng.randf_range(heights.x, heights.y)))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Le vol sort du maillage : la boîte de la case couvre tout l'espace où volent ses copies.
		instance.custom_aabb = AABB(bounds.position - Vector3(radius * 2.0, 0.5, radius * 2.0), bounds.size + Vector3(radius * 4.0, heights.y + 1.5, radius * 4.0))
		instance.visibility_range_end = RANGE
		instance.visibility_range_end_margin = 8.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(instance)
		result.append(instance)
	return result


## Papillon de 45 cm d'envergure (plus grand que nature, pour se voir dans le jardin) : deux ailes de deux triangles
## (l'aile avant, l'aile arrière) et un corps fin.
func _butterfly_mesh() -> ArrayMesh:
	var fore := [Vector3(0.018, 0.0, 0.06), Vector3(0.225, 0.0, 0.135), Vector3(0.195, 0.0, -0.015)]
	var hind := [Vector3(0.018, 0.0, 0.0), Vector3(0.18, 0.0, -0.022), Vector3(0.11, 0.0, -0.15)]
	return _insect([fore, hind], 0.01, Vector2(-0.09, 0.075))


## Libellule de 30 cm d'envergure : quatre ailes longues et étroites, et un long corps.
func _dragonfly_mesh() -> ArrayMesh:
	var fore := [Vector3(0.008, 0.0, 0.045), Vector3(0.15, 0.0, 0.06), Vector3(0.15, 0.0, 0.027)]
	var hind := [Vector3(0.008, 0.0, 0.015), Vector3(0.14, 0.0, 0.0), Vector3(0.14, 0.0, -0.03)]
	return _insect([fore, hind], 0.012, Vector2(-0.18, 0.07))


func _insect(wings: Array, body: float, length: Vector2) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(Color.WHITE)
	tool.set_normal(Vector3.UP)
	for wing: Array in wings:
		for side: float in [1.0, -1.0]:
			for vertex: Vector3 in wing:
				tool.add_vertex(Vector3(vertex.x * side, vertex.y, vertex.z))
	for vertex in [Vector3(-body, 0.0, length.x), Vector3(body, 0.0, length.x), Vector3(body, 0.0, length.y),
			Vector3(-body, 0.0, length.x), Vector3(body, 0.0, length.y), Vector3(-body, 0.0, length.y)]:
		tool.add_vertex(vertex)
	return tool.commit()


## Le poisson : de temps en temps, il jaillit de l'eau près de l'auditeur, devant lui, et y replonge.
func _process(delta: float) -> void:
	if _leap >= 0.0:
		_leap += delta
		var t := _leap / LEAP_TIME
		if t >= 1.0 or not is_visible_in_tree():
			_fish.visible = false
			_leap = -1.0
			_wait = _rng.randf_range(LEAP_WAIT.x, LEAP_WAIT.y)
			return
		var position := _leap_from + _leap_dir * (t * 1.3) + Vector3.UP * (sin(t * PI) * 0.8)
		var velocity := _leap_dir * 1.3 + Vector3.UP * cos(t * PI) * 0.8 * PI
		_fish.global_position = position
		_fish.look_at(position + velocity, Vector3.UP, true)
		return
	_wait -= delta
	if _wait > 0.0 or not is_visible_in_tree():
		return
	_wait = 1.0
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var ear := camera.global_position
	var look := -camera.global_basis.z
	var flat_look := Vector2(look.x, look.z).normalized()
	var samples := HubTerrain.river_samples()
	for attempt in 8:
		var index := _rng.randi_range(2, samples.size() - 3)
		var sample := samples[index]
		var level := HubTerrain.WATER_LEVEL
		var along := Vector2(samples[index + 1].x - sample.x, samples[index + 1].y - sample.y).normalized()
		var spot := Vector2(sample.x, sample.y) + along.orthogonal() * _rng.randf_range(-0.5, 0.5) * sample.z
		if attempt >= 6:
			var pond: Vector3 = HubTerrain.PONDS[0]
			spot = Vector2(pond.x, pond.y) + Vector2.from_angle(_rng.randf() * TAU) * pond.z * 0.4
			level = HubTerrain.POND_LEVEL
			along = Vector2.from_angle(_rng.randf() * TAU)
		var offset := spot - Vector2(ear.x, ear.z)
		var distance := offset.length()
		if distance < LEAP_REACH.x or distance > LEAP_REACH.y or offset.normalized().dot(flat_look) < 0.5:
			continue
		if _rng.randf() < 0.5:
			along = -along
		_leap_from = Vector3(spot.x, level - 0.15, spot.y)
		_leap_dir = Vector3(along.x, 0.0, along.y)
		_leap = 0.0
		_fish.visible = true
		return
