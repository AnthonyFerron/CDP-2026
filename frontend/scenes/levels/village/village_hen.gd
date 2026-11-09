class_name VillageHen
extends Node3D
## Poule échappée du poulailler vidé : elle va d'un point à l'autre de son coin, à petits pas, la tête qui avance et
## recule, picore, s'arrête pour regarder autour d'elle, et détale en caquetant quand le joueur s'approche trop. Formes
## simples fondues en deux maillages (le corps, la tête), sans collision : elle ne gêne jamais le joueur. Elle regarde
## vers +Z.

@export var plumage := Color(0.9, 0.86, 0.78)
## Chemin de son coin, en coordonnées du monde, sur un sol plat : elle va d'un point à son voisin, dans un sens ou
## dans l'autre, sans jamais couper au travers d'une clôture ou d'un tas de bois entre deux points éloignés.
@export var waypoints: PackedVector3Array = PackedVector3Array()
## Point du chemin où elle se trouve au chargement (-1 : au hasard).
@export var start := -1
@export var speed := 0.42
@export var flee_distance := 2.4
## Au-delà, elle ne bouge plus (personne ne la voit) : rien n'est calculé.
@export var awake_distance := 45.0

const COMB := Color(0.75, 0.1, 0.07)
const BEAK := Color(0.85, 0.6, 0.18)
const LEGS := Color(0.82, 0.58, 0.2)
const EYE := Color(0.05, 0.04, 0.03)
const RUN_SPEED := 2.1

enum State { IDLE, WALK, PECK, FLEE }

## Maillages partagés par les poules de même plumage : corps et tête.
static var _bodies := {}
static var _heads := {}

var _state := State.IDLE
var _time := 0.0
var _timer := 0.0
var _target := Vector3.ZERO
## Point visé, et dernier point atteint : entre les deux, elle est sur le segment qui les joint.
var _index := 0
var _from := 0
var _body: Node3D
var _head: Node3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(name) + hash(waypoints)
	_time = _rng.randf() * 10.0
	_body = Node3D.new()
	add_child(_body)
	VillageMesh.instance(_body_mesh(plumage), _body, awake_distance)
	_head = Node3D.new()
	_head.position = Vector3(0, 0.3, 0.1)
	_body.add_child(_head)
	VillageMesh.instance(_head_mesh(plumage), _head, awake_distance)
	if not waypoints.is_empty():
		_index = start if start >= 0 and start < waypoints.size() else _rng.randi() % waypoints.size()
		_from = _index
		global_position = waypoints[_index]
	_timer = _rng.randf_range(0.5, 3.0)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var distance := camera.global_position.distance_to(global_position) if camera else INF
	if distance > awake_distance:
		return
	_time += delta
	_timer -= delta
	if distance < flee_distance and _state != State.FLEE and waypoints.size() > 1:
		_flee(camera.global_position)
	match _state:
		State.IDLE:
			# Elle tourne la tête par à-coups, comme les poules.
			_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.2)
			_head.rotation.x = lerpf(_head.rotation.x, 0.0, 0.3)
			if fmod(_time, 0.7) < delta:
				_head.rotation.y = _rng.randf_range(-0.7, 0.7)
			if _timer <= 0.0:
				_next()
		State.PECK:
			_head.rotation.y = 0.0
			_body.rotation.x = lerpf(_body.rotation.x, 0.35, 0.15)
			var beat := fmod(_time, 0.55)
			_head.rotation.x = 1.0 if beat < 0.12 else 0.35
			if _timer <= 0.0:
				_state = State.IDLE
				_timer = _rng.randf_range(1.0, 3.0)
		State.WALK, State.FLEE:
			_body.rotation.x = lerpf(_body.rotation.x, 0.12 if _state == State.FLEE else 0.0, 0.2)
			_head.rotation = Vector3.ZERO
			var offset := _target - global_position
			offset.y = 0.0
			var pace := RUN_SPEED if _state == State.FLEE else speed
			if offset.length() < 0.05:
				_from = _index
				if _state == State.FLEE or _rng.randf() < 0.6:
					_state = State.PECK
					_timer = _rng.randf_range(2.0, 5.0)
				else:
					_state = State.IDLE
					_timer = _rng.randf_range(1.5, 4.0)
				_body.position = Vector3.ZERO
				_body.rotation.z = 0.0
				_head.position.z = 0.1
				return
			rotation.y = lerp_angle(rotation.y, atan2(offset.x, offset.z), (12.0 if _state == State.FLEE else 5.0) * delta)
			var step := minf(pace * delta, offset.length())
			global_position += offset.normalized() * step
			global_position.y = lerpf(global_position.y, _target.y, minf(1.0, step / maxf(offset.length(), 0.01)))
			# La tête avance et recule à chaque pas ; le corps se dandine.
			var cadence := 14.0 if _state == State.FLEE else 8.0
			_head.position.z = 0.1 + 0.025 * sin(_time * cadence)
			_body.position.y = absf(sin(_time * cadence)) * 0.015
			_body.rotation.z = 0.08 * sin(_time * cadence * 0.5)


