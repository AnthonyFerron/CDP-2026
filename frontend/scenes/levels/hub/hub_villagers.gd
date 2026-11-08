class_name HubVillagers
extends Node3D
## Après la victoire, les survivants du bunker vivent dans le village : chacun fait sa tournée entre la place du feu,
## le puits, le jardin du roi, sa forge, l'étal du marché ou le château, avec des pauses où il travaille, regarde ou
## attend. Le roi et Merlon restent dans la salle du trône.
##
## Ils ne gênent pas le joueur. En chemin, ils n'ont pas de corps (on ne bute jamais sur un villageois qui marche) et
## s'arrêtent, tournés vers lui, dès qu'il s'approche devant eux : on peut leur parler. À leurs pauses, posées à l'écart
## des chemins et des portes, ils reprennent leur corps, comme dans le bunker.
##
## Coût : cinq nœuds déplacés par image, sans requête physique ; leur hauteur vient du sol maillé (HubTerrain).

## Vitesse de marche (m/s) et de rotation (rad/s).
const SPEED := 1.3
const TURN := 5.0
## Le villageois qui marche s'arrête si le joueur est devant lui à moins de YIELD_RADIUS, n'importe où à moins de
## NEAR, ou s'il le vise (son invite « Parler à … » est affichée) ; il attend tant que le joueur lui parle. Il repart
## quand le joueur s'est éloigné au-delà de RESUME_RADIUS, ou s'est écarté de son chemin depuis PATIENCE secondes.
## Le joueur lit les villageois à 3 m.
const YIELD_RADIUS := 3.2
const NEAR := 1.6
const RESUME_RADIUS := 4.0
const PATIENCE := 1.5
## Animations des modèles Kenney qui bouclent pendant une pause.
const LOOPED: Array[StringName] = [&"idle", &"walk", &"interact-right", &"interact-left", &"pick-up"]
## Attente au feu avant le premier départ, après la cinématique : ils quittent la place l'un après l'autre.
const DEPARTURE := {&"Mira": 2.0, &"Bran": 5.0, &"Tom": 8.0, &"Elda": 12.0, &"Garde": 3.5}

## Tournée de chaque villageois. Une entrée est un point de passage [x, z], ou une pause [x, z, durée, animation,
## x visé, z visé]. La tournée part de son repère au feu (une pause devant le feu), et y revient ; celle du garde
## reprend à LOOP_FROM : il a sa nouvelle garde au château, celle des quatre livres. Les chemins suivent les rues, à
## droite de leur milieu, et passent à l'écart des lanternes et des meubles (vérifié par une sonde, docs/hub-renaissance.md).
const ROUNDS := {
	# Mira, l'éclaireuse : le chemin du château, la ruelle du jardin du roi, la statue de Devlyn, puis l'étang.
	&"Mira": [
		[-5.2, -4.0], [-1.0, -7.0], [0.9, -12.0], [0.9, -44.0], [6.0, -45.6], [28.6, -46.6], [31.0, -51.0], [31.0, -69.6],
		[35.2, -69.6, 9.0, &"idle", 42.0, -70.0],
		[31.6, -69.6], [31.6, -85.4], [38.6, -85.4, 8.0, &"idle", 47.4, -84.8],
		[30.6, -85.4], [30.6, -53.0], [29.0, -48.2], [6.0, -47.0], [-0.9, -43.0], [-0.9, -12.0], [-0.9, -7.6], [-5.4, -4.4],
	],
	# Bran, le forgeron : le chemin du bunker jusqu'à sa forge, au bord de la rivière, où il retravaille.
	&"Bran": [
		[-5.2, -5.6], [-0.8, -7.0], [4.4, -6.4], [10.0, -8.0], [14.0, -6.2], [16.0, -0.8], [46.5, -0.8], [46.6, 8.0],
		[48.6, 14.6, 12.0, &"interact-right", 52.0, 16.0],
		[46.0, 9.0], [46.0, 0.6], [16.0, 0.6], [8.0, 1.6], [5.8, -1.6], [4.4, -6.0], [-0.8, -7.0], [-5.2, -5.4],
	],
	# Tom, l'apprenti : il va regarder le portail du désert, puis boire à la fontaine de la place est.
	&"Tom": [
		[5.6, -5.8], [12.6, -11.4], [30.0, -28.8], [33.3, -28.7, 9.0, &"idle", 38.0, -38.0],
		[30.6, -31.4], [11.4, -12.6], [5.2, -6.4], [6.4, -0.8], [39.5, -0.8], [39.5, 8.6],
		[31.0, 8.6, 7.0, &"interact-left", 30.0, 4.2],
		[39.5, 8.6], [39.5, 0.6], [16.0, 0.6], [8.0, 1.6], [5.8, -1.6],
	],
	# Elda, la tisserande : l'étal du marché, puis une maison de la rue de l'ouest.
	&"Elda": [
		[0.0, -7.0], [-6.4, -6.8], [-11.6, -7.2], [-12.4, -4.4, 10.0, &"interact-left", -15.0, -4.0],
		[-12.2, -7.4], [-15.4, -10.2, 8.0, &"idle", -18.6, -9.0],
		[-11.0, -8.6], [-6.4, -7.2], [0.0, -7.2],
	],
	# Aldric, le garde : il monte au château et garde la porte du donjon, où reposent les quatre livres ; de temps en
	# temps, il va jeter un œil au chemin du village, devant la porterie.
	&"Garde": [
		[5.0, -4.0], [1.2, -8.0], [1.2, -48.0], [1.0, -56.0], [1.2, -62.0],
		[2.6, -68.6, 14.0, &"idle", 2.6, -60.0],
		[0.0, -60.0], [-1.0, -50.0], [-1.0, -46.6], [-3.6, -45.4, 10.0, &"idle", -3.6, -30.0],
		[-0.9, -46.4], [-0.9, -49.0], [0.6, -57.0],
	],
}
## Entrée où la tournée reprend une fois finie (par défaut, le repère au feu).
const LOOP_FROM := {&"Garde": 5}


