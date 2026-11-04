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
var _folded: Array[Node3D] = []
var _legs: Array[Node3D] = []


func _ready() -> void:
	_home = transform
	_time = randf() * 10.0
	_body = Node3D.new()
	add_child(_body)
	_part(_body, "body", Vector3(0, 0.13, 0), Vector3(1.0, 0.9, 1.75))
	_part(_body, "tail", Vector3(0, 0.12, -0.2), Vector3.ONE, Vector3(-25, 0, 0))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.205, 0.12)
	_body.add_child(_head)
	_part(_head, "head", Vector3.ZERO, Vector3(1.0, 1.0, 1.15))
	_part(_head, "beak", Vector3(0, -0.012, 0.085), Vector3.ONE, Vector3(90, 0, 0))
	for side in [-1.0, 1.0]:
		_part(_head, "eye", Vector3(side * 0.04, 0.012, 0.028), Vector3.ONE)
		# Aile repliée, couchée le long du flanc.
		_folded.append(_part(_body, "folded", Vector3(side * 0.068, 0.145, -0.035), Vector3.ONE, Vector3(-10, 0, side * 6)))
		# Aile ouverte, cachée tant que l'oiseau est posé.
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.05, 0.16, 0.0)
		_body.add_child(wing)
		_part(wing, "wing", Vector3(side * 0.11, 0, -0.01), Vector3.ONE)
		wing.hide()
		_wings.append(wing)
		_legs.append(_part(_body, "leg", Vector3(side * 0.028, 0.035, 0.01), Vector3.ONE))
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
	for part in _folded + _legs:
		part.show()


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
	for part in _folded + _legs:
		part.hide()
	_timer = FLIGHT_TIME
	_state = State.FLYING


func _part(parent: Node3D, kind: String, at: Vector3, stretch: Vector3, degrees := Vector3.ZERO) -> MeshInstance3D:
	if _meshes.is_empty():
		_meshes = _build_meshes()
	var mesh := MeshInstance3D.new()
	mesh.mesh = _meshes[kind]
	mesh.position = at
	mesh.scale = stretch
	mesh.rotation_degrees = degrees
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


static func _build_meshes() -> Dictionary:
	var feathers := StandardMaterial3D.new()
	feathers.albedo_color = FEATHERS
	feathers.roughness = 0.55
	var beak := StandardMaterial3D.new()
	beak.albedo_color = BEAK
	beak.roughness = 0.5
	var eye := StandardMaterial3D.new()
	eye.albedo_color = EYE
	eye.emission_enabled = true
	eye.emission = EYE * 0.4
	var legs := StandardMaterial3D.new()
	legs.albedo_color = LEGS
	var body := SphereMesh.new()
	body.radius = 0.08
	body.height = 0.16
	body.radial_segments = 10
	body.rings = 5
	body.material = feathers
	var head := SphereMesh.new()
	head.radius = 0.055
	head.height = 0.11
	head.radial_segments = 8
	head.rings = 4
	head.material = feathers
	var bill := CylinderMesh.new()
	bill.top_radius = 0.0
	bill.bottom_radius = 0.02
	bill.height = 0.09
	bill.radial_segments = 6
	bill.material = beak
	var dot := SphereMesh.new()
	dot.radius = 0.011
	dot.height = 0.022
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = eye
	var tail := BoxMesh.new()
	tail.size = Vector3(0.09, 0.015, 0.17)
	tail.material = feathers
	var folded := BoxMesh.new()
	folded.size = Vector3(0.03, 0.075, 0.2)
	folded.material = feathers
	var wing := BoxMesh.new()
	wing.size = Vector3(0.22, 0.012, 0.13)
	wing.material = feathers
	var leg := BoxMesh.new()
	leg.size = Vector3(0.012, 0.07, 0.012)
	leg.material = legs
	return {"body": body, "head": head, "beak": bill, "eye": dot, "tail": tail, "folded": folded, "wing": wing, "leg": leg}
