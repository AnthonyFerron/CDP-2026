class_name DesertLife
extends Node3D
## Vie du désert de Pythania : des vautours qui tournent haut au-dessus des ossements, des lézards et des
## scorpions qui filent entre les pierres et fuient le joueur, des toiles qui claquent au vent (fanions de la
## caravane et du poste de garde, chiffons des pieux, bannières du sanctuaire). Tout est construit au lancement,
## en formes simples, sans collision gênante : seules les hampes ont une fine collision.

const CLOTH := preload("res://scenes/levels/desert/desert_cloth.gdshader")
## Vautours : centre du cercle (x, z), rayon et hauteur de vol.
const VULTURES: Array[Vector4] = [
	Vector4(26.0, 50.0, 12.0, 26.0), Vector4(26.0, 50.0, 17.0, 31.0),
	Vector4(-36.0, -30.0, 14.0, 28.0), Vector4(-36.0, -30.0, 9.0, 23.0),
	Vector4(40.0, -2.0, 15.0, 33.0), Vector4(0.0, -10.0, 22.0, 38.0),
]
## Bêtes du sable : gîte (x, z) et espèce (0 : lézard, 1 : scorpion).
const CRITTERS: Array[Vector3] = [
	Vector3(14.0, 22.0, 0), Vector3(-15.0, 22.0, 0), Vector3(30.0, 12.0, 1), Vector3(-41.0, -12.0, 0),
	Vector3(10.0, -40.0, 1), Vector3(-30.0, 42.0, 0), Vector3(47.0, 24.0, 1), Vector3(-48.0, 28.0, 0),
	Vector3(-7.0, 30.0, 1), Vector3(20.0, -8.0, 0), Vector3(-22.0, -40.0, 0), Vector3(34.0, -30.0, 1),
]
## Fanions sur une hampe : pied de la hampe, hauteur de la hampe, taille du fanion, couleur. Le vent souffle vers +X.
const PENNANTS := [
	[Vector3(-30.95, 0.0, -37.37), 3.4, Vector2(1.5, 0.55), Color(0.62, 0.17, 0.1)],
	[Vector3(35.2, 0.0, 30.2), 3.0, Vector2(1.3, 0.6), Color(0.18, 0.28, 0.5)],
]
## Chiffons noués aux pieux coiffés d'un crâne de vautour (tools/build_desert.py) : pied du pieu.
const STAKES: Array[Vector3] = [Vector3(4.6, 0.0, 46.0), Vector3(-27.6, 0.0, 49.4), Vector3(-20.6, 0.0, 49.6), Vector3(-22.8, 0.0, 51.4)]
## Bannières pendues à l'architrave du sanctuaire englouti : point d'attache, taille, couleur.
const BANNERS := [
	[Vector3(-9.5, 5.3, -22.04), Vector2(1.2, 2.3), Color(0.6, 0.16, 0.1)],
	[Vector3(-5.5, 5.3, -22.04), Vector2(1.2, 2.0), Color(0.76, 0.52, 0.18)],
]
const LIZARD_SPEED := 2.8
const SCORPION_SPEED := 0.9
## Le joueur effraie les bêtes du sable à cette distance.
const FLEE_DISTANCE := 3.5
const HOME_RADIUS := 6.0

@export var terrain: DesertTerrain

var _vultures: Array[Dictionary] = []
var _critters: Array[Dictionary] = []
var _time := 0.0
var _player: Node3D
var _settled := false


func _ready() -> void:
	if not terrain.is_node_ready():
		await terrain.ready
	_player = get_tree().current_scene.get_node_or_null("Player") as Node3D
	_build_vultures()
	_build_critters()
	_build_cloths()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	for bird in _vultures:
		_fly(bird, delta)


## Les bêtes du sable se déplacent au rythme de la physique : elles évitent les rochers et les ruines.
func _physics_process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# Au premier pas de physique, les collisions du décor sont en place : chaque gîte s'écarte des rochers.
	if not _settled:
		_settled = true
		for critter in _critters:
			critter.home = _free_spot(critter.home)
			critter.spot = critter.home
			critter.target = critter.home
			_place(critter)
		return
	for critter in _critters:
		_scurry(critter, delta)