func _next() -> void:
	if waypoints.size() < 2:
		_state = State.PECK
		_timer = _rng.randf_range(2.0, 5.0)
		return
	var step := 1 if _rng.randf() < 0.5 else -1
	if _index + step < 0 or _index + step >= waypoints.size():
		step = -step
	_go(_index + step, State.WALK)


## Détale vers le point le plus loin du joueur : l'un des deux bouts du segment où elle marche, ou, arrêtée, l'un de
## ses deux voisins.
func _flee(from: Vector3) -> void:
	var best := -1
	var choices := [_from, _index] if _from != _index else [_index - 1, _index + 1]
	for index: int in choices:
		if index < 0 or index >= waypoints.size():
			continue
		if best < 0 or waypoints[index].distance_squared_to(from) > waypoints[best].distance_squared_to(from):
			best = index
	_go(best, State.FLEE)


func _go(index: int, state: State) -> void:
	_index = index
	var jitter := Vector3(_rng.randf_range(-0.25, 0.25), 0.0, _rng.randf_range(-0.25, 0.25))
	_target = waypoints[index] + jitter
	_state = state


static func release() -> void:
	_bodies = {}
	_heads = {}


static func _body_mesh(color: Color) -> ArrayMesh:
	var key := color.to_html()
	if _bodies.has(key):
		return _bodies[key]
	var dark := color.darkened(0.25)
	var parts := [
		[VillageMesh.sphere(0.13), VillageMesh.at(Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(0.85, 0.8, 1.15)), color],
		# Le cou, qui monte vers la tête.
		[VillageMesh.sphere(0.06, 8, 4), VillageMesh.at(Vector3(0, 0.27, 0.08), Vector3(-20, 0, 0), Vector3(0.95, 1.4, 0.95)), color],
		# La queue, deux plumes dressées vers l'arrière.
		[VillageMesh.box(Vector3(0.05, 0.15, 0.09)), VillageMesh.at(Vector3(0, 0.3, -0.13), Vector3(-30, 0, 0)), dark],
		[VillageMesh.box(Vector3(0.035, 0.12, 0.07)), VillageMesh.at(Vector3(0, 0.27, -0.16), Vector3(-55, 0, 0)), dark],
	]
	for side in [-1.0, 1.0]:
		# Les ailes repliées contre les flancs.
		parts.append([VillageMesh.sphere(0.09, 8, 4), VillageMesh.at(Vector3(side * 0.095, 0.21, -0.02), Vector3(-8, 0, 0),
			Vector3(0.35, 0.7, 1.25)), dark])
		parts.append([VillageMesh.box(Vector3(0.018, 0.12, 0.018)), VillageMesh.at(Vector3(side * 0.04, 0.065, 0.01)), LEGS])
		parts.append([VillageMesh.box(Vector3(0.045, 0.01, 0.07)), VillageMesh.at(Vector3(side * 0.04, 0.005, 0.03)), LEGS])
	var mesh := VillageMesh.merge(parts)
	_bodies[key] = mesh
	return mesh


static func _head_mesh(color: Color) -> ArrayMesh:
	var key := color.to_html()
	if _heads.has(key):
		return _heads[key]
	var parts := [
		[VillageMesh.sphere(0.058, 8, 4), VillageMesh.at(Vector3(0, 0.04, 0.025)), color],
		[VillageMesh.box(Vector3(0.016, 0.045, 0.07)), VillageMesh.at(Vector3(0, 0.1, 0.03)), COMB],
		[VillageMesh.sphere(0.02, 6, 3), VillageMesh.at(Vector3(0, -0.01, 0.07), Vector3.ZERO, Vector3(0.6, 1.4, 0.6)), COMB],
		[VillageMesh.cone(0.017, 0.045), VillageMesh.at(Vector3(0, 0.035, 0.095), Vector3(90, 0, 0)), BEAK],
	]
	for side in [-1.0, 1.0]:
		parts.append([VillageMesh.sphere(0.009, 6, 3), VillageMesh.at(Vector3(side * 0.045, 0.05, 0.055)), EYE])
	var mesh := VillageMesh.merge(parts)
	_heads[key] = mesh
	return mesh
