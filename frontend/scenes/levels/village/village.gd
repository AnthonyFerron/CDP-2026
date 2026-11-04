class_name Village
extends Node3D
## Zone du Village détruit par les attaques de Vibelandia : l'enceinte forcée, la place du marché, la mairie (le
## dernier bâtiment intact) et les deux moulins. L'énigme des cinq langages oubliés se joue dans la mairie : dix
## fragments de papier y sont cachés, et le dispositif du bureau du maire, une fois ses cinq codes résolus, fait
## glisser la bibliothèque devant la salle secrète du Codonomicon.

signal book_collected(book_id: StringName)

const ZONE := &"village"
const BOOK_ID := &"codonomicon"
## Tours par seconde des ailes du moulin et de la roue du moulin à eau.
const WINDMILL_SPEED := 0.05
const WHEEL_SPEED := 0.12
## Deux fragments par code : le premier explique le langage, le second aide à trouver le résultat.
const FRAGMENTS: Array[String] = [
	"Notes de l'archiviste : en HTML, <ul> ouvre une liste à puces. Chaque élément s'écrit entre <li> et </li>, et le navigateur l'affiche sur sa propre ligne.",
	"Griffonné dans une marge : tout ce qui est enfermé entre <!-- et --> n'est qu'un commentaire laissé au développeur. Le navigateur ne l'affiche jamais.",
	"Leçon de style : en CSS, un nom seul vise une balise (p), un point vise une classe (.annonce), un dièse vise un identifiant (#maire). La propriété color fixe la couleur du texte.",
	"Mot du peintre de la mairie : quand plusieurs règles CSS visent le même élément, la plus précise l'emporte. L'identifiant passe avant la classe, et la classe avant la balise.",
	"Carnet du scribe : en Python, une variable garde une valeur. « greniers = greniers + 2 » remplace l'ancienne valeur par la nouvelle.",
	"Page déchirée : en Python, seul le bloc décalé sous « if » s'exécute quand la condition est vraie ; sinon, c'est celui sous « else ». « print » affiche la valeur du moment, à la fin.",
	"Registre du trésorier : en PHP, chaque variable commence par $. L'instruction « $a += 5 » ajoute 5 à la valeur de $a.",
	"Calcul du trésorier : l'opérateur % donne le reste d'une division entière. 9 % 4 vaut 1, car 9 = 2 × 4 + 1. Le point colle deux textes, et echo les affiche.",
	"Lettre du capitaine : en TypeScript, « tours: number[] » annonce un tableau de nombres. « for (const gardes of tours) » prend chaque valeur du tableau, une à une, de la première à la dernière.",
	"Ordre de garde : « === » compare deux valeurs à l'identique. Un nombre est pair quand le reste de sa division par 2 vaut 0. « return » rend le total, que console.log affiche.",
]
## Distance parcourue par la bibliothèque qui glisse devant le passage secret.
const SHELF_TRAVEL := 3.3
## Vibration des murs à une mauvaise réponse : amplitude en mètres et durée en secondes.
const SHAKE_AMPLITUDE := 0.035
const SHAKE_TIME := 0.6
## Lumière bleutée du dispositif quand les cinq codes sont résolus.
const DEVICE_GLOW := 6.0

@export var shelf_duration := 3.0

var _inside := false
var _busy := false
## Fragments retrouvés : numéro vers texte.
var _found := {}

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _portal: Portal = $Portal
@onready var _windmill: Node3D = $WindmillRotor
@onready var _wheel: Node3D = $WaterWheel
@onready var _sun: DirectionalLight3D = $Sun
@onready var _sky_fill: DirectionalLight3D = $SkyFill
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _hall_door: Interactable = $HallDoor
@onready var _outside_spawn: Marker3D = $OutsideSpawn
@onready var _interior: Node3D = $Interior
@onready var _inside_spawn: Marker3D = $Interior/InsideSpawn
@onready var _exit: Interactable = $Interior/Exit
@onready var _fragments: Node3D = $Interior/Fragments
@onready var _storages: Node3D = $Interior/Storages
@onready var _device: Interactable = $Interior/Device/Interactable
@onready var _sections: Node3D = $Interior/Device/Sections
@onready var _shelf: Node3D = $Interior/SecretShelf
@onready var _secret_light: OmniLight3D = $Interior/SecretLight
@onready var _device_light: OmniLight3D = $Interior/Device/DeviceLight
@onready var _hall: Node3D = $Interior/Hall
@onready var _book: Node3D = $Interior/Book
@onready var _book_pickup: Interactable = $Interior/Book/Interactable
@onready var _puzzle: CodePuzzle = $CodePuzzle
@onready var _notebook: PaperNotebook = $PaperNotebook


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	_portal.travel_requested.connect(GameState.return_to_hub.bind(ZONE))
	_portal.refused.connect(_hud.show_message.bind("Le portail reste éteint : trouvez le livre du Village."))
	_hall_door.interacted.connect(_travel.bind(true))
	_exit.interacted.connect(_travel.bind(false))
	for fragment: PaperFragment in _fragments.get_children():
		fragment.interacted.connect(_on_fragment_taken.bind(fragment))
	for storage: Storage in _storages.get_children():
		storage.opened.connect(_on_storage_opened.bind(storage))
	_device.interacted.connect(_open_device)
	_puzzle.answered.connect(_on_code_answered)
	_puzzle.solved_all.connect(_on_codes_solved)
	_puzzle.closed.connect(_close_panel)
	_notebook.closed.connect(_close_panel)
	_book_pickup.interacted.connect(_on_book_taken)
	for note: Readable in $Lore.get_children():
		note.interacted.connect(_read_note.bind(note))

	_book_pickup.enabled = false
	_secret_light.visible = false
	for index in _sections.get_child_count():
		_set_section(index, Color(0.4, 0.45, 0.7), 0.6)
	_portal.is_open = GameState.has_book(BOOK_ID)
	_apply_location()
	# Le nom du lieu est déjà annoncé par la transition du portail.
	if GameState.has_book(BOOK_ID):
		_hud.show_message("Vous avez déjà trouvé le livre de cette zone : le portail est ouvert.")


