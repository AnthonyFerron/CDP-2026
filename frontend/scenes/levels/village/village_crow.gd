class_name VillageCrow
extends Node3D
## Corbeau du Village : il guette ou picore sur son perchoir, s'envole en battant des ailes quand le joueur approche,
## et revient se poser plus tard, quand le joueur est loin. Formes simples, sans collision.

## Penché pour picorer au sol, ou droit sur un mur.
@export var pecking := false
@export var flee_distance := 6.5
@export var return_distance := 24.0

const FEATHERS := Color(0.05, 0.05, 0.07)
const BEAK := Color(0.17, 0.16, 0.15)
const FLIGHT_TIME := 4.0

enum State { PERCHED, FLYING, AWAY }

static var _parts := {}

var _state := State.PERCHED
var _time := 0.0
var _timer := 0.0
var _velocity := Vector3.ZERO
var _home: Transform3D
var _body: Node3D
var _head: Node3D
var _wings: Array[Node3D] = []


func _ready() -> void:
	_home = transform
	_time = randf() * 10.0
	_body = Node3D.new()
	add_child(_body)
	_part(_body, "body", Vector3(0, 0.13, 0), Vector3(1.0, 0.85, 1.7))
	_part(_body, "tail", Vector3(0, 0.16, -0.17), Vector3.ONE, Vector3(-20, 0, 0))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.2, 0.12)
	_body.add_child(_head)
	_part(_head, "head", Vector3.ZERO, Vector3(1.0, 1.0, 1.1))
	_part(_head, "beak", Vector3(0, -0.005, 0.07), Vector3.ONE, Vector3(90, 0, 0))
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.06, 0.17, 0.0)
		_body.add_child(wing)
		_part(wing, "wing", Vector3(side * 0.09, 0, 0), Vector3.ONE)
		wing.rotation.z = -side * 0.25
		_wings.append(wing)
	if pecking:
		_body.rotation.x = deg_to_rad(30.0)


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
			var flap := sin(_time * 22.0) * 0.9
			for index in _wings.size():
				_wings[index].rotation.z = flap * (1.0 if index == 0 else -1.0)
			if _timer <= 0.0:
				hide()
				_state = State.AWAY
				_timer = randf_range(20.0, 40.0)
		State.AWAY:
			_timer -= delta
			if _timer <= 0.0 and (camera == null or camera.global_position.distance_to(_home.origin) > return_distance):
				transform = _home
				_body.rotation.x = deg_to_rad(30.0) if pecking else 0.0
				for index in _wings.size():
					_wings[index].rotation.z = 0.25 if index == 0 else -0.25
				show()
				_state = State.PERCHED


## S'envole à l'opposé du joueur, en montant.
func _take_off(from: Vector3) -> void:
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	away = away.rotated(Vector3.UP, randf_range(-0.6, 0.6))
	_velocity = away * randf_range(5.0, 6.5) + Vector3.UP * 2.5
	look_at(global_position + _velocity, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)
	_body.rotation.x = 0.0
	_timer = FLIGHT_TIME
	_state = State.FLYING


func _part(parent: Node3D, kind: String, at: Vector3, stretch: Vector3, degrees := Vector3.ZERO) -> void:
	if _parts.is_empty():
		var feathers := StandardMaterial3D.new()
		feathers.albedo_color = FEATHERS
		feathers.roughness = 0.6
		var beak := StandardMaterial3D.new()
		beak.albedo_color = BEAK
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
		bill.bottom_radius = 0.018
		bill.height = 0.07
		bill.radial_segments = 5
		bill.material = beak
		var tail := BoxMesh.new()
		tail.size = Vector3(0.09, 0.015, 0.14)
		tail.material = feathers
		var wing := BoxMesh.new()
		wing.size = Vector3(0.18, 0.012, 0.12)
		wing.material = feathers
		_parts = {"body": body, "head": head, "beak": bill, "tail": tail, "wing": wing}
	var mesh := MeshInstance3D.new()
	mesh.mesh = _parts[kind]
	mesh.position = at
	mesh.scale = stretch
	mesh.rotation_degrees = degrees
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
