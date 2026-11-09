class_name VillageCat
extends Node3D
## Chat resté au village : il va et vient entre quelques points, à pas comptés, s'arrête un moment, la queue qui
## balance, puis repart. Formes simples, sans collision : il ne gêne jamais le joueur.

@export var coat := Color(0.07, 0.07, 0.08)
## Points de passage, en coordonnées du monde, sur un sol plat.
@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var speed := 0.55

## Maillages partagés par les chats de même pelage.
static var _shared := {}

var _target := 0
var _pause := 0.0
var _time := 0.0
var _legs: Array[Node3D] = []
var _tail: Node3D
var _body: Node3D


func _ready() -> void:
	_time = randf() * 5.0
	var meshes := _meshes(coat)
	_body = Node3D.new()
	add_child(_body)
	# Le corps, la tête, les oreilles et les yeux ne bougent pas les uns par rapport aux autres : un seul maillage.
	VillageMesh.instance(meshes["body"], _body)
	for corner: Vector2 in [Vector2(-0.05, 0.11), Vector2(0.05, 0.11), Vector2(-0.05, -0.1), Vector2(0.05, -0.1)]:
		var hip := Node3D.new()
		hip.position = Vector3(corner.x, 0.16, corner.y)
		_body.add_child(hip)
		VillageMesh.instance(meshes["leg"], hip)
		_legs.append(hip)
	# La queue part de l'arrière du corps (son pivot est dans le corps) et se dresse vers l'arrière : posée plus haut
	# et penchée vers le bas, elle flottait au-dessus de la croupe.
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.22, -0.14)
	_body.add_child(_tail)
	VillageMesh.instance(meshes["tail"], _tail)
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


static func release() -> void:
	_shared = {}


## Les formes du chat, fondues par partie (VillageMesh) et partagées par les chats de même pelage.
static func _meshes(fur: Color) -> Dictionary:
	var key := fur.to_html()
	if _shared.has(key):
		return _shared[key]
	var eye := Color(0.6, 0.55, 0.12)
	var head := Vector3(0, 0.29, 0.19)
	var body := [
		[VillageMesh.sphere(0.1), VillageMesh.at(Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(0.85, 0.8, 1.7)), fur],
		[VillageMesh.sphere(0.075), VillageMesh.at(head, Vector3.ZERO, Vector3(1.0, 0.92, 1.0)), fur],
	]
	for side in [-1.0, 1.0]:
		body.append([VillageMesh.cone(0.025, 0.06, 4), VillageMesh.at(head + Vector3(side * 0.04, 0.08, -0.01)), fur])
		body.append([VillageMesh.sphere(0.011, 6, 3), VillageMesh.at(head + Vector3(side * 0.032, 0.015, 0.065)), eye])
	var tilt := deg_to_rad(35.0)
	var meshes := {
		"body": VillageMesh.merge(body),
		"leg": VillageMesh.merge([[VillageMesh.box(Vector3(0.035, 0.16, 0.035)), VillageMesh.at(Vector3(0, -0.08, 0)), fur]]),
		"tail": VillageMesh.merge([[VillageMesh.box(Vector3(0.03, 0.03, 0.28)),
			VillageMesh.at(Vector3(0, 0.12 * sin(tilt), -0.12 * cos(tilt)), Vector3(35, 0, 0)), fur]]),
	}
	_shared[key] = meshes
	return meshes
