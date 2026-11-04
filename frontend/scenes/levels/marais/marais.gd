class_name Marais
extends Node3D
## Les marais de Kernel Swamp : le tombeau du chiffrement. Le joueur suit les pontons dans la brume jusqu'à la
## crypte du gardien, descend son long escalier, déchiffre l'inscription gravée face au mécanisme et les épitaphes
## des rois, puis aligne cinq cercles de lettres pour ouvrir le tombeau du Logiconomicon, le livre de la logique
## et du chiffrement. Les eaux peu profondes ralentissent le joueur ; les eaux profondes le ramènent sur la rive.

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
## Teinte des dalles de la crypte, et le shader qui la leur donne.
const CRYPT_STONE := Color(0.6, 0.63, 0.64)
const STONE_SHADER := preload("res://scenes/levels/marais/crypt_stone.gdshader")
## Lumière d'ambiance de la crypte : sous terre, elle vient des cierges et non du ciel de nuit. Une faible lueur
## chaude, pour qu'aucune face tournée à l'opposé des lumières ne reste d'un noir d'encre.
const CRYPT_AMBIENT := Color(0.36, 0.3, 0.25)
## Le dehors, caché quand on est dans la crypte (et la crypte, cachée dehors).
const OUTSIDE_NODES: Array[NodePath] = [^"Terrain", ^"Water", ^"Scatter", ^"Props", ^"Grounded", ^"Portal", ^"Campfire",
	^"GateLightNorth", ^"GateLightSouth", ^"CryptLight", ^"SignLight", ^"ChapelLight", ^"Clues", ^"Ghost", ^"CryptDoor",
	^"DoorInteractable", ^"Volcano"]
## Direction d'où vient la lumière de la lune (axe +Z du nœud Moon).
const MOON_DIRECTION := Vector3(-0.5, 0.7071, 0.5)

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
## Particules fixes du dehors : nappes de brume (village englouti, chapelle, eaux de la crypte) et essaims de
## lucioles au-dessus des roseaux. Elles s'arrêtent dans la crypte.
var _mist_banks: Array[CPUParticles3D] = []
var _rumble: AudioStreamPlayer3D