# --- Vautours ---------------------------------------------------------------------------------------------

func _build_vultures() -> void:
	var feathers := _material(Color(0.13, 0.1, 0.09))
	var skin := _material(Color(0.72, 0.48, 0.42))
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 5
	var body := _compose([
		[sphere, Transform3D(Basis().scaled(Vector3(0.17, 0.13, 0.45)), Vector3.ZERO)],
		[_box(Vector3(0.36, 0.03, 0.32)), Transform3D(Basis(), Vector3(0.0, 0.0, 0.52))],
		[_cone(0.05, 0.06, 0.22, 6), Transform3D(Basis(Vector3.RIGHT, -1.2), Vector3(0.0, 0.06, -0.42))],
	], feathers)
	_compose([
		[sphere, Transform3D(Basis().scaled(Vector3(0.07, 0.065, 0.09)), Vector3(0.0, 0.12, -0.56))],
		[_cone(0.005, 0.03, 0.1, 5), Transform3D(Basis(Vector3.RIGHT, -1.75), Vector3(0.0, 0.1, -0.66))],
	], skin, body)
	var wing := _compose([
		[_box(Vector3(1.55, 0.03, 0.5)), Transform3D(Basis(), Vector3(0.78, 0.0, 0.0))],
		[_box(Vector3(0.5, 0.025, 0.36)), Transform3D(Basis(), Vector3(1.7, 0.0, 0.08))],
	], feathers)
	for index in VULTURES.size():
		var spec := VULTURES[index]
		var bird := Node3D.new()
		var mesh := MeshInstance3D.new()
		mesh.mesh = body
		bird.add_child(mesh)
		var wings: Array[Node3D] = []
		for side in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 0.12, 0.04, 0.0)
			pivot.scale = Vector3(side, 1.0, 1.0)
			var part := MeshInstance3D.new()
			part.mesh = wing
			pivot.add_child(part)
			bird.add_child(pivot)
			wings.append(pivot)
		add_child(bird)
		_vultures.append({
			"node": bird, "wings": wings, "center": Vector2(spec.x, spec.y), "radius": spec.z, "height": spec.w,
			"angle": TAU * index / VULTURES.size(), "direction": 1.0 if index % 2 == 0 else -1.0, "phase": index * 1.7,
		})


func _fly(bird: Dictionary, delta: float) -> void:
	var direction: float = bird.direction
	bird.angle += direction * 5.5 / bird.radius * delta
	var angle: float = bird.angle
	var center: Vector2 = bird.center
	var radius: float = bird.radius
	var height: float = bird.height
	var spot := center + Vector2(cos(angle), sin(angle)) * radius
	var node: Node3D = bird.node
	var phase: float = bird.phase
	node.position = Vector3(spot.x, height + sin(_time * 0.35 + phase) * 1.5, spot.y)
	var tangent := Vector2(-sin(angle), cos(angle)) * direction
	node.rotation = Vector3(0.0, atan2(-tangent.x, -tangent.y), direction * 0.32)
	# Le plus souvent en vol plané, ailes en léger V ; de temps en temps, quelques battements lents.
	var flap := 0.0
	if sin(_time * 0.45 + phase) > 0.8:
		flap = sin(_time * 7.0) * 0.45
	for pivot: Node3D in bird.wings:
		pivot.rotation.z = 0.12 + flap


# --- Lézards et scorpions -----------------------------------------------------------------------------