class Walker:
	var node: Node3D
	var player: AnimationPlayer
	var shape: CollisionShape3D
	## Entrées de la tournée, le repère au feu en premier.
	var entries: Array = []
	var loop_from := 0
	var index := 0
	var wait := 0.0
	var walking := false
	var yielding := false
	## Temps depuis lequel le joueur ne le retient plus, pendant qu'il attend.
	var patience := 0.0
	var animation := &""


@export var terrain: HubTerrain
@export var characters: Node3D
@export var player: Node3D

var _walkers: Array[Walker] = []


func _ready() -> void:
	set_process(false)


## Les villageois quittent la place pour leurs tournées. from_fire : ils sont au feu (fin de la cinématique) et partent
## l'un après l'autre ; sinon (retour au hub après la victoire), chacun est déjà à sa première pause.
func start(from_fire: bool) -> void:
	_walkers.clear()
	for name: StringName in ROUNDS:
		var node := characters.get_node_or_null(String(name)) as Node3D
		if not node:
			continue
		var walker := Walker.new()
		walker.node = node
		walker.player = node.get_node_or_null("Model/AnimationPlayer") as AnimationPlayer
		walker.shape = node.get_node_or_null("Body/CollisionShape3D") as CollisionShape3D
		var home := node.global_position
		walker.entries = [[home.x, home.z, 6.0, &"idle", 0.0, 0.0]] + ROUNDS[name]
		walker.loop_from = LOOP_FROM.get(name, 0)
		if from_fire:
			walker.index = 0
			walker.wait = DEPARTURE.get(name, 4.0)
		else:
			walker.index = _first_pause(walker.entries)
			var entry: Array = walker.entries[walker.index]
			_place(walker, Vector2(entry[0], entry[1]))
			walker.wait = 2.0 + float(walker.index)
		_pause(walker)
		_walkers.append(walker)
	for walker in _walkers:
		if walker.player:
			for animation_name in LOOPED:
				var animation := walker.player.get_animation(animation_name)
				if animation:
					animation.loop_mode = Animation.LOOP_LINEAR
	set_process(not _walkers.is_empty())


## Les tournées s'arrêtent (une fin rejouée, où ils se rassemblent au feu) ; chacun garde son corps.
func stop() -> void:
	set_process(false)
	for walker in _walkers:
		if walker.shape:
			walker.shape.disabled = false
	_walkers.clear()


func _first_pause(entries: Array) -> int:
	for index in range(1, entries.size()):
		if (entries[index] as Array).size() > 2:
			return index
	return 0


