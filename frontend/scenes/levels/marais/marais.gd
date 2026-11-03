class_name Marais
extends Node3D
## Zone du Marais : le tombeau des lettres oubliées. Le joueur descend dans la crypte, déchiffre
## l'inscription et aligne cinq cercles de lettres pour ouvrir le tombeau du Logiconomicon.
## Les eaux peu profondes ralentissent le joueur ; les eaux profondes le ramènent sur la rive.

signal book_collected(book_id: StringName)
signal hub_requested

const ZONE := &"marais"
const BOOK_ID := &"logiconomicon"
## Hauteur des pieds sous laquelle le joueur patauge, puis s'enlise.
const WADE_DEPTH := -0.15
const SINK_DEPTH := -0.9
const WADE_SPEED := 0.55
## Images passées au sol, hors de l'eau, avant de retenir la position comme sûre.
const SAFE_FRAMES := 15
const AMBIENCE_DB := -6.0

@export var ground_steps: Array[AudioStream]
@export var water_steps: Array[AudioStream]
@export var stone_steps: Array[AudioStream]
@export var door_sound: AudioStream
@export var reject_sound: AudioStream

var _busy := false
var _inside := false
var _wading := false
var _door_open := false
var _safe_position := Vector3.ZERO
var _grounded_frames := 0
var _time := 0.0
var _ghost_base := 0.0
var _fireflies: CPUParticles3D
var _mist: CPUParticles3D

@onready var _player: Player = $Player
@onready var _player_camera: Camera3D = $Player/CameraPivot/SpringArm3D/Camera3D
@onready var _hud: Hud = $Hud
@onready var _portal: Portal = $Portal
@onready var _clues: Node3D = $Clues
@onready var _ghost: Node3D = $Ghost
@onready var _moon: DirectionalLight3D = $Moon
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _ambience: AudioStreamPlayer = $Ambience
@onready var _crypt_ambience: AudioStreamPlayer = $CryptAmbience
@onready var _door: Node3D = $CryptDoor
@onready var _door_sound: AudioStreamPlayer3D = $CryptDoor/Sound
@onready var _door_interactable: Interactable = $DoorInteractable
@onready var _outside_spawn: Marker3D = $OutsideSpawn
@onready var _inside_spawn: Marker3D = $Interior/InsideSpawn
@onready var _exit: Interactable = $Interior/Exit
@onready var _inscription: Readable = $Interior/Inscription
@onready var _mechanism: RingMechanism = $Interior/Mechanism
@onready var _mechanism_interactable: Interactable = $Interior/MechanismInteractable
@onready var _mechanism_camera: Camera3D = $Interior/MechanismCamera
@onready var _puzzle: RingPuzzle = $RingPuzzle
@onready var _tomb_lid: Node3D = $Interior/Tomb/Lid
@onready var _tomb_sound: AudioStreamPlayer3D = $Interior/Tomb/Sound
@onready var _book: Node3D = $Interior/Tomb/Book
@onready var _book_pickup: Interactable = $Interior/Tomb/Book/Interactable


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	for clue: Readable in _clues.get_children():
		clue.interacted.connect(_read.bind(clue))
	_inscription.interacted.connect(_read.bind(_inscription))
	_door_interactable.interacted.connect(_travel.bind(true))
	_exit.interacted.connect(_travel.bind(false))
	_mechanism_interactable.interacted.connect(_open_mechanism)
	_puzzle.validated.connect(_on_mechanism_validated)
	_puzzle.closed.connect(_close_mechanism)
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)

	_door_sound.stream = door_sound
	_tomb_sound.stream = door_sound
	_book_pickup.enabled = false
	_book.hide()
	_ghost_base = _ghost.position.y
	_safe_position = _player.global_position
	_fireflies = _create_fireflies()
	_mist = _create_mist()
	add_child(_fireflies)
	add_child(_mist)
	_apply_location()
	_hud.show_message("Le Marais")
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà rapporté le livre de cette zone : le portail est ouvert.")


func _process(delta: float) -> void:
	_time += delta
	_fireflies.global_position = _player.global_position + Vector3.UP * 1.5
	_mist.global_position = Vector3(_player.global_position.x, 0.25, _player.global_position.z)
	_ghost.position.y = _ghost_base + sin(_time * 1.3) * 0.18
	_ghost.rotation.y = sin(_time * 0.4) * 0.35 - PI * 0.5
	if _book.visible:
		_book.rotation.y += delta * 0.8


func _physics_process(_delta: float) -> void:
	if _busy or _inside:
		return
	var feet := _player.global_position.y
	if feet < SINK_DEPTH:
		_sink()
		return
	var wading := feet < WADE_DEPTH
	if wading != _wading:
		_wading = wading
		_player.speed_multiplier = WADE_SPEED if wading else 1.0
		_player.footstep_sounds = water_steps if wading else ground_steps
	# Juste après un déplacement, is_on_floor() vaut encore l'image précédente : on attend d'être posé.
	if _player.is_on_floor() and feet > MaraisTerrain.WATER_LEVEL + 0.1:
		_grounded_frames += 1
		if _grounded_frames >= SAFE_FRAMES:
			_safe_position = _player.global_position
	else:
		_grounded_frames = 0


func mechanism() -> RingMechanism:
	return _mechanism


