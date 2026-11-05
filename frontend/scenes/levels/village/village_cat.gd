class_name VillageCat
extends Node3D
## Chat resté au village : il va et vient entre quelques points, à pas comptés, s'arrête un moment, la queue qui
## balance, puis repart. Formes simples, sans collision : il ne gêne jamais le joueur.

@export var coat := Color(0.07, 0.07, 0.08)
## Points de passage, en coordonnées du monde, sur un sol plat.
@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var speed := 0.55

var _target := 0
var _pause := 0.0
var _time := 0.0
var _legs: Array[Node3D] = []
var _tail: Node3D
var _body: Node3D


func _ready() -> void:
	_time = randf() * 5.0
	var fur := StandardMaterial3D.new()
	fur.albedo_color = coat
	fur.roughness = 1.0
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.6, 0.55, 0.12)
	eye.emission_enabled = true
	eye.emission = Color(0.45, 0.4, 0.06)
	_body = Node3D.new()
	add_child(_body)
	_sphere(_body, fur, 0.1, Vector3(0, 0.2, 0), Vector3(0.85, 0.8, 1.7))
	var head := Node3D.new()
	head.position = Vector3(0, 0.29, 0.19)
	_body.add_child(head)
	_sphere(head, fur, 0.075, Vector3.ZERO, Vector3(1.0, 0.92, 1.0))
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.025
		cone.height = 0.06
		cone.radial_segments = 4
		cone.material = fur
		ear.mesh = cone
		ear.position = Vector3(side * 0.04, 0.08, -0.01)
		head.add_child(ear)
		_sphere(head, eye, 0.011, Vector3(side * 0.032, 0.015, 0.065), Vector3.ONE)
	for corner: Vector2 in [Vector2(-0.05, 0.11), Vector2(0.05, 0.11), Vector2(-0.05, -0.1), Vector2(0.05, -0.1)]:
		var hip := Node3D.new()
		hip.position = Vector3(corner.x, 0.16, corner.y)
		_body.add_child(hip)
		_box(hip, fur, Vector3(0.035, 0.16, 0.035), Vector3(0, -0.08, 0))
		_legs.append(hip)
	# La queue part de l'arrière du corps (son pivot est dans le corps) et se dresse vers l'arrière : posée plus haut
	# et penchée vers le bas, elle flottait au-dessus de la croupe.
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.22, -0.14)
	_body.add_child(_tail)
	_box(_tail, fur, Vector3(0.03, 0.03, 0.28), Vector3(0, 0.12 * sin(deg_to_rad(35.0)), -0.12 * cos(deg_to_rad(35.0))),
		Vector3(35, 0, 0))
	if not waypoints.is_empty():
		global_position = waypoints[0]
		_target = 1 % waypoints.size()


func _process(delta: float) -> void:
	_time += delta
	_tail.rotation.y = 0.5 * sin(_time * 1.6)
	if waypoints.size() < 2:
		return
	if _pause > 0.0:
		_pause -= delta
		for leg in _legs:
			leg.rotation.x = lerpf(leg.rotation.x, 0.0, 0.2)
		_body.position.y = 0.0
		return
	var goal := waypoints[_target]
	var offset := goal - global_position
	offset.y = 0.0
	if offset.length() < 0.05:
		_target = (_target + 1) % waypoints.size()
		_pause = randf_range(3.0, 8.0)
		return
	var heading := atan2(offset.x, offset.z)
	rotation.y = lerp_angle(rotation.y, heading, 4.0 * delta)
	global_position += offset.normalized() * minf(speed * delta, offset.length())
	# Pas alternés : pattes avant gauche et arrière droite ensemble.
	var stride := sin(_time * 9.0) * 0.5
	for index in _legs.size():
		_legs[index].rotation.x = stride * (1.0 if index in [0, 3] else -1.0)
	_body.position.y = absf(sin(_time * 9.0)) * 0.012


func _sphere(parent: Node3D, material: Material, radius: float, at: Vector3, stretch: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = stretch
	parent.add_child(instance)


func _box(parent: Node3D, material: Material, size: Vector3, at: Vector3, degrees := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation_degrees = degrees
	parent.add_child(instance)
