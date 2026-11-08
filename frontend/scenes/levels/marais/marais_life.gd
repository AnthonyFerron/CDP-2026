class_name MaraisLife
extends Node3D
## La vie des marais, par des scripts légers et sans collision gênante :
## - des grenouilles sur les berges, qui sautent à l'eau quand on approche, et reviennent plus tard ;
## - des poissons qui font des ronds dans l'eau autour du joueur, et sautent parfois ;
## - des corbeaux perchés sur les pierres levées, la chapelle, le bosquet mort et la croix du gardien ;
##   ils tournent la tête, s'ébrouent, et ceux du cimetière s'envolent si l'on s'approche ;
## - des chauves-souris pendues aux voûtes de la crypte, qui s'envolent en tournoyant à l'approche ;
## - des lanternes pendues à des potences, qui se balancent.
## Les animaux sont faits de formes simples (les kits Kenney n'en ont pas), le poisson vient du kit Survival.

@export var terrain: MaraisTerrain
@export var player: Node3D
@export var fish_model: PackedScene
@export var lantern_model: PackedScene
## Îlots dont les berges accueillent les grenouilles : centre (x, z) et rayon du replat.
@export var frog_islands: Array[Vector3] = []
## Nénuphars où des grenouilles attendent, au bord des pontons : position (x, z).
@export var pad_frogs: Array[Vector2] = []
## Corbeaux : point au-dessus duquel ils se posent (sur ce que l'on trouve en dessous), et s'ils s'envolent.
@export var crow_perches: Array[Vector3] = []
@export var shy_crows: PackedInt32Array = PackedInt32Array()
## Chauves-souris : point d'accroche sous la voûte, en coordonnées du monde.
@export var bat_roosts: Array[Vector3] = []
## Potences des lanternes qui se balancent : pied (x, z) et orientation du bras (w, en degrés).
@export var gallows: Array[Vector4] = []

