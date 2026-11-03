class_name Desert
extends Node3D
## Zone du Désert : les runes de l'algorithme. Le joueur ramasse des runes dans les ruines et sous
## le sable, puis reconstitue deux algorithmes sur la table ronde de la cave pour libérer l'Algonicon.
## Les sables mouvants ramènent le joueur en lieu sûr.

signal book_collected(book_id: StringName)
signal hub_requested

const ZONE := &"desert"
const BOOK_ID := &"algonicon"
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

## Runes ramassées, dans l'ordre où le joueur les a trouvées.
var _inventory: Array[StringName] = []
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
@onready var _puzzle: RunePuzzle = $RunePuzzle
@onready var _table: Interactable = $Interior/RoundTable/Interactable
@onready var _table_glow: OmniLight3D = $Interior/RoundTable/Glow
@onready var _table_sound: AudioStreamPlayer3D = $Interior/RoundTable/Sound
@onready var _chest: Node3D = $Interior/Chest
@onready var _chest_sand: Node3D = $Interior/ChestSand
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
	for rune: Rune in find_children("*", "Rune", true, false):
		rune.interacted.connect(_on_rune_taken.bind(rune))
	for pile: SandPile in find_children("*", "SandPile", true, false):
		pile.cleared.connect(_on_pile_cleared)
	_table.interacted.connect(_open_table)
	_puzzle.validated.connect(_on_puzzle_validated)
	_puzzle.closed.connect(_close_panel)
	_trapdoor.interacted.connect(_travel.bind(true))
	_exit.interacted.connect(_travel.bind(false))
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)

	_book_pickup.enabled = false
	_book.hide()
	_chest.hide()
	_table_glow.visible = false
	_safe_position = _player.global_position
	_tint_stone($Exterior/Ruins)
	_sandstorm = _create_sandstorm()
	_exterior.add_child(_sandstorm)
	_apply_location()
	_hud.show_message("Le Désert")
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà trouvé le livre de cette zone : le portail est ouvert.")


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


func inventory() -> Array[StringName]:
	return _inventory


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


func _on_rune_taken(rune: Rune) -> void:
	rune.collect()
	_inventory.append(rune.rune_id)
	_table_sound.stream = chimes[0]
	_table_sound.play()
	_hud.show_message("Rune ramassée : « %s »" % RunePuzzle.RUNES[rune.rune_id])


func _on_pile_cleared(had_rune: bool) -> void:
	_hud.show_message("Une rune affleure sous le sable." if had_rune else "Rien sous ce tas de sable.")


func _open_table() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.set_crosshair_visible(false)
	_puzzle.open(_inventory)


func _on_puzzle_validated(correct: bool) -> void:
	_table_glow.visible = true
	if not correct:
		# Les runes rougissent un instant et le volcan se rapproche de l'éruption.
		GameState.penalize()
		_table_glow.light_color = Color(1.0, 0.15, 0.1)
		_table_sound.stream = reset_sound
		_table_sound.play()
		var flash := create_tween()
		flash.tween_interval(1.2)
		flash.tween_callback(_table_glow.hide)
		return
	_close_panel()
	_table.enabled = false
	_table_glow.light_color = Color(0.4, 0.7, 1.0)
	_table_sound.stream = chimes[2]
	_table_sound.play()
	_hud.show_message("Les runes s'illuminent de bleu. Un grondement : dans un coin, le sable se disperse…")
	var tween := create_tween()
	tween.tween_property(_chest_sand, "scale", Vector3(1.4, 0.02, 1.4), 2.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_chest_sand.hide()
	_chest.show()
	var target := _book_target.global_position
	_book.global_position = target + Vector3.DOWN * 1.2
	_book.show()
	var rise := create_tween()
	rise.tween_property(_book, "global_position", target, 1.8).set_trans(Tween.TRANS_SINE)
	await rise.finished
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("L'Algonicon est à vous. Rapportez-le au château du hub : le portail du Désert s'est rouvert.")
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
