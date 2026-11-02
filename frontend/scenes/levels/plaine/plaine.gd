class_name Plaine
extends Node3D
## Zone de la Plaine : la surface et sa bibliothèque, puis l'énigme qui libère le Projenomicon.
## Seule la partie où se trouve le joueur reste affichée.

signal book_collected(book_id: StringName)
signal hub_requested

const BOOK_ID := &"projenomicon"

## Scène du hub, chargée quand le joueur repasse le portail une fois le livre récupéré.
@export_file("*.tscn") var hub_scene := ""
@export var stone_travel := 3.4
@export var stone_duration := 2.5

var _has_book := false
var _inside := false

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _puzzle: TabletPuzzle = $TabletPuzzle
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _exterior: Node3D = $Exterior
@onready var _interior: Node3D = $Interior
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

	_book_pickup.enabled = false
	_apply_location()
	_hud.show_message("La Plaine")


func _travel(inside: bool) -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_inside = inside
	_apply_location()
	var spawn := _inside_spawn if inside else _outside_spawn
	_player.global_position = spawn.global_position
	_player.velocity = Vector3.ZERO
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT


func _apply_location() -> void:
	_interior.visible = _inside
	_exterior.visible = not _inside
	_sun.visible = not _inside
	_environment.fog_enabled = not _inside


func _read(readable: Readable) -> void:
	_open_panel()
	_hud.show_text(readable.title, readable.body)


func _open_tablet() -> void:
	_open_panel()
	_puzzle.open()


func _open_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
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
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre de la Plaine.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	if hub_scene.is_empty():
		_hud.show_message("Le hub n'est pas encore relié à ce portail.")
	else:
		get_tree().change_scene_to_file(hub_scene)