@onready var _player: Player = $Player
@onready var _player_camera: Camera3D = $Player/CameraPivot/SpringArm3D/Camera3D
@onready var _hud: Hud = $Hud
@onready var _portal: Portal = $Portal
@onready var _clues: Node3D = $Clues
@onready var _ghost: Node3D = $Ghost
@onready var _moon: DirectionalLight3D = $Moon
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sky_ambient: Color = _environment.ambient_light_color
@onready var _ambience: AudioStreamPlayer = $Ambience
@onready var _crypt_ambience: AudioStreamPlayer = $CryptAmbience
@onready var _door: Node3D = $CryptDoor
@onready var _door_sound: AudioStreamPlayer3D = $CryptDoor/Sound
@onready var _door_interactable: Interactable = $DoorInteractable
@onready var _outside_spawn: Marker3D = $OutsideSpawn
@onready var _inside_spawn: Marker3D = $Interior/InsideSpawn
@onready var _exit: Interactable = $Interior/Exit
@onready var _exit_top: Interactable = $Interior/ExitTop
@onready var _wisps: Node3D = $Wisps
@onready var _moon_disc: Node3D = $MoonDisc
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
	# Tous les textes à lire : indices du dehors, inscription, épitaphes, hommage aux rois.
	for node in get_tree().get_nodes_in_group(&"interactable"):
		if node is Readable and is_ancestor_of(node):
			node.interacted.connect(_read.bind(node))
	_door_interactable.interacted.connect(_travel.bind(true))
	_exit.interacted.connect(_travel.bind(false))
	_exit_top.interacted.connect(_travel.bind(false))
	_mechanism_interactable.interacted.connect(_open_mechanism)
	_puzzle.validated.connect(_on_mechanism_validated)
	_puzzle.closed.connect(_close_mechanism)
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)

	_door_sound.stream = door_sound
	_tomb_sound.stream = door_sound
	# Grondement sourd de la crypte quand le mécanisme refuse une combinaison.
	_rumble = AudioStreamPlayer3D.new()
	_rumble.stream = door_sound
	_rumble.pitch_scale = 0.55
	_rumble.unit_size = 8.0
	_rumble.position = Vector3(0.0, 3.0, -12.0)
	$Interior.add_child(_rumble)
	_book_pickup.enabled = false
	_book.hide()
	_ghost_base = _ghost.position.y
	_safe_position = _player.global_position
	_fireflies = _create_fireflies()
	_mist = _create_mist()
	add_child(_fireflies)
	add_child(_mist)
	for bank: Vector4 in [Vector4(24.0, 30.0, 13.0, 16), Vector4(-35.0, -4.0, 9.0, 10), Vector4(-12.0, -28.0, 9.0, 10),
			Vector4(30.0, -26.0, 8.0, 8), Vector4(-30.0, 38.0, 9.0, 9)]:
		var mist := _create_mist(Vector3(bank.z, 0.2, bank.z), int(bank.w))
		mist.position = Vector3(bank.x, 0.3, bank.y)
		_mist_banks.append(mist)
		add_child(mist)
	# Essaims de lucioles au-dessus des roseaux : la berge du campement, le cimetière, l'arrivée, la crypte.
	for swarm: Vector3 in [Vector3(-14.5, 0.9, 29.0), Vector3(5.5, 1.0, -4.0), Vector3(-8.5, 0.9, 50.0), Vector3(-7.0, 1.0, -31.0),
			Vector3(28.0, 0.9, 6.0)]:
		var flies := _create_fireflies(Vector3(3.5, 0.8, 3.5), 16)
		flies.position = swarm
		_mist_banks.append(flies)
		add_child(flies)
	_tint_crypt()
	# Pour le web : le décor fixe regroupé en MultiMesh, par cases de 32 m dehors, de 12 m (une pièce) sous terre.
	for root: Node3D in [$Props/Models, $Grounded, $Scatter/Boardwalks, $Scatter/Lanterns]:
		MaraisBatch.merge(root, 32.0, true)
	MaraisBatch.merge($Interior/Crypt/Models, 12.0, false)
	# La lumière du feu de camp s'éteint au loin, comme les autres lumières du dehors.
	for light: Light3D in $Campfire.find_children("*", "Light3D", true, false):
		light.distance_fade_enabled = true
		light.distance_fade_begin = 38.0
		light.distance_fade_length = 8.0
	_apply_location()
	# Le nom du lieu s'affiche déjà pendant la transition du portail.
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà trouvé le livre de cette zone : le portail est ouvert.")


func _process(delta: float) -> void:
	_time += delta
	_fireflies.global_position = _player.global_position + Vector3.UP * 1.5
	_mist.global_position = Vector3(_player.global_position.x, 0.25, _player.global_position.z)
	# La lune suit le regard à distance fixe, dans la direction d'où vient sa lumière.
	var camera := get_viewport().get_camera_3d()
	if camera:
		_moon_disc.global_position = camera.global_position + MOON_DIRECTION * 420.0
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
	# On ne dessine que le côté où l'on est : la crypte, sous la carte, entrait dans le champ quand on regardait le
	# sol ; le marais, au-dessus du plafond, quand on levait les yeux dans la crypte. Lumières comprises.
	$Interior.visible = _inside
	for path in OUTSIDE_NODES:
		get_node(path).visible = not _inside
	_environment.fog_enabled = not _inside
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if _inside else Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_color = CRYPT_AMBIENT if _inside else _sky_ambient
	_fireflies.emitting = not _inside
	_mist.emitting = not _inside
	for bank in _mist_banks:
		bank.emitting = not _inside
	_wisps.visible = not _inside
	$GroundFog.visible = not _inside
	_moon_disc.visible = not _inside
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
		# Les inscriptions rougissent, un grondement roule dans la crypte et le volcan se rapproche de l'éruption.
		GameState.penalize()
		_tomb_sound.stream = reject_sound
		_tomb_sound.global_position = _mechanism.global_position
		_tomb_sound.play()
		_rumble.play()
		_shake(_mechanism_camera, 0.9)
		_mechanism.set_glow(Color(1.0, 0.15, 0.1), 3.0)
		var flash := create_tween()
		flash.tween_interval(1.2)
		flash.tween_callback(_mechanism.set_glow.bind(Color(0.85, 0.8, 0.7), 0.2))
		return
	_mechanism.set_glow(Color(0.35, 1.0, 0.5), 3.0)
	_mechanism_interactable.enabled = false
	_close_mechanism()
	# Le message attend que le panneau des cercles se soit effacé (1,5 s) : il ne passe pas sur son titre.
	get_tree().create_timer(1.5).timeout.connect(_hud.show_message.bind(
		"Les cercles s'illuminent de vert. Un grondement : dans la chambre de l'est, le lourd couvercle d'un tombeau glisse…"))
	_tomb_sound.stream = door_sound
	_tomb_sound.position = Vector3.UP
	_tomb_sound.play()
	# Le couvercle glisse vers l'est et bascule : un bord sur la cuve, l'autre au sol.
	var tween := create_tween()
	tween.tween_property(_tomb_lid, "position", _tomb_lid.position + Vector3(1.82, -0.51, 0.0), 2.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_tomb_lid, "rotation:z", deg_to_rad(-30.0), 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_book.show()
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	# Le livre vole jusqu'à la main du joueur, qui le garde jusqu'au château.
	_player.receive_book(BOOK_ID, _book.global_position)
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le Logiconomicon, le livre de la logique et du chiffrement, est à vous. Rapportez-le au château : le portail s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)