func _build_critters() -> void:
	var lizard_skin := _material(Color(0.5, 0.4, 0.24))
	var shell := _material(Color(0.22, 0.13, 0.07))
	var lizard := _compose([
		[_box(Vector3(0.09, 0.045, 0.22)), Transform3D(Basis(), Vector3(0.0, 0.035, 0.0))],
		[_box(Vector3(0.07, 0.04, 0.08)), Transform3D(Basis(), Vector3(0.0, 0.04, -0.14))],
		[_cone(0.004, 0.03, 0.28, 5), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.03, 0.25))],
		[_box(Vector3(0.2, 0.015, 0.025)), Transform3D(Basis(Vector3.UP, 0.3), Vector3(0.0, 0.015, -0.06))],
		[_box(Vector3(0.2, 0.015, 0.025)), Transform3D(Basis(Vector3.UP, -0.3), Vector3(0.0, 0.015, 0.07))],
	], lizard_skin)
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	var scorpion_parts := [
		[sphere, Transform3D(Basis().scaled(Vector3(0.07, 0.03, 0.1)), Vector3(0.0, 0.035, 0.0))],
		[_cone(0.004, 0.016, 0.05, 4), Transform3D(Basis(Vector3.RIGHT, -2.4), Vector3(0.0, 0.17, 0.05))],
	]
	for segment in 4:
		var t := segment / 3.0
		scorpion_parts.append([_box(Vector3(0.035, 0.03, 0.05)), Transform3D(Basis(Vector3.RIGHT, -t * 1.9), Vector3(0.0, 0.05 + t * 0.12, 0.11 + sin(t * PI) * 0.05 - t * 0.04))])
	for side in [-1.0, 1.0]:
		scorpion_parts.append([_box(Vector3(0.025, 0.02, 0.09)), Transform3D(Basis(Vector3.UP, side * 0.4), Vector3(side * 0.06, 0.03, -0.12))])
		scorpion_parts.append([_box(Vector3(0.04, 0.025, 0.04)), Transform3D(Basis(), Vector3(side * 0.085, 0.03, -0.17))])
		for leg in 3:
			scorpion_parts.append([_box(Vector3(0.09, 0.012, 0.012)), Transform3D(Basis(Vector3.UP, side * (leg - 1) * 0.3), Vector3(side * 0.07, 0.02, -0.03 + leg * 0.04))])
	var scorpion := _compose(scorpion_parts, shell)
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	for spec in CRITTERS:
		var node := MeshInstance3D.new()
		node.mesh = lizard if spec.z == 0 else scorpion
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = 40.0
		var home := Vector2(spec.x, spec.y)
		add_child(node)
		var critter := {"node": node, "home": home, "lizard": spec.z == 0, "spot": home, "target": home,
			"wait": rng.randf_range(0.0, 3.0), "rng": rng, "scared": false}
		_place(critter)
		_critters.append(critter)


func _scurry(critter: Dictionary, delta: float) -> void:
	var spot: Vector2 = critter.spot
	var lizard: bool = critter.lizard
	var rng: RandomNumberGenerator = critter.rng
	if _player and not critter.scared:
		var away := spot - Vector2(_player.global_position.x, _player.global_position.z)
		if away.length() < FLEE_DISTANCE:
			critter.scared = true
			critter.wait = 0.0
			critter.target = _pick(critter, spot + away.normalized() * 4.0)
	if critter.wait > 0.0:
		critter.wait -= delta
		if critter.wait <= 0.0:
			critter.target = _pick(critter, spot + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 3.0))
		return
	var target: Vector2 = critter.target
	var offset := target - spot
	var speed := (LIZARD_SPEED if lizard else SCORPION_SPEED) * (1.6 if critter.scared else 1.0)
	if offset.length() < 0.05:
		critter.scared = false
		critter.wait = rng.randf_range(1.0, 4.0) if lizard else rng.randf_range(2.0, 6.0)
		return
	var step := offset.normalized() * minf(speed * delta, offset.length())
	critter.spot = spot + step
	var node: Node3D = critter.node
	node.rotation.y = atan2(-offset.x, -offset.y) + (sin(_time * 30.0) * 0.18 if lizard else 0.0)
	_place(critter)


func _place(critter: Dictionary) -> void:
	var spot: Vector2 = critter.spot
	var node: Node3D = critter.node
	node.position = Vector3(spot.x, maxf(terrain.surface_height(spot.x, spot.y), 0.03) + 0.005, spot.y)


func _clamp_home(critter: Dictionary, point: Vector2) -> Vector2:
	var home: Vector2 = critter.home
	return home + (point - home).limit_length(HOME_RADIUS)


