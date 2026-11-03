class_name Marais
extends Node3D
## Zone du Marais : les indices du gardien, puis les braseros qui ouvrent sa crypte et libèrent le livre.
## Les eaux peu profondes ralentissent le joueur ; les eaux profondes le ramènent sur la rive.

signal book_collected(book_id: StringName)
signal hub_requested

const BOOK_ID := &"binarium"
## Nombre que les braseros doivent former : les années de veille du gardien, de 5803 à 5814.
const CRYPT_CODE := 11
## Hauteur des pieds sous laquelle le joueur patauge, puis s'enlise.
const WADE_DEPTH := -0.15
const SINK_DEPTH := -0.9
const WADE_SPEED := 0.55
## Images passées au sol, hors de l'eau, avant de retenir la position comme sûre.
const SAFE_FRAMES := 15

## Scène du hub, chargée quand le joueur repasse le portail une fois le livre récupéré.
@export_file("*.tscn") var hub_scene := ""
@export var ground_steps: Array[AudioStream]
@export var water_steps: Array[AudioStream]
@export var door_sound: AudioStream

var _has_book := false
var _busy := false
var _wading := false
var _safe_position := Vector3.ZERO
var _grounded_frames := 0
var _time := 0.0
var _ghost_base := 0.0
var _fireflies: CPUParticles3D
var _mist: CPUParticles3D

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _portal: Portal = $Portal
@onready var _clues: Node3D = $Clues
@onready var _ghost: Node3D = $Ghost
@onready var _braziers: Array[Brazier] = [$Braziers/Eight, $Braziers/Four, $Braziers/Two, $Braziers/One]
@onready var _door: Node3D = $CryptDoor
@onready var _door_sound: AudioStreamPlayer3D = $CryptDoor/Sound
@onready var _book: Node3D = $Book
@onready var _book_pickup: Interactable = $Book/Interactable
@onready var _book_target: Marker3D = $BookTarget


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	for clue: Readable in _clues.get_children():
		clue.interacted.connect(_read.bind(clue))
	for brazier in _braziers:
		brazier.toggled.connect(_on_brazier_toggled.unbind(1))
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)

	_door_sound.stream = door_sound
	_book_pickup.enabled = false
	_book.hide()
	_ghost_base = _ghost.position.y
	_safe_position = _player.global_position
	_player.footstep_sounds = ground_steps
	_fireflies = _create_fireflies()
	_mist = _create_mist()
	add_child(_fireflies)
	add_child(_mist)
	_hud.show_message("Le Marais")


func _process(delta: float) -> void:
	_time += delta
	_fireflies.global_position = _player.global_position + Vector3.UP * 1.5
	_mist.global_position = Vector3(_player.global_position.x, 0.25, _player.global_position.z)
	_ghost.position.y = _ghost_base + sin(_time * 1.3) * 0.18
	_ghost.rotation.y = sin(_time * 0.4) * 0.35 - PI * 0.5
	if _book.visible:
		_book.rotation.y += delta * 0.8


func _physics_process(_delta: float) -> void:
	if _busy:
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


func crypt_value() -> int:
	var total := 0
	for brazier in _braziers:
		if brazier.lit:
			total += brazier.value
	return total


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


func _read(readable: Readable) -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_text(readable.title, readable.body)


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_brazier_toggled() -> void:
	if crypt_value() != CRYPT_CODE:
		return
	for brazier in _braziers:
		brazier.set_locked(true)
	_hud.show_message("Un déclic sourd sous la pierre : la porte de la crypte pivote…")
	_door_sound.play()
	var tween := create_tween()
	tween.tween_property(_door, "rotation:y", _door.rotation.y + deg_to_rad(105.0), 2.4)
	tween.set_trans(Tween.TRANS_SINE)
	await tween.finished
	_reveal_book()


func _reveal_book() -> void:
	var target := _book_target.global_position
	_book.global_position = target + Vector3(0.0, 0.0, -3.5)
	_book.show()
	var tween := create_tween()
	tween.tween_property(_book, "global_position", target, 2.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	_has_book = true
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le Binarium est à vous. Le portail du Marais s'est rouvert.")
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre du Marais.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	if hub_scene.is_empty():
		_hud.show_message("Le hub n'est pas encore relié à ce portail.")
	else:
		get_tree().change_scene_to_file(hub_scene)


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