func _process(delta: float) -> void:
	var near := Vector2(player.global_position.x, player.global_position.z) if player else Vector2(INF, INF)
	for walker in _walkers:
		_step(walker, delta, near)


func _step(walker: Walker, delta: float, near: Vector2) -> void:
	var node := walker.node
	var here := Vector2(node.global_position.x, node.global_position.z)
	var entry: Array = walker.entries[walker.index]
	var target := Vector2(entry[0], entry[1])
	var to_player := near - here
	var distance := to_player.length()
	var talking := _held(walker, distance)
	if walker.walking:
		var heading := (target - here).normalized()
		var ahead := distance < YIELD_RADIUS and (distance < NEAR or heading.dot(to_player / maxf(distance, 0.001)) > 0.3)
		if walker.yielding:
			walker.patience = 0.0 if ahead or talking else walker.patience + delta
			if distance > RESUME_RADIUS or walker.patience > PATIENCE:
				walker.yielding = false
				_play(walker, &"walk")
		elif ahead or talking:
			walker.yielding = true
			walker.patience = 0.0
			_play(walker, &"idle")
		if walker.yielding:
			_turn(walker, to_player, delta)
			return
		var travel := SPEED * delta
		var remaining := here.distance_to(target)
		if remaining <= travel:
			_place(walker, target)
			_arrive(walker)
			return
		_place(walker, here + heading * travel)
		_turn(walker, heading, delta)
		return
	# Pause : il regarde ce qui l'occupe, ou le joueur qui vient le voir.
	if distance < YIELD_RADIUS:
		_turn(walker, to_player, delta)
	elif entry.size() > 2:
		_turn(walker, Vector2(entry[4], entry[5]) - here, delta)
	walker.wait -= delta
	if walker.wait <= 0.0 and distance >= NEAR and not talking:
		_leave(walker)


## Vrai si le joueur retient le villageois : il le vise (son invite est affichée), ou lui parle (le joueur est
## arrêté pendant la lecture) tout près de lui.
func _held(walker: Walker, distance: float) -> bool:
	var readable := walker.node as Interactable
	if readable and readable.focused:
		return true
	return distance < RESUME_RADIUS and player and not player.can_process()


## Arrivé au point visé : une pause commence, ou il file vers le point suivant.
func _arrive(walker: Walker) -> void:
	var entry: Array = walker.entries[walker.index]
	if entry.size() > 2:
		walker.wait = entry[2]
		_pause(walker)
	else:
		_next(walker)


func _leave(walker: Walker) -> void:
	_next(walker)
	walker.walking = true
	walker.yielding = false
	if walker.shape:
		walker.shape.disabled = true
	_play(walker, &"walk")


func _next(walker: Walker) -> void:
	walker.index += 1
	if walker.index >= walker.entries.size():
		walker.index = walker.loop_from


func _pause(walker: Walker) -> void:
	walker.walking = false
	walker.yielding = false
	if walker.shape:
		walker.shape.disabled = false
	var entry: Array = walker.entries[walker.index]
	_play(walker, entry[3] if entry.size() > 2 else &"idle")


func _place(walker: Walker, point: Vector2) -> void:
	var height := terrain.surface_height(point.x, point.y) if terrain else walker.node.global_position.y
	walker.node.global_position = Vector3(point.x, height, point.y)


## Tourne peu à peu le villageois (sa face +Z) vers la direction donnée.
func _turn(walker: Walker, direction: Vector2, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var yaw := atan2(direction.x, direction.y)
	walker.node.rotation.y = lerp_angle(walker.node.rotation.y, yaw, minf(TURN * delta, 1.0))


func _play(walker: Walker, animation: StringName) -> void:
	if walker.animation == animation or not walker.player or not walker.player.has_animation(animation):
		return
	walker.animation = animation
	walker.player.speed_scale = 1.0
	walker.player.play(animation, 0.25)


## Position et état de chaque villageois, pour les tests et les captures.
func describe() -> Array[String]:
	var lines: Array[String] = []
	for walker in _walkers:
		lines.append("%s %s %s%s" % [walker.node.name, walker.node.global_position.snappedf(0.1),
			"marche" if walker.walking else "pause", " (cède le passage)" if walker.yielding else ""])
	return lines
