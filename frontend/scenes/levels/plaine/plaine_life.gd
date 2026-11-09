class_name PlaineLife
extends Node3D
## Vie des plaines d'Hexcole : des corbeaux tournent au-dessus des engins de siège, d'autres guettent sur la tour,
## les croix et la stèle des tombes, et s'envolent quand le joueur approche ou quand le volcan gronde (startle), avant
## de revenir plus tard ; les bannières déchirées ondulent dans le vent. Celles qui sont plantées dans les positions de
## Vibelandia portent ses couleurs, les autres le bleu de Codia. Tout est animé par ce script, sans collision.

## Centre et rayon du vol des corbeaux, au-dessus des engins de siège et des tombes.
const FLOCK_CENTER := Vector3(-6.0, 13.0, 42.0)
const FLOCK_COUNT := 7
## Perchoirs fixes : bord du sommet de la tour de guet et dessus de la stèle des défenseurs. Les croix des tombes
## s'y ajoutent, leur sommet lu sur leur maillage.
const PERCHES: Array[Vector3] = [
	Vector3(-22.1, 6.88, 53.25),
	Vector3(17.6, 1.52, 50.5),
]
## Distance à laquelle un corbeau perché s'envole, et délai avant qu'il ne revienne.
const ALARM_DISTANCE := 7.0
const RETURN_DELAY := 24.0
## Positions de Vibelandia (x, z, rayon), comme VIBELANDIA_CAMPS dans tools/build_plaine.py : engins de siège et
## batterie de balistes.
const VIBELANDIA_CAMPS: Array[Vector3] = [Vector3(-14.0, 39.0, 9.0), Vector3(17.0, -22.0, 8.0)]

@export var player: Node3D
## Scènes de décor où chercher les bannières à faire onduler.
@export var decor: Array[Node3D] = []
## Couleurs du kit Castle pour les bannières de Vibelandia : la variante dont le bleu de Codia devient vert.
@export var vibelandia_colors: Texture2D

var _crows: Array[Crow] = []
var _flags: Array[Node3D] = []
var _flag_bases: Array[Basis] = []
var _time := 0.0


func _ready() -> void:
	var feathers := StandardMaterial3D.new()
	feathers.albedo_color = Color(0.05, 0.05, 0.06)
	feathers.roughness = 0.6
	var beak := StandardMaterial3D.new()
	beak.albedo_color = Color(0.18, 0.17, 0.16)
	var random := RandomNumberGenerator.new()
	random.seed = 1402
	var perches := PERCHES.duplicate()
	for root in decor:
		for model in root.get_node("Models").get_children():
			if String(model.name).begins_with("cross_wood"):
				perches.append(_top_of(model))
	for index in FLOCK_COUNT + perches.size():
		var crow := Crow.new(feathers, beak)
		crow.radius = random.randf_range(7.0, 15.0)
		crow.speed = random.randf_range(0.22, 0.38) * (1.0 if index % 3 else -1.0)
		crow.angle = random.randf() * TAU
		crow.altitude = random.randf_range(-2.0, 3.0)
		crow.phase = random.randf() * TAU
		crow.position = FLOCK_CENTER + Vector3(cos(crow.angle) * crow.radius, crow.altitude, sin(crow.angle) * crow.radius)
		crow.timer = 3.0 + random.randf() * 10.0
		if index >= FLOCK_COUNT:
			crow.perch = perches[index - FLOCK_COUNT]
			crow.perched = true
			crow.position = crow.perch
			crow.rotation.y = random.randf() * TAU
		add_child(crow)
		_crows.append(crow)
	var enemy_materials := {}
	for root in decor:
		for model in root.get_node("Models").get_children():
			if not String(model.name).begins_with("flag_"):
				continue
			if _in_vibelandia_camp(model.global_position):
				_dye(model, enemy_materials)
			# Une bannière piétinée, couchée dans la cendre, ne flotte plus.
			if model.basis.y.normalized().y > 0.5:
				_flags.append(model)
				_flag_bases.append(model.basis)


func _in_vibelandia_camp(point: Vector3) -> bool:
	for camp in VIBELANDIA_CAMPS:
		if Vector2(point.x - camp.x, point.z - camp.y).length() < camp.z:
			return true
	return false


## Le même matériau que le modèle, avec la variante de couleurs de Vibelandia : un matériau par matériau d'origine.
func _dye(model: Node3D, materials: Dictionary) -> void:
	if not vibelandia_colors:
		return
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if not source:
				continue
			if not materials.has(source):
				var dyed := source.duplicate() as StandardMaterial3D
				dyed.albedo_texture = vibelandia_colors
				materials[source] = dyed
			mesh.set_surface_override_material(surface, materials[source])