## Destination d'une bête : près de son gîte, hors des rochers et des ruines ; sinon elle reste où elle est.
func _pick(critter: Dictionary, wanted: Vector2) -> Vector2:
	var rng: RandomNumberGenerator = critter.rng
	var spot: Vector2 = critter.spot
	for attempt in 8:
		var point := _clamp_home(critter, wanted)
		if _is_free(point) and _is_free((point + spot) * 0.5):
			return point
		wanted = spot + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.8, 2.5)
	return spot


func _is_free(point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = Vector3(point.x, terrain.surface_height(point.x, point.y) + 0.08, point.y)
	return get_world_3d().direct_space_state.intersect_point(query, 1).is_empty()


## Gîte libre le plus proche du point voulu, en tournant autour de lui.
func _free_spot(point: Vector2) -> Vector2:
	for ring in 8:
		for step in 8:
			var candidate := point + Vector2.from_angle(TAU * step / 8.0) * ring * 0.6
			if _is_free(candidate):
				return candidate
	return point


# --- Toiles au vent ---------------------------------------------------------------------------------------

func _build_cloths() -> void:
	var wood := _material(Color(0.3, 0.19, 0.1))
	var body := StaticBody3D.new()
	add_child(body)
	for index in PENNANTS.size():
		var spec: Array = PENNANTS[index]
		var foot: Vector3 = spec[0]
		var height: float = spec[1]
		var pole := MeshInstance3D.new()
		pole.mesh = _cone(0.04, 0.06, height, 6)
		pole.material_override = wood
		pole.position = foot + Vector3.UP * height * 0.5
		add_child(pole)
		var shape := CylinderShape3D.new()
		shape.radius = 0.12
		shape.height = height
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = pole.position
		body.add_child(collision)
		_cloth(foot + Vector3(0.0, height - spec[2].y * 0.5 - 0.05, 0.0), spec[2], spec[3], false, index * 1.3)
	for index in STAKES.size():
		var foot := STAKES[index]
		_cloth(foot + Vector3(0.0, 1.3, 0.0), Vector2(0.7, 0.22), [Color(0.6, 0.17, 0.1), Color(0.76, 0.52, 0.18)][index % 2], false, index * 0.9)
	for index in BANNERS.size():
		var spec: Array = BANNERS[index]
		var top: Vector3 = spec[0]
		_cloth(top - Vector3(0.0, spec[1].y * 0.5, 0.0), spec[1], spec[2], true, index * 2.1)


## Une toile verticale : un fanion attaché par son bord gauche (le vent l'étire vers +X), ou une bannière
## attachée par le haut, face vers +Z.
func _cloth(center: Vector3, size: Vector2, color: Color, hanging: bool, phase: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 10
	plane.subdivide_depth = 5
	var material := ShaderMaterial.new()
	material.shader = CLOTH
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("hanging", hanging)
	material.set_shader_parameter("phase", phase)
	material.set_shader_parameter("amplitude", 0.06 if hanging else 0.12)
	material.set_shader_parameter("speed", 3.0 if hanging else 7.0)
	var cloth := MeshInstance3D.new()
	cloth.mesh = plane
	cloth.material_override = material
	cloth.rotation.x = PI * 0.5
	cloth.position = center + (Vector3.ZERO if hanging else Vector3(size.x * 0.5, 0.0, 0.0))
	cloth.extra_cull_margin = 0.5
	add_child(cloth)


# --- Formes ---------------------------------------------------------------------------------------------

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material


func _box(size: Vector3) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = size
	return box


func _cone(top: float, bottom: float, height: float, segments: int) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.top_radius = top
	cone.bottom_radius = bottom
	cone.height = height
	cone.radial_segments = segments
	cone.rings = 1
	return cone


## Fond des maillages simples, chacun à sa place, en une surface d'un seul matériau, ajoutée à mesh s'il est donné.
func _compose(parts: Array, material: Material, mesh: ArrayMesh = null) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: Array in parts:
		tool.append_from(part[0], 0, part[1])
	var result := tool.commit(mesh)
	result.surface_set_material(result.get_surface_count() - 1, material)
	return result
