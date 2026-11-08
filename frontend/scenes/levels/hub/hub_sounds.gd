class_name HubSounds
extends Node3D
## Sons du hub, posés dans l'espace : l'eau de la rivière, le feuillage et les oiseaux du jardin du roi, la roue du
## moulin. Le village est sinistré sous un volcan : avant les livres, on n'entend que l'eau lente et des feuilles
## mortes ; le jardin reconstruit (deuxième livre) retrouve ses oiseaux, de plus en plus nombreux jusqu'à la victoire,
## et la roue du moulin, réparée au même palier, bat l'eau.
##
## Peu de lecteurs : la rivière et le feuillage ont chacun une seule source, qui suit l'auditeur, au point de la
## rivière le plus proche et au point du jardin le plus proche ; les oiseaux en ont une, déplacée d'un arbre à
## l'autre. Chaque source se tait au-delà de sa portée, et toutes dans le bunker. Les portées s'arrêtent avant la
## place du village, où la musique reste seule avec l'ambiance. Voir docs/sons.md.

const RIVER: AudioStream = preload("res://assets/audio/river.wav")
const LEAVES: AudioStream = preload("res://assets/audio/park_leaves.wav")
const WHEEL: AudioStream = preload("res://assets/audio/stream.wav")
const BIRDS: Array[AudioStream] = [
	preload("res://assets/audio/bird_1.wav"),
	preload("res://assets/audio/bird_2.wav"),
	preload("res://assets/audio/bird_3.wav"),
]
## Roue du moulin (MILL_WHEEL de tools/build_hub.py), réparée au deuxième livre comme le jardin du roi.
const MILL_WHEEL := Vector3(70.5, 0.4, 48.0)
const PARK_STAGE := 2
## Hauteur des feuillages du jardin, et des branches où chantent les oiseaux.
const CANOPY := 3.0
const BRANCHES := Vector2(3.5, 6.0)
## Attente entre deux chants, en secondes : au deuxième livre, puis à la victoire.
const BIRD_WAIT_FIRST := Vector2(9.0, 20.0)
const BIRD_WAIT_VICTORY := Vector2(2.5, 7.0)
## Au-dessous de cette hauteur, l'auditeur est dans le bunker, sous la carte.
const INSIDE_BELOW := -20.0
## Les sources sont replacées à ce rythme, en secondes ; le reste du temps, rien ne se calcule.
const STEP := 0.1
## Au plus près, une source ne dépasse son volume que d'autant (dB) : la rivière et le feuillage, qui suivent
## l'auditeur, et les sources fixes (oiseaux, roue). Godot ajoute le gain de la distance au volume avant de plafonner à
## max_db : la rivière ou le feuillage, à un ou deux mètres de l'auditeur, montaient sinon de 10 à 14 dB.
const NEAR_GAIN := 1.0
const POINT_NEAR_GAIN := 3.0

var _river: AudioStreamPlayer3D
var _leaves: AudioStreamPlayer3D
var _wheel: AudioStreamPlayer3D
var _bird: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()
var _clock := 0.0
var _bird_wait := 0.0
## Tracé de la rivière (x, z), de HubTerrain.RIVER (x, z, demi-largeur).
var _course: PackedVector2Array


func _ready() -> void:
	_rng.randomize()
	for point in HubTerrain.RIVER:
		_course.append(Vector2(point.x, point.y))
	# Portées : la rivière s'entend de ses berges et des ponts, plus du tout au cœur du village (à 60 m) ; le jardin et
	# ses oiseaux, dans le jardin et sur ses abords ; la roue, en approchant du moulin.
	_river = _source("River", RIVER, 6.0, 38.0)
	_leaves = _source("Leaves", LEAVES, 7.0, 30.0)
	_wheel = _source("MillWheel", WHEEL, 4.0, 24.0)
	_wheel.pitch_scale = 0.72
	_wheel.volume_db = -9.0
	_wheel.max_db = _wheel.volume_db + POINT_NEAR_GAIN
	_wheel.position = MILL_WHEEL
	_bird = _source("Bird", BIRDS[0], 5.0, 40.0)
	_bird_wait = _rng.randf_range(BIRD_WAIT_FIRST.x, BIRD_WAIT_FIRST.y)


