class_name VillageVane
extends Node3D
## Girouette de fer sur le faîte de la mairie : sa flèche et son coq tournent au gré du vent du soir, par à-coups,
## autour du cap où souffle le vent. Le pied, la croix des quatre points et la boule restent fixes. Formes simples fondues
## en deux maillages (le pied et ce qui tourne), sans collision, hors de portée du joueur.

## Cap moyen du vent, en degrés autour de y, et amplitude de ses sautes.
@export var heading := 70.0
@export var swing := 28.0

const IRON := Color(0.1, 0.09, 0.085)
const GILT := Color(0.62, 0.45, 0.16)

var _time := 0.0
var _rotor: Node3D


func _ready() -> void:
	_time = 13.0
	VillageMesh.instance(_stand(), self)
	_rotor = Node3D.new()
	_rotor.position = Vector3(0, 1.05, 0)
	add_child(_rotor)
	VillageMesh.instance(_vane(), _rotor)
	_rotor.rotation.y = deg_to_rad(heading)


func _process(delta: float) -> void:
	_time += delta
	# Deux vents mêlés, lents, et une rafale de temps en temps.
	var gust := 0.6 * sin(_time * 0.37) + 0.3 * sin(_time * 1.1 + 1.7) + 0.1 * sin(_time * 3.3)
	_rotor.rotation.y = deg_to_rad(heading + swing * gust)


## Le pied : la tige plantée dans le faîte, la croix des quatre points cardinaux, et leurs boules dorées.
static func _stand() -> ArrayMesh:
	var parts := [
		[VillageMesh.box(Vector3(0.05, 1.3, 0.05)), VillageMesh.at(Vector3(0, 0.6, 0)), IRON],
		[VillageMesh.sphere(0.07, 8, 4), VillageMesh.at(Vector3(0, 0.62, 0)), GILT],
		[VillageMesh.box(Vector3(0.7, 0.03, 0.03)), VillageMesh.at(Vector3(0, 0.7, 0)), IRON],
		[VillageMesh.box(Vector3(0.03, 0.03, 0.7)), VillageMesh.at(Vector3(0, 0.7, 0)), IRON],
	]
	for point: Vector3 in [Vector3(0.35, 0.7, 0), Vector3(-0.35, 0.7, 0), Vector3(0, 0.7, 0.35), Vector3(0, 0.7, -0.35)]:
		parts.append([VillageMesh.sphere(0.035, 6, 3), VillageMesh.at(point), GILT])
	return VillageMesh.merge(parts)


## Ce qui tourne : la flèche, sa pointe et son empennage, et le coq dressé dessus, tourné comme elle (vers +Z).
static func _vane() -> ArrayMesh:
	var parts := [
		[VillageMesh.box(Vector3(0.025, 0.025, 1.0)), VillageMesh.at(Vector3(0, 0, 0)), IRON],
		[VillageMesh.cone(0.06, 0.18, 4), VillageMesh.at(Vector3(0, 0, 0.55), Vector3(90, 0, 0), Vector3(1.0, 1.0, 0.35)), IRON],
		[VillageMesh.box(Vector3(0.012, 0.22, 0.22)), VillageMesh.at(Vector3(0, 0, -0.45), Vector3(45, 0, 0)), IRON],
		# Le coq : son corps, sa queue en éventail, son cou, sa tête et sa crête, découpés dans une tôle mince.
		[VillageMesh.box(Vector3(0.015, 0.16, 0.3)), VillageMesh.at(Vector3(0, 0.12, -0.02)), IRON],
		[VillageMesh.box(Vector3(0.015, 0.26, 0.14)), VillageMesh.at(Vector3(0, 0.22, -0.18), Vector3(-25, 0, 0)), IRON],
		[VillageMesh.box(Vector3(0.015, 0.16, 0.07)), VillageMesh.at(Vector3(0, 0.24, 0.1), Vector3(20, 0, 0)), IRON],
		[VillageMesh.box(Vector3(0.015, 0.08, 0.09)), VillageMesh.at(Vector3(0, 0.33, 0.13)), IRON],
		[VillageMesh.box(Vector3(0.015, 0.05, 0.07)), VillageMesh.at(Vector3(0, 0.38, 0.12)), GILT],
		[VillageMesh.box(Vector3(0.015, 0.025, 0.06)), VillageMesh.at(Vector3(0, 0.325, 0.19)), GILT],
		[VillageMesh.box(Vector3(0.012, 0.09, 0.012)), VillageMesh.at(Vector3(0, 0.035, 0.0)), IRON],
	]
	return VillageMesh.merge(parts)