## Les dalles du kit de donjon sont orangées : sous le marais, le sol, le plafond et l'escalier deviennent de pierre
## froide et humide. La texture reste, seule sa teinte change.
func _tint_crypt() -> void:
	var tinted := {}
	for model: Node in $Interior/Crypt/Models.get_children():
		if not (model.name.contains("template_floor") or model.name.contains("stairs")):
			continue
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var source := mesh.get_active_material(0)
			if not source is BaseMaterial3D:
				continue
			if not tinted.has(source):
				var stone := ShaderMaterial.new()
				stone.shader = STONE_SHADER
				stone.set_shader_parameter(&"albedo_texture", (source as BaseMaterial3D).albedo_texture)
				stone.set_shader_parameter(&"tint", CRYPT_STONE)
				tinted[source] = stone
			mesh.material_override = tinted[source]


## Secoue une caméra quelques instants : le sol de la crypte gronde.
func _shake(camera: Camera3D, duration: float) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.05)
	for step in steps:
		var strength := 0.06 * (1.0 - float(step) / steps)
		tween.tween_property(camera, "h_offset", randf_range(-strength, strength), 0.05)
		tween.parallel().tween_property(camera, "v_offset", randf_range(-strength, strength), 0.05)
	tween.tween_property(camera, "h_offset", 0.0, 0.05)
	tween.parallel().tween_property(camera, "v_offset", 0.0, 0.05)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre des marais.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	GameState.return_to_hub(ZONE)


## Lucioles autour du joueur : de petites lueurs qui dérivent lentement.
func _create_fireflies(extents := Vector3(18.0, 1.5, 18.0), amount := 70) -> CPUParticles3D:
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
	fireflies.amount = amount
	fireflies.lifetime = 6.0
	fireflies.preprocess = 6.0
	fireflies.local_coords = false
	fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fireflies.emission_box_extents = extents
	fireflies.spread = 180.0
	fireflies.gravity = Vector3.ZERO
	fireflies.initial_velocity_min = 0.1
	fireflies.initial_velocity_max = 0.4
	fireflies.color_ramp = gradient
	return fireflies


## Nappes de brume au ras de l'eau : autour du joueur, ou fixes au-dessus d'une étendue d'eau.
func _create_mist(extents := Vector3(26.0, 0.2, 26.0), amount := 40) -> CPUParticles3D:
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
	mist.amount = amount
	mist.lifetime = 14.0
	mist.preprocess = 14.0
	mist.local_coords = false
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = extents
	mist.direction = Vector3(1.0, 0.0, 0.2)
	mist.spread = 40.0
	mist.gravity = Vector3.ZERO
	mist.initial_velocity_min = 0.1
	mist.initial_velocity_max = 0.3
	mist.color_ramp = fade
	return mist