func _source(source_name: String, stream: AudioStream, unit_size: float, max_distance: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = source_name
	player.stream = stream
	player.unit_size = unit_size
	player.max_distance = max_distance
	add_child(player)
	return player


func _process(delta: float) -> void:
	_clock += delta
	_bird_wait -= delta
	if _clock < STEP:
		return
	_clock = 0.0
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var ear := camera.global_position
	var placed := GameState.placed_books.size()
	var life := float(placed) / GameState.BOOK_COUNT
	var outside := ear.y > INSIDE_BELOW
	var flat := Vector2(ear.x, ear.z)
	# Rivière : au point de son tracé le plus proche, au ras de l'eau. L'eau lente et boueuse d'avant les livres
	# s'éclaircit avec eux (HubRiver.set_life) : elle chante un peu plus fort.
	var near := _closest_on_river(flat)
	_river.position = Vector3(near.x, HubTerrain.WATER_LEVEL + 0.3, near.y)
	_river.volume_db = lerpf(-16.0, -13.0, life)
	_river.max_db = _river.volume_db + NEAR_GAIN
	_keep(_river, outside, ear)
	# Feuillage : au point du jardin le plus proche, à hauteur des arbres. Feuilles mortes avant le jardin
	# reconstruit, plus fournies ensuite.
	var park := HubTerrain.PARK_AREA
	var leaf := flat.clamp(park.position, park.end)
	_leaves.position = Vector3(leaf.x, CANOPY, leaf.y)
	_leaves.volume_db = lerpf(-16.0, -11.0, life)
	_leaves.max_db = _leaves.volume_db + NEAR_GAIN
	_keep(_leaves, outside, ear)
	_keep(_wheel, outside and placed >= PARK_STAGE, ear)
	# Oiseaux : le jardin reconstruit, et pas pendant l'éruption.
	var singing := outside and placed >= PARK_STAGE and not GameState.has_erupted
	if singing and _bird_wait <= 0.0 and not _bird.playing:
		_sing(placed, ear)
	elif _bird.playing and (not singing or _bird.position.distance_to(ear) > _bird.max_distance):
		_bird.stop()


## Un oiseau chante sur une branche au hasard du jardin, un peu plus haut ou plus bas selon l'espèce.
func _sing(placed: int, ear: Vector3) -> void:
	var park := HubTerrain.PARK_AREA
	var spot := Vector3(_rng.randf_range(park.position.x, park.end.x), _rng.randf_range(BRANCHES.x, BRANCHES.y),
		_rng.randf_range(park.position.y, park.end.y))
	_bird.position = spot
	if spot.distance_to(ear) < _bird.max_distance:
		_bird.stream = BIRDS[_rng.randi() % BIRDS.size()]
		_bird.pitch_scale = _rng.randf_range(0.92, 1.08)
		_bird.volume_db = _rng.randf_range(-15.0, -10.0)
		_bird.max_db = _bird.volume_db + POINT_NEAR_GAIN
		_bird.play()
	var victory := placed >= GameState.BOOK_COUNT and not GameState.is_victory_pending()
	var wait := BIRD_WAIT_VICTORY if victory else BIRD_WAIT_FIRST
	_bird_wait = _rng.randf_range(wait.x, wait.y)


## Une source en boucle ne joue que si l'auditeur est à sa portée : hors de portée, elle ne mixe rien.
func _keep(player: AudioStreamPlayer3D, wanted: bool, ear: Vector3) -> void:
	var audible := wanted and player.position.distance_to(ear) < player.max_distance + 4.0
	if audible and not player.playing:
		# Départ à un endroit au hasard de la boucle : deux passages ne recommencent pas au même clapotis.
		player.play(_rng.randf() * player.stream.get_length())
	elif not audible and player.playing:
		player.stop()


func _closest_on_river(point: Vector2) -> Vector2:
	var best := _course[0]
	var best_distance := INF
	for index in _course.size() - 1:
		var candidate := Geometry2D.get_closest_point_to_segment(point, _course[index], _course[index + 1])
		var distance := candidate.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## Sources qui jouent en ce moment, pour les tests : leur nombre reste petit.
func active_sources() -> int:
	var count := 0
	for player in [_river, _leaves, _wheel, _bird]:
		if player.playing:
			count += 1
	return count