func _process(delta: float) -> void:
	_windmill.rotate_object_local(Vector3.RIGHT, TAU * WINDMILL_SPEED * delta)
	_wheel.rotate_object_local(Vector3.RIGHT, -TAU * WHEEL_SPEED * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and _player.process_mode != Node.PROCESS_MODE_DISABLED and not _busy:
		get_viewport().set_input_as_handled()
		_open_panel()
		_notebook.open(found_fragments(), FRAGMENTS.size())


func found_fragments() -> Array[String]:
	var texts: Array[String] = []
	var numbers := _found.keys()
	numbers.sort()
	for number: int in numbers:
		texts.append(_found[number])
	return texts


func _travel(inside: bool) -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_inside = inside
	_apply_location()
	var spawn := _inside_spawn if inside else _outside_spawn
	_player.global_position = spawn.global_position
	_player.velocity = Vector3.ZERO
	_player.get_node("CameraPivot").rotation.y = 0.0 if inside else PI
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false
	if inside and _found.is_empty():
		_hud.show_message("La mairie de Codia. Fouillez-la : [I] ouvre le carnet des fragments retrouvés.")


func _apply_location() -> void:
	_sun.visible = not _inside
	_sky_fill.visible = not _inside
	_environment.fog_enabled = not _inside
	_interior.visible = _inside


func _on_fragment_taken(fragment: PaperFragment) -> void:
	fragment.collect()
	_found[fragment.fragment] = FRAGMENTS[fragment.fragment]
	$ChimeSound.play()
	_hud.show_message("Fragment de papier trouvé : %d / %d. [I] pour relire vos fragments." % [_found.size(), FRAGMENTS.size()])


func _on_storage_opened(had_fragment: bool, storage: Storage) -> void:
	if had_fragment:
		_hud.show_message("Vous ouvrez %s : un fragment de papier y est glissé." % storage.furniture_name)
	else:
		_hud.show_message("Vous ouvrez %s : il ne contient que de la poussière." % storage.furniture_name)


func _open_device() -> void:
	_open_panel()
	_hud.set_crosshair_visible(false)
	_puzzle.open(found_fragments())


func _read_note(note: Readable) -> void:
	_open_panel()
	_hud.show_text(note.title, note.body)


func _open_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_section(index: int, color: Color, energy: float) -> void:
	var plate := _sections.get_child(index) as MeshInstance3D
	var material := plate.get_active_material(0) as StandardMaterial3D
	material.emission = color
	material.emission_energy_multiplier = energy


func _on_code_answered(index: int, correct: bool) -> void:
	if correct:
		_set_section(index, Color(0.3, 1.0, 0.4), 2.5)
		$ChimeSound.play()
		return
	# Mauvaise réponse : la section rougit, les murs vibrent, et le volcan se rapproche de l'éruption.
	GameState.penalize()
	$RejectSound.play()
	_set_section(index, Color(1.0, 0.1, 0.05), 3.0)
	_shake_walls()
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(_set_section.bind(index, Color(0.4, 0.45, 0.7), 0.6))


## Les murs et les meubles de la mairie tremblent un instant, la vue du joueur avec eux.
func _shake_walls() -> void:
	var camera := get_viewport().get_camera_3d()
	var tween := create_tween()
	var steps := 10
	for step in steps:
		var fade := 1.0 - float(step) / steps
		var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * SHAKE_AMPLITUDE * fade
		tween.tween_property(_hall, "position", offset, SHAKE_TIME / steps)
		if camera:
			tween.parallel().tween_property(camera, "h_offset", offset.x * 1.5, SHAKE_TIME / steps)
			tween.parallel().tween_property(camera, "v_offset", offset.z * 1.5, SHAKE_TIME / steps)
	tween.tween_property(_hall, "position", Vector3.ZERO, 0.05)
	if camera:
		tween.parallel().tween_property(camera, "h_offset", 0.0, 0.05)
		tween.parallel().tween_property(camera, "v_offset", 0.0, 0.05)


## Les cinq codes résolus : intense lumière bleutée, bruit mécanique, et la bibliothèque glisse devant la salle
## secrète.
func _on_codes_solved() -> void:
	_close_panel()
	_device.enabled = false
	for index in _sections.get_child_count():
		_set_section(index, Color(0.35, 0.6, 1.0), 3.0)
	var glow := create_tween()
	glow.tween_property(_device_light, "light_energy", DEVICE_GLOW, 0.4)
	glow.tween_property(_device_light, "light_energy", DEVICE_GLOW * 0.35, 2.5)
	$RumbleSound.play()
	_hud.show_message("Le dispositif s'illumine d'une lumière bleutée. Un grondement résonne : la bibliothèque glisse et révèle un passage…")
	var tween := create_tween()
	tween.tween_property(_shelf, "position:z", _shelf.position.z + SHELF_TRAVEL, shelf_duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_secret_light.visible = true
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	# Le livre vole jusqu'à la main du joueur, qui le garde jusqu'au château.
	_player.receive_book(BOOK_ID, _book.global_position)
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le Codonomicon est à vous. Rapportez-le au château du hub : le portail du Village s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)
