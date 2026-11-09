class_name VillageCrow
extends Node3D
## Corbeau du Village : il guette ou picore sur son perchoir, les ailes repliées le long du corps, s'envole en battant
## des ailes quand le joueur approche, et revient se poser plus tard, quand le joueur est loin. Formes simples, sans
## collision. Il regarde vers +Z.

## Penché pour picorer au sol, ou droit sur un mur.
@export var pecking := false
@export var flee_distance := 6.5
@export var return_distance := 24.0

const FEATHERS := Color(0.05, 0.05, 0.07)
const BEAK := Color(0.55, 0.52, 0.47)
const EYE := Color(0.85, 0.75, 0.35)
const LEGS := Color(0.2, 0.19, 0.18)
const FLIGHT_TIME := 4.0
## Ailes ouvertes en vol : relevées en V, comme un oiseau qui plane, plutôt qu'à plat en croix.
const DIHEDRAL := 0.35

enum State { PERCHED, FLYING, AWAY }

static var _meshes := {}

var _state := State.PERCHED
var _time := 0.0
var _timer := 0.0
var _velocity := Vector3.ZERO
var _home: Transform3D
var _body: Node3D
var _head: Node3D
var _wings: Array[Node3D] = []
var _perched: MeshInstance3D
var _flying: MeshInstance3D


func _ready() -> void:
	_home = transform
	_time = randf() * 10.0
	if _meshes.is_empty():
		_meshes = _build_meshes()
	_body = Node3D.new()
	add_child(_body)
	# Le corps posé (ailes repliées le long des flancs, pattes) et le corps en vol (sans elles) : un maillage chacun.
	_perched = VillageMesh.instance(_meshes["perched"], _body)
	_flying = VillageMesh.instance(_meshes["flying"], _body)
	_head = Node3D.new()
	_head.position = Vector3(0, 0.205, 0.12)
	_body.add_child(_head)
	VillageMesh.instance(_meshes["head"], _head)
	for side in [-1.0, 1.0]:
		# Aile ouverte, cachée tant que l'oiseau est posé.
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.05, 0.16, 0.0)
		_body.add_child(wing)
		var blade := VillageMesh.instance(_meshes["wing"], wing)
		blade.position = Vector3(side * 0.11, 0, -0.01)
		wing.hide()
		_wings.append(wing)
	_settle()


func _process(delta: float) -> void:
	_time += delta
	var camera := get_viewport().get_camera_3d()
	match _state:
		State.PERCHED:
			# Petits coups de bec ou tête qui guette, de loin en loin.
			var beat := fmod(_time, 3.1)
			_head.rotation.x = (0.7 * sin(beat * 9.0) if beat < 0.35 else 0.0) if pecking else 0.0
			_head.rotation.y = 0.5 * sin(_time * 0.7) if not pecking else 0.0
			if camera and camera.global_position.distance_to(global_position) < flee_distance:
				_take_off(camera.global_position)
		State.FLYING:
			_timer -= delta
			_velocity.y += 1.2 * delta
			global_position += _velocity * delta
			var flap := sin(_time * 22.0) * 0.8
			_wings[0].rotation.z = -(DIHEDRAL + flap)
			_wings[1].rotation.z = DIHEDRAL + flap
			if _timer <= 0.0:
				hide()
				_state = State.AWAY
				_timer = randf_range(20.0, 40.0)
		State.AWAY:
			_timer -= delta
			if _timer <= 0.0 and (camera == null or camera.global_position.distance_to(_home.origin) > return_distance):
				transform = _home
				_settle()
				show()
				_state = State.PERCHED


## Posé : ailes repliées, pattes visibles, penché s'il picore.
func _settle() -> void:
	_body.rotation.x = deg_to_rad(30.0) if pecking else 0.0
	for wing in _wings:
		wing.hide()
	_perched.show()
	_flying.hide()


## S'envole à l'opposé du joueur, en montant, ailes ouvertes et pattes rentrées.
func _take_off(from: Vector3) -> void:
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	away = away.rotated(Vector3.UP, randf_range(-0.6, 0.6))
	_velocity = away * randf_range(5.0, 6.5) + Vector3.UP * 2.5
	look_at(global_position + _velocity, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)
	_body.rotation.x = 0.0
	for wing in _wings:
		wing.show()
	_perched.hide()
	_flying.show()
	_timer = FLIGHT_TIME
	_state = State.FLYING


static func release() -> void:
	_meshes = {}


## Les formes du corbeau, fondues par partie (VillageMesh) : posé, il coûte deux appels de dessin au lieu de dix.
static func _build_meshes() -> Dictionary:
	var body := [VillageMesh.sphere(0.08), VillageMesh.at(Vector3(0, 0.13, 0), Vector3.ZERO, Vector3(1.0, 0.9, 1.75)), FEATHERS]
	var tail := [VillageMesh.box(Vector3(0.09, 0.015, 0.17)), VillageMesh.at(Vector3(0, 0.12, -0.2), Vector3(-25, 0, 0)), FEATHERS]
	var perched := [body, tail]
	for side in [-1.0, 1.0]:
		# Aile repliée, couchée le long du flanc, et patte.
		perched.append([VillageMesh.box(Vector3(0.03, 0.075, 0.2)),
			VillageMesh.at(Vector3(side * 0.068, 0.145, -0.035), Vector3(-10, 0, side * 6)), FEATHERS])
		perched.append([VillageMesh.box(Vector3(0.012, 0.07, 0.012)), VillageMesh.at(Vector3(side * 0.028, 0.035, 0.01)), LEGS])
	var head := [
		[VillageMesh.sphere(0.055, 8, 4), VillageMesh.at(Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 1.15)), FEATHERS],
		[VillageMesh.cone(0.02, 0.09), VillageMesh.at(Vector3(0, -0.012, 0.085), Vector3(90, 0, 0)), BEAK],
	]
	for side in [-1.0, 1.0]:
		head.append([VillageMesh.sphere(0.011, 6, 3), VillageMesh.at(Vector3(side * 0.04, 0.012, 0.028)), EYE])
	return {
		"perched": VillageMesh.merge(perched),
		"flying": VillageMesh.merge([body, tail]),
		"head": VillageMesh.merge(head),
		"wing": VillageMesh.merge([[VillageMesh.box(Vector3(0.22, 0.012, 0.13)), Transform3D.IDENTITY, FEATHERS]]),
	}