## Le volcan gronde : les corbeaux perchés s'envolent tous, et ceux qui volent battent des ailes un moment.
func startle() -> void:
	for crow in _crows:
		crow.timer = 0.0
		if crow.perched:
			crow.perched = false
			crow.angle = atan2(crow.position.z - FLOCK_CENTER.z, crow.position.x - FLOCK_CENTER.x)


## Haut d'un modèle, au milieu de sa boîte : le sommet d'une croix.
func _top_of(model: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var part: AABB = mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return Vector3(box.get_center().x, box.end.y + 0.01, box.get_center().z)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	for index in _flags.size():
		# Le vent fait tourner la bannière sur sa hampe et l'incline un peu, par rafales.
		var gust := 0.6 + 0.4 * sin(_time * 0.37 + index)
		var sway := Basis(Vector3.UP, sin(_time * 1.3 + index * 1.7) * 0.07 * gust)
		var lean := Basis(Vector3.FORWARD, sin(_time * 2.1 + index) * 0.02 * gust)
		_flags[index].basis = _flag_bases[index] * sway * lean
	for crow in _crows:
		_update_crow(crow, delta)


func _update_crow(crow: Crow, delta: float) -> void:
	crow.timer += delta
	if crow.perched:
		crow.fold()
		# Le corbeau perché tourne la tête de temps en temps, et s'envole si le joueur approche.
		crow.head.rotation.y = sin(crow.timer * 0.7 + crow.phase) * 0.6
		if player and player.global_position.distance_to(crow.global_position) < ALARM_DISTANCE:
			crow.perched = false
			crow.timer = 0.0
			crow.angle = atan2(crow.position.z - FLOCK_CENTER.z, crow.position.x - FLOCK_CENTER.x)
		return
	var target: Vector3
	if crow.perch != Vector3.ZERO and crow.timer > RETURN_DELAY and player \
			and player.global_position.distance_to(crow.perch) > ALARM_DISTANCE * 2.0:
		# Retour au perchoir, en planant.
		target = crow.perch
		if crow.position.distance_to(target) < 0.2:
			crow.position = target
			crow.perched = true
			crow.timer = 0.0
			return
	else:
		crow.angle += crow.speed * delta
		target = FLOCK_CENTER + Vector3(cos(crow.angle) * crow.radius,
			crow.altitude + sin(crow.timer * 0.5 + crow.phase) * 1.2, sin(crow.angle) * crow.radius)
	var heading := target - crow.position
	var step := minf(heading.length(), (7.0 if crow.timer < 3.0 else 4.5) * delta)
	if heading.length() > 0.01:
		crow.position += heading.normalized() * step
		var look := Vector2(heading.x, heading.z)
		if look.length() > 0.01:
			crow.rotation.y = lerp_angle(crow.rotation.y, atan2(-look.x, -look.y), minf(1.0, delta * 4.0))
	# Battements d'ailes, puis de longs vols planés.
	var flapping := sin(crow.timer * 0.6 + crow.phase) > -0.3 or crow.timer < 3.0
	crow.flap(crow.timer * 11.0 if flapping else 0.0, 0.7 if flapping else 0.12)


class Crow:
	extends Node3D
	## Corbeau en formes simples : corps, tête, bec, queue et deux ailes articulées.

	var head: Node3D
	var wings: Array[Node3D] = []
	var radius := 10.0
	var speed := 0.3
	var angle := 0.0
	var altitude := 0.0
	var phase := 0.0
	var timer := 0.0
	var perched := false
	var perch := Vector3.ZERO

	func _init(feathers: Material, beak: Material) -> void:
		scale = Vector3.ONE * 1.4
		_box(self, Vector3(0.13, 0.12, 0.32), Vector3(0.0, 0.08, 0.0), feathers)
		_box(self, Vector3(0.11, 0.02, 0.16), Vector3(0.0, 0.08, 0.22), feathers)
		head = Node3D.new()
		head.position = Vector3(0.0, 0.14, -0.17)
		add_child(head)
		_box(head, Vector3(0.09, 0.09, 0.1), Vector3.ZERO, feathers)
		_box(head, Vector3(0.025, 0.025, 0.08), Vector3(0.0, -0.01, -0.08), beak)
		for side in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 0.06, 0.11, -0.02)
			add_child(pivot)
			_box(pivot, Vector3(0.3, 0.012, 0.17), Vector3(side * 0.15, 0.0, 0.02), feathers)
			wings.append(pivot)

	func flap(time: float, amplitude: float) -> void:
		for index in wings.size():
			var side := -1.0 if index == 0 else 1.0
			wings[index].rotation.z = side * (sin(time) * amplitude + 0.1)

	## Ailes repliées le long du corps, pour un corbeau posé.
	func fold() -> void:
		for index in wings.size():
			var side := -1.0 if index == 0 else 1.0
			wings[index].rotation.z = -side * 1.35

	func _box(parent: Node3D, size: Vector3, offset: Vector3, material: Material) -> void:
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = material
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.position = offset
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
