class_name Plaine
extends Node3D
## Zone de la Plaine : la surface et sa bibliothèque, puis l'énigme qui libère le Projenomicon.
## Seule la partie où se trouve le joueur reste affichée.

signal book_collected(book_id: StringName)
signal hub_requested

const ZONE := &"plaine"
const BOOK_ID := &"projenomicon"
## Volume du vent dehors, et dans la bibliothèque où il n'arrive qu'étouffé.
const WIND_OUTSIDE_DB := -10.0
const WIND_INSIDE_DB := -26.0

@export var stone_travel := 3.4
@export var stone_duration := 2.5
## Calque de suie posé sur les ruines.
@export var soot_material: Material

var _has_book := false
var _inside := false
var _busy := false
var _safe_position := Vector3.ZERO
var _ash: CPUParticles3D

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _puzzle: TabletPuzzle = $TabletPuzzle
@onready var _wind: AudioStreamPlayer = $Wind
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _exterior: Node3D = $Exterior
@onready var _interior: Node3D = $Interior
@onready var _scatter: PlaineScatter = $Exterior/Scatter
@onready var _portal: Portal = $Exterior/Portal
@onready var _entry_door: Interactable = $Exterior/EntryDoor
@onready var _exit_door: Interactable = $Interior/ExitDoor
@onready var _inside_spawn: Marker3D = $Interior/InsideSpawn
@onready var _outside_spawn: Marker3D = $Exterior/OutsideSpawn
@onready var _clues: Node3D = $Interior/Clues
@onready var _tablet: Interactable = $Interior/Tablet/Interactable
@onready var _stone: Node3D = $Interior/Stone
@onready var _book: Node3D = $Interior/Book
@onready var _book_pickup: Interactable = $Interior/Book/Interactable


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)

	_entry_door.interacted.connect(_travel.bind(true))
	_exit_door.interacted.connect(_travel.bind(false))
	for clue: Readable in _clues.get_children():
		clue.interacted.connect(_read.bind(clue))

	_tablet.interacted.connect(_open_tablet)
	_puzzle.closed.connect(_close_panel)
	_puzzle.solved.connect(_on_puzzle_solved)
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)
	_scatter.lava_touched.connect(_on_lava_touched)

	_book_pickup.enabled = false
	_safe_position = _player.global_position
	_apply_soot($Exterior/Ruins)
	_apply_soot(_scatter.get_node("Lanterns"))
	_ash = _create_ash()
	_exterior.add_child(_ash)
	_apply_location()
	_hud.show_message("La Plaine")
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà rapporté le livre de cette zone : le portail est ouvert.")


func _process(_delta: float) -> void:
	_ash.global_position = _player.global_position + Vector3.UP * 6.0


func _physics_process(_delta: float) -> void:
	# Dernier endroit sûr où le joueur se tenait, pour l'y ramener s'il tombe dans la lave.
	if not _busy and not _inside and _player.is_on_floor():
		if not _scatter.is_near_lava(_player.global_position, 2.5):
			_safe_position = _player.global_position


func _travel(inside: bool) -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_inside = inside
	_apply_location()
	var spawn := _inside_spawn if inside else _outside_spawn
	_player.global_position = spawn.global_position
	_player.velocity = Vector3.ZERO
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
	_ash.emitting = not _inside
	_wind.volume_db = WIND_INSIDE_DB if _inside else WIND_OUTSIDE_DB


func _on_lava_touched(body: Node3D) -> void:
	if body != _player or _busy:
		return
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_player.global_position = _safe_position
	_player.velocity = Vector3.ZERO
	_hud.show_message("La lave vous brûle : vous reculez en hâte.")
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


func _read(readable: Readable) -> void:
	_open_panel()
	_hud.show_text(readable.title, readable.body)


func _open_tablet() -> void:
	_open_panel()
	_hud.set_crosshair_visible(false)
	_puzzle.open()


func _open_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_puzzle_solved() -> void:
	_close_panel()
	_tablet.enabled = false
	_hud.show_message("Un grondement sourd : la pierre du fond se déplace…")
	var tween := create_tween()
	tween.tween_property(_stone, "position:x", _stone.position.x - stone_travel, stone_duration)
	tween.set_trans(Tween.TRANS_SINE)
	await tween.finished
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	_has_book = true
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le Projenomicon est à vous. Le portail de la Plaine s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre de la Plaine.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	GameState.return_to_hub(ZONE)


func _apply_soot(root: Node) -> void:
	if not soot_material:
		return
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = soot_material


## Cendres qui tombent autour du joueur, pour donner de la matière à l'air.
func _create_ash() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.07)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.6, 0.55, 0.55, 0.0))
	gradient.set_color(1, Color(0.45, 0.4, 0.4, 0.0))
	gradient.add_point(0.2, Color(0.62, 0.56, 0.56, 0.85))
	gradient.add_point(0.8, Color(0.5, 0.45, 0.45, 0.7))

	var ash := CPUParticles3D.new()
	ash.mesh = quad
	ash.amount = 260
	ash.lifetime = 9.0
	ash.preprocess = 9.0
	ash.local_coords = false
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(20.0, 5.0, 20.0)
	ash.direction = Vector3(1.0, -0.4, 0.3)
	ash.spread = 30.0
	ash.gravity = Vector3(0.2, -0.35, 0.05)
	ash.initial_velocity_min = 0.2
	ash.initial_velocity_max = 0.6
	ash.color_ramp = gradient
	return ash
