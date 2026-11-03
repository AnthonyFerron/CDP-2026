class_name Desert
extends Node3D
## Zone du Désert : les stèles du sanctuaire, puis la cave où trois tablettes s'éveillent dans l'ordre
## pour libérer le livre des Archives du Soleil. Les sables mouvants ramènent le joueur en lieu sûr.
## Conception reprise de l'ébauche de niveau 2 : sanctuaire, trappe, cave, trois fonctions et coffre.

signal book_collected(book_id: StringName)
signal hub_requested

const ZONE := &"desert"
const BOOK_ID := &"archives_du_soleil"
const ORDER: Array[StringName] = [&"initialiser", &"transformer", &"transmettre"]
const QUICKSAND_SPEED := 0.35
## Temps passé dans les sables mouvants avant d'être englouti.
const SINK_TIME := 1.6
const SAFE_FRAMES := 15
const WIND_DB := -8.0
## Teinte appliquée à la pierre claire du kit pour en faire du grès.
const SANDSTONE := Color(1.0, 0.8, 0.6)

@export var sand_steps: Array[AudioStream]
@export var stone_steps: Array[AudioStream]
@export var chimes: Array[AudioStream]
@export var reset_sound: AudioStream

var _progress := 0
var _inside := false
var _busy := false
var _sinking := 0.0
var _grounded_frames := 0
var _safe_position := Vector3.ZERO
var _sandstorm: CPUParticles3D

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _wind: AudioStreamPlayer = $Wind
@onready var _cave_sound: AudioStreamPlayer = $CaveAmbience
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _exterior: Node3D = $Exterior
@onready var _interior: Node3D = $Interior
@onready var _portal: Portal = $Exterior/Portal
@onready var _hatch: Node3D = $Exterior/Trapdoor/Hatch
@onready var _trapdoor: Interactable = $Exterior/Trapdoor/Interactable
@onready var _exit: Interactable = $Interior/Exit
@onready var _inside_spawn: Marker3D = $Interior/InsideSpawn
@onready var _outside_spawn: Marker3D = $Exterior/OutsideSpawn
@onready var _tablets: Node3D = $Interior/Tablets
@onready var _tablet_sound: AudioStreamPlayer3D = $Interior/Tablets/Sound
@onready var _book: Node3D = $Interior/Book
@onready var _book_pickup: Interactable = $Interior/Book/Interactable
@onready var _book_target: Marker3D = $Interior/BookTarget


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	for clues: Node in [$Exterior/Clues, $Interior/Clues]:
		for clue: Readable in clues.get_children():
			clue.interacted.connect(_read.bind(clue))
	for tablet: Node3D in _tablets.get_children().filter(func(node: Node) -> bool: return node.has_node("Interactable")):
		var pickup: Interactable = tablet.get_node("Interactable")
		pickup.interacted.connect(_on_tablet_activated.bind(tablet))
	_trapdoor.interacted.connect(_travel.bind(true))
	_exit.interacted.connect(_travel.bind(false))
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)

	_book_pickup.enabled = false
	_book.hide()
	_safe_position = _player.global_position
	_tint_stone($Exterior/Ruins)
	_sandstorm = _create_sandstorm()
	_exterior.add_child(_sandstorm)
	_apply_location()
	_hud.show_message("Le Désert")
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà rapporté le livre de cette zone : le portail est ouvert.")


func _process(delta: float) -> void:
	_sandstorm.global_position = _player.global_position + Vector3(-12.0, 1.5, 0.0)
	if _book.visible:
		_book.rotation.y += delta * 0.8


func _physics_process(delta: float) -> void:
	if _busy or _inside:
		return
	var in_sand := _quicksand_at(_player.global_position)
	_player.speed_multiplier = QUICKSAND_SPEED if in_sand else 1.0
	if in_sand:
		_sinking += delta
		if _sinking >= SINK_TIME:
			_swallow()
		return
	_sinking = 0.0
	# Juste après un déplacement, is_on_floor() vaut encore l'image précédente : on attend d'être posé.
	if _player.is_on_floor():
		_grounded_frames += 1
		if _grounded_frames >= SAFE_FRAMES:
			_safe_position = _player.global_position
	else:
		_grounded_frames = 0


func tablet_progress() -> int:
	return _progress


func _quicksand_at(point: Vector3) -> bool:
	for sand in DesertTerrain.QUICKSANDS:
		if Vector2(point.x - sand.x, point.z - sand.y).length() < sand.z * 0.85:
			return true
	return false