const FROG_SIZE := 1.9

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _frogs: Array[Dictionary] = []
var _crows: Array[Dictionary] = []
var _bats: Array[Dictionary] = []
var _lanterns: Array[Dictionary] = []
var _ripples: Array[Dictionary] = []
var _fish: Node3D
var _fish_jump := {}
var _ripple_timer := 2.0
var _ripple_mesh: TorusMesh
var _ripple_material: StandardMaterial3D
## Distance au-delà de laquelle les pièces des bêtes ne se dessinent plus (0 : toujours).
var _part_range := 45.0
## Bêtes déjà taillées, par espèce : la première grenouille, le premier corbeau, la première chauve-souris sont faits
## pièce par pièce puis fondus (MaraisBatch) ; les suivants sont des copies de ce modèle, prises avant qu'il soit placé,
## qui partagent ses maillages et ses matériaux. Chaque bête est la même qu'avant, pour bien moins de travail au
## chargement (une grenouille coûtait 6 ms). Espèce -> [modèle hors de l'arbre, chemins de ses pièces mobiles].
var _templates := {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for kind: String in _templates:
			(_templates[kind][0] as Node).free()


## Copie de la bête modèle de cette espèce, ajoutée au décor, et ses pièces mobiles ; [] si l'espèce n'a pas encore de
## modèle.
func _copy_of(kind: String) -> Array:
	if not _templates.has(kind):
		return []
	var copy := (_templates[kind][0] as Node3D).duplicate() as Node3D
	add_child(copy)
	var parts: Array[Node3D] = []
	for path: PackedInt32Array in _templates[kind][1]:
		var part: Node = copy
		for index in path:
			part = part.get_child(index)
		parts.append(part)
	return [copy, parts]


## Retient la bête qu'on vient de tailler (encore à l'origine) comme modèle de son espèce, avec ses pièces mobiles,
## repérées par leur rang parmi les enfants (une copie renomme les nœuds sans nom).
func _keep_template(kind: String, node: Node3D, parts: Array[Node3D]) -> void:
	var paths: Array[PackedInt32Array] = []
	for part in parts:
		var path := PackedInt32Array()
		var current: Node = part
		while current != node:
			path.insert(0, current.get_index())
			current = current.get_parent()
		paths.append(path)
	_templates[kind] = [node.duplicate(), paths]


func _ready() -> void:
	_rng.seed = 1234
	if terrain and not terrain.is_node_ready():
		await terrain.ready
	_build_ripples()
	_build_frogs()
	_build_bats()
	_part_range = 0.0
	_build_gallows()
	_part_range = 45.0
	# Les corbeaux cherchent leur perchoir par un rayon : on attend que le décor posé au sol soit en place.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_build_crows()


func _process(delta: float) -> void:
	_time += delta
	if not player:
		return
	var feet := player.global_position
	var inside := feet.y < -20.0
	if not inside:
		_update_frogs(delta, feet)
		_update_crows(delta, feet)
		_update_fish(delta, feet)
		_update_lanterns()
	else:
		_update_bats(delta, feet)
	_update_ripples(delta)


# --- Matériaux et formes ---------------------------------------------------------------------------------

func _material(color: Color, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _part(parent: Node3D, mesh: Mesh, position: Vector3, scale := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = position
	part.scale = scale
	part.rotation = rotation
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Pour le web : les petites bêtes ne se dessinent plus au-delà de 45 m (les lanternes pendues, si : _part_range).
	part.visibility_range_end = _part_range
	part.visibility_range_end_margin = 4.0
	parent.add_child(part)
	return part


func _sphere(radius: float, material: Material) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	mesh.material = material
	return mesh


# --- Ronds dans l'eau et poissons ------------------------------------------------------------------------

func _build_ripples() -> void:
	_ripple_mesh = TorusMesh.new()
	_ripple_mesh.inner_radius = 0.42
	_ripple_mesh.outer_radius = 0.5
	_ripple_mesh.rings = 24
	_ripple_mesh.ring_segments = 4
	_ripple_material = StandardMaterial3D.new()
	_ripple_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ripple_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ripple_material.albedo_color = Color(0.85, 0.95, 0.95, 0.75)
	# Dessinés après les nappes de brume, pour rester visibles à travers elles.
	_ripple_material.render_priority = 3
	_ripple_mesh.material = _ripple_material
	if fish_model:
		_fish = fish_model.instantiate()
		_fish.scale = Vector3.ONE * 2.6
		_fish.hide()
		add_child(_fish)


## Un rond s'élargit et s'efface à la surface de l'eau.
func ripple(at: Vector3, size := 1.0) -> void:
	var ring: MeshInstance3D = null
	for entry in _ripples:
		if not entry.node.visible:
			ring = entry.node
			_ripples.erase(entry)
			break
	if not ring:
		ring = MeshInstance3D.new()
		ring.mesh = _ripple_mesh
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.visibility_range_end = 45.0
		ring.material_override = _ripple_material.duplicate()
		add_child(ring)
	ring.position = Vector3(at.x, MaraisTerrain.WATER_LEVEL + 0.03, at.z)
	ring.show()
	_ripples.append({"node": ring, "age": 0.0, "size": size})


func _update_ripples(delta: float) -> void:
	for entry in _ripples:
		var ring: MeshInstance3D = entry.node
		if not ring.visible:
			continue
		entry.age += delta
		var t: float = entry.age / 1.8
		if t >= 1.0:
			ring.hide()
			continue
		var radius: float = lerpf(0.3, 2.4, t) * entry.size
		ring.scale = Vector3(radius, 0.05, radius)
		(ring.material_override as StandardMaterial3D).albedo_color.a = 0.75 * (1.0 - t)


## De temps en temps, un rond dans l'eau profonde près du joueur ; une fois sur quatre, un poisson saute.
func _update_fish(delta: float, feet: Vector3) -> void:
	if not _fish_jump.is_empty():
		_fish_jump.time += delta
		var t: float = _fish_jump.time / 0.9
		if t >= 1.0:
			_fish.hide()
			ripple(_fish_jump.to, 0.8)
			_fish_jump = {}
		else:
			var from: Vector3 = _fish_jump.from
			var to: Vector3 = _fish_jump.to
			_fish.position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * 0.9
			_fish.rotation = Vector3(lerpf(-1.0, 1.0, t), _fish_jump.yaw, 0.0)
	_ripple_timer -= delta
	if _ripple_timer > 0.0:
		return
	_ripple_timer = _rng.randf_range(1.5, 3.5)
	for attempt in 8:
		var spot := Vector2(feet.x, feet.z) + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5.0, 18.0)
		if spot.length() > MaraisTerrain.PLAY_RADIUS - 4.0 or terrain.height_at(spot.x, spot.y) > -0.6:
			continue
		var point := Vector3(spot.x, 0.0, spot.y)
		ripple(point, _rng.randf_range(0.6, 1.0))
		if _fish and _fish_jump.is_empty() and _rng.randf() < 0.28:
			var heading := _rng.randf() * TAU
			var to := point + Vector3(cos(heading), 0.0, sin(heading)) * 1.4
			_fish_jump = {"from": point + Vector3.DOWN * 0.1, "to": to, "time": 0.0, "yaw": -heading + PI * 0.5}
			_fish.show()
		break


# --- Grenouilles -----------------------------------------------------------------------------------------

## Une grenouille de formes simples : corps aplati, deux yeux saillants, pattes repliées.
func _make_frog() -> Node3D:
	var copy := _copy_of("frog")
	if not copy.is_empty():
		return copy[0]
	var frog := Node3D.new()
	var skin := _material(Color(0.32, 0.52, 0.16))
	var belly := _material(Color(0.62, 0.66, 0.3))
	var eye := _material(Color(0.95, 0.8, 0.25))
	_part(frog, _sphere(0.1, skin), Vector3(0, 0.07, 0), Vector3(1.0, 0.6, 1.3))
	_part(frog, _sphere(0.08, belly), Vector3(0, 0.05, 0.03), Vector3(1.0, 0.5, 1.1))
	for side in [-1.0, 1.0]:
		_part(frog, _sphere(0.035, eye), Vector3(side * 0.055, 0.13, 0.08))
		_part(frog, _sphere(0.05, skin), Vector3(side * 0.09, 0.03, -0.07), Vector3(1.0, 0.6, 1.6))
	frog.scale = Vector3.ONE * FROG_SIZE
	add_child(frog)
	# Pour le web : une grenouille, un seul maillage (ses couleurs passent dans les sommets), un appel de dessin.
	MaraisBatch.merge(frog, 100.0, false)
	_keep_template("frog", frog, [])
	return frog


func _build_frogs() -> void:
	for island in frog_islands:
		for step in 4:
			var angle := _rng.randf() * TAU
			var direction := Vector2.from_angle(angle)
			var spot := Vector2(island.x, island.y) + direction * island.z
			# On descend la berge jusqu'au-dessus des roseaux, qui poussent au ras de l'eau : la grenouille s'y voit.
			for walk in 30:
				if terrain.surface_height(spot.x, spot.y) < 0.26:
					break
				spot += direction * 0.3
			_add_frog(Vector3(spot.x, terrain.surface_height(spot.x, spot.y), spot.y), direction)
	# D'autres attendent sur un nénuphar, au bord des pontons, et plongent quand on passe.
	var pad := CylinderMesh.new()
	pad.top_radius = 0.32
	pad.bottom_radius = 0.32
	pad.height = 0.02
	pad.radial_segments = 12
	pad.material = _material(Color(0.2, 0.42, 0.22))
	for spot in pad_frogs:
		var leaf := _part(self, pad, Vector3(spot.x, MaraisTerrain.WATER_LEVEL + 0.01, spot.y))
		leaf.rotation.y = _rng.randf() * TAU
		var away := Vector2.from_angle(_rng.randf() * TAU)
		_add_frog(Vector3(spot.x, MaraisTerrain.WATER_LEVEL + 0.02, spot.y), away)


func _add_frog(home: Vector3, out: Vector2) -> void:
	var frog := _make_frog()
	frog.position = home
	frog.rotation.y = atan2(out.x, out.y)
	_frogs.append({"node": frog, "home": home, "out": Vector3(out.x, 0.0, out.y), "state": "rest", "time": 0.0})


func _update_frogs(delta: float, feet: Vector3) -> void:
	for frog in _frogs:
		var node: Node3D = frog.node
		frog.time += delta
		var home: Vector3 = frog.home
		var distance := Vector2(feet.x - home.x, feet.z - home.z).length()
		match frog.state:
			"rest":
				# Gorge qui palpite.
				node.scale.y = FROG_SIZE * (1.0 + sin(_time * 7.0 + home.x) * 0.06)
				if distance < 3.2:
					frog.state = "jump"
					frog.time = 0.0
			"jump":
				var t: float = frog.time / 0.55
				var out: Vector3 = frog.out
				if t >= 1.0:
					node.hide()
					ripple(home + out * 1.6, 0.6)
					frog.state = "away"
					frog.time = 0.0
				else:
					node.position = home + out * 1.6 * t + Vector3.UP * (sin(t * PI) * 0.45 - t * 0.2)
			"away":
				if frog.time > 18.0 and distance > 8.0:
					node.position = home
					node.show()
					frog.state = "rest"


# --- Corbeaux --------------------------------------------------------------------------------------------

func _make_crow() -> Dictionary:
	var copy := _copy_of("crow")
	if not copy.is_empty():
		var parts: Array[Node3D] = copy[1]
		var copied_wings: Array[Node3D] = [parts[1], parts[2]]
		return {"node": copy[0], "head": parts[0], "wings": copied_wings}
	var crow := Node3D.new()
	var black := _material(Color(0.05, 0.05, 0.07))
	var beak := _material(Color(0.2, 0.19, 0.18))
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.08
	capsule.height = 0.34
	capsule.material = black
	_part(crow, capsule, Vector3(0, 0.12, 0), Vector3.ONE, Vector3(PI * 0.5 - 0.35, 0, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.22, 0.13)
	crow.add_child(head)
	_part(head, _sphere(0.065, black), Vector3.ZERO)
	var bill := PrismMesh.new()
	bill.size = Vector3(0.05, 0.11, 0.04)
	bill.material = beak
	_part(head, bill, Vector3(0, -0.01, 0.08), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var tail := BoxMesh.new()
	tail.size = Vector3(0.1, 0.02, 0.16)
	tail.material = black
	_part(crow, tail, Vector3(0, 0.08, -0.2), Vector3.ONE, Vector3(-0.3, 0, 0))
	var wings: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.06, 0.16, 0.02)
		crow.add_child(pivot)
		var wing := BoxMesh.new()
		wing.size = Vector3(0.26, 0.015, 0.16)
		wing.material = black
		_part(pivot, wing, Vector3(side * 0.12, 0, 0))
		pivot.rotation = Vector3(0.0, side * 1.35, -side * 0.2)
		wings.append(pivot)
	for side in [-1.0, 1.0]:
		var leg := BoxMesh.new()
		leg.size = Vector3(0.012, 0.06, 0.012)
		leg.material = beak
		_part(crow, leg, Vector3(side * 0.03, 0.03, 0.0))
	crow.scale = Vector3.ONE * 1.6
	add_child(crow)
	# Corps, queue et pattes en un maillage, la tête en un autre ; les ailes battent à part.
	MaraisBatch.merge(crow, 100.0, false, false)
	MaraisBatch.merge(head, 100.0, false)
	_keep_template("crow", crow, [head, wings[0], wings[1]])
	return {"node": crow, "head": head, "wings": wings}


func _build_crows() -> void:
	var space := get_world_3d().direct_space_state
	for index in crow_perches.size():
		var perch := crow_perches[index]
		var ray := PhysicsRayQueryParameters3D.create(perch + Vector3.UP * 8.0, perch + Vector3.DOWN * 4.0)
		var hit := space.intersect_ray(ray)
		var seat: Vector3 = hit.position if not hit.is_empty() else perch
		var crow := _make_crow()
		var node: Node3D = crow.node
		node.position = seat
		node.rotation.y = _rng.randf() * TAU
		crow.merge({"seat": seat, "state": "perch", "time": 0.0, "next": _rng.randf_range(1.0, 3.0), "shy": index in shy_crows, "flight": Vector3.ZERO})
		_crows.append(crow)


func _flap(wings: Array, amount: float, speed: float) -> void:
	for index in wings.size():
		var side := -1.0 if index == 0 else 1.0
		(wings[index] as Node3D).rotation = Vector3(0.0, 0.0, side * (0.2 + amount * sin(_time * speed)))


func _fold(wings: Array) -> void:
	for index in wings.size():
		var side := -1.0 if index == 0 else 1.0
		# Ailes repliées le long du corps, vers la queue.
		(wings[index] as Node3D).rotation = Vector3(0.0, side * 1.35, -side * 0.2)


func _update_crows(delta: float, feet: Vector3) -> void:
	for crow in _crows:
		var node: Node3D = crow.node
		var head: Node3D = crow.head
		crow.time += delta
		var seat: Vector3 = crow.seat
		var distance := feet.distance_to(seat)
		match crow.state:
			"perch":
				crow.next -= delta
				if crow.next <= 0.0:
					crow.next = _rng.randf_range(1.0, 3.5)
					# Il tourne la tête, sautille ou s'ébroue.
					head.rotation.y = _rng.randf_range(-1.1, 1.1)
					if _rng.randf() < 0.3:
						node.rotation.y += _rng.randf_range(-1.2, 1.2)
					if _rng.randf() < 0.25:
						crow.state = "shake"
						crow.time = 0.0
				node.position = seat
				if crow.shy and distance < 7.0:
					crow.state = "fly"
					crow.time = 0.0
					var away := (seat - feet)
					away.y = 0.0
					crow.flight = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
			"shake":
				_flap(crow.wings, 0.9, 22.0)
				node.position = seat + Vector3.UP * absf(sin(crow.time * 12.0)) * 0.04
				if crow.time > 0.5:
					_fold(crow.wings)
					crow.state = "perch"
			"fly":
				_flap(crow.wings, 1.0, 16.0)
				var flight: Vector3 = crow.flight
				node.position = seat + flight * crow.time * 6.0 + Vector3.UP * crow.time * 3.0
				node.rotation.y = atan2(flight.x, flight.z)
				if crow.time > 5.0:
					node.hide()
					crow.state = "gone"
					crow.time = 0.0
			"gone":
				if crow.time > 25.0 and distance > 14.0:
					node.show()
					_fold(crow.wings)
					crow.state = "perch"


# --- Chauves-souris --------------------------------------------------------------------------------------

func _make_bat() -> Dictionary:
	var copy := _copy_of("bat")
	if not copy.is_empty():
		return {"node": copy[0], "wings": copy[1]}
	var bat := Node3D.new()
	var dark := _material(Color(0.07, 0.05, 0.06))
	var membrane := _material(Color(0.12, 0.08, 0.08))
	membrane.cull_mode = BaseMaterial3D.CULL_DISABLED
	_part(bat, _sphere(0.06, dark), Vector3.ZERO, Vector3(1.0, 0.9, 1.6))
	_part(bat, _sphere(0.045, dark), Vector3(0, 0.0, 0.1))
	var wings: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.04, 0, 0)
		bat.add_child(pivot)
		var wing := PrismMesh.new()
		wing.size = Vector3(0.18, 0.3, 0.01)
		wing.material = membrane
		_part(pivot, wing, Vector3(side * 0.15, 0, 0), Vector3.ONE, Vector3(PI * 0.5, 0, side * PI * 0.5))
		wings.append(pivot)
	bat.scale = Vector3.ONE * 1.5
	add_child(bat)
	MaraisBatch.merge(bat, 100.0, false, false)
	_keep_template("bat", bat, wings)
	return {"node": bat, "wings": wings}


func _build_bats() -> void:
	for roost in bat_roosts:
		var bat := _make_bat()
		var node: Node3D = bat.node
		node.position = roost
		node.rotation.x = PI
		bat.merge({"roost": roost, "state": "hang", "time": 0.0, "phase": _rng.randf() * TAU, "radius": _rng.randf_range(1.6, 2.6)})
		_bats.append(bat)


func _update_bats(delta: float, feet: Vector3) -> void:
	for bat in _bats:
		var node: Node3D = bat.node
		var roost: Vector3 = bat.roost
		bat.time += delta
		var distance := feet.distance_to(roost)
		match bat.state:
			"hang":
				_fold_bat(bat.wings)
				node.rotation.z = sin(_time * 1.3 + bat.phase) * 0.08
				if distance < 6.5:
					bat.state = "fly"
					bat.time = 0.0
					node.rotation = Vector3.ZERO
			"fly":
				_flap(bat.wings, 1.1, 26.0)
				# Elle tournoie sous la voûte, autour de son perchoir, puis y revient.
				var t: float = bat.time
				var angle: float = bat.phase + t * 2.4
				var radius: float = bat.radius
				var target := roost + Vector3(cos(angle) * radius, -0.9 + sin(t * 3.1) * 0.35, sin(angle) * radius * 0.8)
				node.position = node.position.lerp(target, minf(1.0, delta * 6.0))
				node.rotation.y = -angle
				if t > 7.0:
					bat.state = "return"
					bat.time = 0.0
			"return":
				_flap(bat.wings, 1.0, 24.0)
				node.position = node.position.lerp(roost, minf(1.0, delta * 3.0))
				if node.position.distance_to(roost) < 0.05:
					node.position = roost
					node.rotation = Vector3(PI, 0.0, 0.0)
					bat.state = "rest"
					bat.time = 0.0
			"rest":
				_fold_bat(bat.wings)
				if bat.time > 12.0 and distance > 6.5:
					bat.state = "hang"


func _fold_bat(wings: Array) -> void:
	for index in wings.size():
		(wings[index] as Node3D).rotation.z = (-1.0 if index == 0 else 1.0) * -1.2


# --- Lanternes pendues -----------------------------------------------------------------------------------

## Une potence de bois, sa chaîne et sa lanterne, qui se balance au vent. Le montant a sa collision.
func _build_gallows() -> void:
	if not lantern_model:
		return
	var wood := _material(Color(0.3, 0.2, 0.12))
	var iron := _material(Color(0.16, 0.16, 0.18))
	var glow := _material(Color(2.2, 1.6, 0.7), true)
	for entry in gallows:
		var foot := Vector3(entry.x, terrain.surface_height(entry.x, entry.y) - 0.05, entry.y)
		var post := Node3D.new()
		post.position = foot
		post.rotation.y = deg_to_rad(entry.w)
		add_child(post)
		var pole := BoxMesh.new()
		pole.size = Vector3(0.14, 2.7, 0.14)
		pole.material = wood
		_part(post, pole, Vector3(0, 1.35, 0))
		var arm := BoxMesh.new()
		arm.size = Vector3(0.1, 0.1, 0.95)
		arm.material = wood
		_part(post, arm, Vector3(0, 2.6, 0.42))
		var brace := BoxMesh.new()
		brace.size = Vector3(0.07, 0.6, 0.07)
		brace.material = wood
		_part(post, brace, Vector3(0, 2.35, 0.18), Vector3.ONE, Vector3(0.75, 0, 0))
		var hook := Node3D.new()
		hook.position = Vector3(0, 2.55, 0.82)
		post.add_child(hook)
		var chain := BoxMesh.new()
		chain.size = Vector3(0.02, 0.42, 0.02)
		chain.material = iron
		_part(hook, chain, Vector3(0, -0.21, 0))
		var lantern: Node3D = lantern_model.instantiate()
		lantern.scale = Vector3.ONE * 1.6
		lantern.position = Vector3(0, -0.42 - 0.39 * 1.6, 0)
		hook.add_child(lantern)
		_part(hook, _sphere(0.06, glow), Vector3(0, -0.42 - 0.39 * 1.6 * 0.45, 0))
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.3, 2.7, 0.3)
		shape.shape = box
		shape.position = Vector3(0, 1.35, 0)
		body.add_child(shape)
		post.add_child(body)
		# La potence en un maillage, la chaîne et la lanterne qui se balancent en un autre ; visibles de loin.
		MaraisBatch.merge(post, 100.0, false, false, false)
		MaraisBatch.merge(hook, 100.0, false, true, false)
		_lanterns.append({"hook": hook, "phase": _rng.randf() * TAU})


func _update_lanterns() -> void:
	for lantern in _lanterns:
		var hook: Node3D = lantern.hook
		var phase: float = lantern.phase
		hook.rotation = Vector3(sin(_time * 1.1 + phase) * 0.12, 0.0, sin(_time * 0.8 + phase * 1.7) * 0.09)