func _sink() -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_player.global_position = _safe_position
	_player.velocity = Vector3.ZERO
	_grounded_frames = 0
	_hud.show_message("La vase vous aspire : vous regagnez la rive à grand-peine.")
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


## Descend dans la crypte ou en remonte. La porte pivote la première fois qu'on la franchit.
func _travel(inside: bool) -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	if inside and not _door_open:
		_door_open = true
		_door_sound.play()
		var tween := create_tween()
		tween.tween_property(_door, "rotation:y", _door.rotation.y + deg_to_rad(105.0), 1.6).set_trans(Tween.TRANS_SINE)
		await tween.finished
	await _hud.fade(true)
	_inside = inside
	_apply_location()
	var spawn := _inside_spawn if inside else _outside_spawn
	_player.global_position = spawn.global_position
	_player.velocity = Vector3.ZERO
	_player.speed_multiplier = 1.0
	_wading = false
	if not inside:
		_safe_position = spawn.global_position
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false
	if inside:
		_hud.show_message("La crypte du gardien")


func _apply_location() -> void:
	_moon.visible = not _inside
	_environment.fog_enabled = not _inside
	_fireflies.emitting = not _inside
	_mist.emitting = not _inside
	_player.footstep_sounds = stone_steps if _inside else ground_steps
	_ambience.volume_db = AMBIENCE_DB - 24.0 if _inside else AMBIENCE_DB
	if _inside:
		_crypt_ambience.play()
	else:
		_crypt_ambience.stop()


func _read(readable: Readable) -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_text(readable.title, readable.body)


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Vue rapprochée : la caméra se place au-dessus du mécanisme et l'interface des cercles s'ouvre.
func _open_mechanism() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.set_crosshair_visible(false)
	_hud.set_prompt("")
	_mechanism_camera.current = true
	_puzzle.open(_mechanism)


func _close_mechanism() -> void:
	_player_camera.current = true
	_close_panel()


func _on_mechanism_validated(correct: bool) -> void:
	if not correct:
		# Les inscriptions rougissent, un bruit sourd résonne et le volcan se rapproche de l'éruption.
		GameState.penalize()
		_tomb_sound.stream = reject_sound
		_tomb_sound.global_position = _mechanism.global_position
		_tomb_sound.play()
		_mechanism.set_glow(Color(1.0, 0.15, 0.1), 3.0)
		var flash := create_tween()
		flash.tween_interval(1.2)
		flash.tween_callback(_mechanism.set_glow.bind(Color(0.85, 0.8, 0.7), 0.2))
		return
	_mechanism.set_glow(Color(0.35, 1.0, 0.5), 3.0)
	_mechanism_interactable.enabled = false
	_close_mechanism()
	_hud.show_message("Les inscriptions s'illuminent de vert. Un grondement : dans la chambre de l'est, un tombeau s'ouvre…")
	_tomb_sound.stream = door_sound
	_tomb_sound.position = Vector3.UP
	_tomb_sound.play()
	var tween := create_tween()
	tween.tween_property(_tomb_lid, "position", _tomb_lid.position + Vector3(1.7, -0.2, 0.0), 2.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_tomb_lid, "rotation:z", deg_to_rad(-12.0), 2.4)
	await tween.finished
	_book.show()
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le Logiconomicon est à vous. Le portail du Marais s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre du Marais.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	GameState.return_to_hub(ZONE)


## Lucioles autour du joueur : de petites lueurs qui dérivent lentement.
func _create_fireflies() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(2.2, 2.6, 1.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.8, 1.0, 0.4, 0.0))
	gradient.set_color(1, Color(0.8, 1.0, 0.4, 0.0))
	gradient.add_point(0.3, Color(0.85, 1.0, 0.45, 1.0))
	gradient.add_point(0.7, Color(0.85, 1.0, 0.45, 1.0))

	var fireflies := CPUParticles3D.new()
	fireflies.mesh = quad
	fireflies.amount = 70
	fireflies.lifetime = 6.0
	fireflies.preprocess = 6.0
	fireflies.local_coords = false
	fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fireflies.emission_box_extents = Vector3(18.0, 1.5, 18.0)
	fireflies.spread = 180.0
	fireflies.gravity = Vector3.ZERO
	fireflies.initial_velocity_min = 0.1
	fireflies.initial_velocity_max = 0.4
	fireflies.color_ramp = gradient
	return fireflies


## Nappes de brume au ras de l'eau autour du joueur.
func _create_mist() -> CPUParticles3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(9.0, 4.0)
	quad.material = material
	var fade := Gradient.new()
	fade.set_color(0, Color(0.55, 0.65, 0.6, 0.0))
	fade.set_color(1, Color(0.55, 0.65, 0.6, 0.0))
	fade.add_point(0.5, Color(0.55, 0.65, 0.6, 0.14))

	var mist := CPUParticles3D.new()
	mist.mesh = quad
	mist.amount = 40
	mist.lifetime = 14.0
	mist.preprocess = 14.0
	mist.local_coords = false
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(26.0, 0.2, 26.0)
	mist.direction = Vector3(1.0, 0.0, 0.2)
	mist.spread = 40.0
	mist.gravity = Vector3.ZERO
	mist.initial_velocity_min = 0.1
	mist.initial_velocity_max = 0.3
	mist.color_ramp = fade
	return mist