func _swallow() -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_player.global_position = _safe_position
	_player.velocity = Vector3.ZERO
	_player.speed_multiplier = 1.0
	_sinking = 0.0
	_grounded_frames = 0
	_hud.show_message("Les sables mouvants vous happent : vous vous arrachez de justesse.")
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


func _travel(inside: bool) -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	if inside:
		var tween := create_tween()
		tween.tween_property(_hatch, "rotation:x", deg_to_rad(-110.0), 0.6).set_trans(Tween.TRANS_BACK)
		await tween.finished
	await _hud.fade(true)
	_inside = inside
	_apply_location()
	var spawn := _inside_spawn if inside else _outside_spawn
	_player.global_position = spawn.global_position
	_player.velocity = Vector3.ZERO
	_player.speed_multiplier = 1.0
	_hatch.rotation.x = 0.0
	if not inside:
		_safe_position = spawn.global_position
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


func _apply_location() -> void:
	_interior.visible = _inside
	_exterior.visible = not _inside
	_sun.visible = not _inside
	_environment.fog_enabled = not _inside
	_sandstorm.emitting = not _inside
	_player.footstep_sounds = stone_steps if _inside else sand_steps
	_wind.volume_db = WIND_DB - 18.0 if _inside else WIND_DB
	if _inside:
		_cave_sound.play()
	else:
		_cave_sound.stop()


func _read(readable: Readable) -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_text(readable.title, readable.body)


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_tablet_activated(tablet: Node3D) -> void:
	if _progress >= ORDER.size():
		return
	if StringName(tablet.name.to_lower()) == ORDER[_progress]:
		_set_tablet_glow(tablet, true)
		_tablet_sound.stream = chimes[_progress]
		_tablet_sound.play()
		_progress += 1
		tablet.get_node("Interactable").enabled = false
		if _progress == ORDER.size():
			_on_sequence_complete()
		else:
			_hud.show_message("La tablette s'illumine. Fonctions éveillées : %d / %d" % [_progress, ORDER.size()])
		return
	_progress = 0
	_tablet_sound.stream = reset_sound
	_tablet_sound.play()
	for other: Node3D in _tablets.get_children().filter(func(node: Node) -> bool: return node.has_node("Interactable")):
		_set_tablet_glow(other, false)
		other.get_node("Interactable").enabled = true
	_hud.show_message("L'algorithme se dissipe : les tablettes s'éteignent. Relisez les stèles.")


func _set_tablet_glow(tablet: Node3D, lit: bool) -> void:
	var slab: MeshInstance3D = tablet.get_node("Slab")
	var material := slab.get_active_material(0) as StandardMaterial3D
	material.emission_energy_multiplier = 2.5 if lit else 0.15
	tablet.get_node("Glow").visible = lit


func _on_sequence_complete() -> void:
	_hud.show_message("Les trois fonctions s'éveillent : le coffre s'entrouvre…")
	var target := _book_target.global_position
	_book.global_position = target + Vector3.DOWN * 1.2
	_book.show()
	var tween := create_tween()
	tween.tween_property(_book, "global_position", target, 1.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le livre des Archives du Soleil est à vous. Le portail du Désert s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre du Désert.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	GameState.return_to_hub(ZONE)


## Teinte les matériaux des modèles en grès, en partageant une copie par matériau d'origine.
func _tint_stone(root: Node) -> void:
	var tinted := {}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():
			var original := mesh.get_active_material(surface) as BaseMaterial3D
			if not original:
				continue
			if not tinted.has(original):
				var copy: BaseMaterial3D = original.duplicate()
				copy.albedo_color *= SANDSTONE
				tinted[original] = copy
			mesh.set_surface_override_material(surface, tinted[original])


## Rafales de sable qui balaient le sol autour du joueur.
func _create_sandstorm() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.35, 0.04)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.95, 0.8, 0.55, 0.0))
	gradient.set_color(1, Color(0.95, 0.8, 0.55, 0.0))
	gradient.add_point(0.3, Color(0.95, 0.82, 0.58, 0.55))
	gradient.add_point(0.7, Color(0.95, 0.82, 0.58, 0.45))

	var storm := CPUParticles3D.new()
	storm.mesh = quad
	storm.amount = 220
	storm.lifetime = 2.5
	storm.preprocess = 2.5
	storm.local_coords = false
	storm.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	storm.emission_box_extents = Vector3(4.0, 1.5, 22.0)
	storm.direction = Vector3(1.0, 0.05, 0.15)
	storm.spread = 6.0
	storm.gravity = Vector3(0.0, -0.4, 0.0)
	storm.initial_velocity_min = 8.0
	storm.initial_velocity_max = 13.0
	storm.color_ramp = gradient
	return storm
