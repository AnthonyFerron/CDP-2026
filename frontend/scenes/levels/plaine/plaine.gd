class_name Plaine
extends Node3D
## Les plaines d'Hexcole : le champ de bataille et l'ancienne bibliothèque, puis l'énigme des fragments du passé,
## qui libère le Projenomicon. Six fragments sont cachés dans les livres ; la tablette les remet en ordre.
## Erreur : les inscriptions virent au rouge et le sol tremble. Réussite : elles passent au vert, la dalle glisse
## et l'escalier oublié descend vers le pupitre de pierre. Seule la partie où se trouve le joueur reste affichée.

signal book_collected(book_id: StringName)
signal hub_requested

const ZONE := &"plaine"
const BOOK_ID := &"projenomicon"
## Volume du vent dehors, et dans la bibliothèque où il n'arrive qu'étouffé.
const WIND_OUTSIDE_DB := -10.0
const WIND_INSIDE_DB := -26.0
## Lumière ambiante du ciel, dehors et dans les archives.
const AMBIENT_OUTSIDE := 0.75
const AMBIENT_INSIDE := 0.5
## Décor irrégulier posé par tools/build_plaine.py sans boîte : épaves, tas de pierres, rochers, tentes,
## charrettes. Il reçoit ici l'enveloppe convexe de ses maillages, plus juste qu'une boîte.
const HULL_PROPS: Array[String] = ["siege_", "rocks_", "rock_", "resource_stone", "tower_hexagon", "tent_", "cart_"]
## Conversation entre la bibliothécaire, cheffe de projet, et son employé, dans le bon ordre.
const FRAGMENTS: Array[String] = [
	"Bibliothécaire : « Nous devons organiser la restauration des archives avant la prochaine inspection. »",
	"Employé : « Quels sont les objectifs prioritaires de cette restauration ? »",
	"Bibliothécaire : « Nous devons d'abord inventorier les ouvrages endommagés et identifier les ressources nécessaires. »",
	"Employé : « Une fois l'inventaire terminé, nous pourrons établir un planning et répartir les tâches. »",
	"Bibliothécaire : « Exactement. Nous devrons également suivre l'avancement des travaux et anticiper les éventuels retards. »",
	"Employé : « Lorsque les travaux seront terminés, nous vérifierons leur conformité avant de clôturer le projet. »",
]

@export var stone_travel := 3.4
@export var stone_duration := 2.5
## Calque de suie posé sur les ruines, et sa version plus légère pour les archives.
@export var soot_material: Material
@export var interior_soot_material: Material

const INSCRIPTION_IDLE := Color(0.13, 0.1, 0.09)
const INSCRIPTION_WRONG := Color(2.4, 0.25, 0.12)
const INSCRIPTION_RIGHT := Color(0.35, 2.2, 0.55)
const SLOTS_IDLE := Color(0.95, 0.4, 0.12)

var _has_book := false
var _inside := false
var _busy := false
var _safe_position := Vector3.ZERO
var _ash: CPUParticles3D
var _dust: CPUParticles3D
## Fragments retrouvés : numéro vers texte.
var _found := {}

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
@onready var _books: Node3D = $Interior/Books
@onready var _tablet: Interactable = $Interior/Tablet/Interactable
@onready var _tablet_top: MeshInstance3D = $Interior/Tablet/Top
@onready var _stone: Node3D = $Interior/Stone
@onready var _book: Node3D = $Interior/Book
@onready var _book_pickup: Interactable = $Interior/Book/Interactable
@onready var _inscription: Label3D = $Interior/Inscription/Text
@onready var _slot_material: StandardMaterial3D = $Interior/Tablet/Top/Slot1.mesh.material
@onready var _slab_sound: AudioStreamPlayer = $Interior/SlabSound
@onready var _rumble: AudioStreamPlayer = $Interior/Rumble
@onready var _camera: Camera3D = $Player/CameraPivot/SpringArm3D/Camera3D
@onready var _inside_ambience: AudioStreamPlayer = $Interior/InsideAmbience


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)

	_entry_door.interacted.connect(_travel.bind(true))
	_exit_door.interacted.connect(_travel.bind(false))
	for book: SearchableBook in _books.get_children():
		book.interacted.connect(_on_book_searched.bind(book))
	for note: Readable in $Exterior/Lore.get_children():
		note.interacted.connect(_read_note.bind(note))

	_tablet.interacted.connect(_open_tablet)
	_puzzle.closed.connect(_close_panel)
	_puzzle.validated.connect(_on_puzzle_validated)
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)
	_scatter.lava_touched.connect(_on_lava_touched)

	_book_pickup.enabled = false
	_safe_position = _player.global_position
	_apply_soot($Exterior/Ruins, soot_material)
	_apply_soot($Exterior/Battlefield, soot_material)
	_apply_soot(_scatter.get_node("Lanterns"), soot_material)
	_apply_soot($Interior/Library/Models, interior_soot_material)
	_add_hull_collisions($Exterior/Battlefield/Models, HULL_PROPS)
	_add_hull_collisions($Exterior/Ruins/Models, HULL_PROPS)
	_ash = _create_ash()
	_exterior.add_child(_ash)
	_dust = _create_dust()
	_interior.add_child(_dust)
	_apply_location()
	# Le nom du lieu s'affiche déjà pendant la transition du portail.
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà trouvé le livre de cette zone : le portail est ouvert.")


func _process(_delta: float) -> void:
	_ash.global_position = _player.global_position + Vector3.UP * 6.0
	_dust.global_position = _player.global_position + Vector3.UP * 1.6


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
	# Sous terre, la lumière du ciel ne descend plus : les lustres et les bougies donnent le ton.
	_environment.ambient_light_energy = AMBIENT_INSIDE if _inside else AMBIENT_OUTSIDE
	_ash.emitting = not _inside
	_dust.emitting = _inside
	_wind.volume_db = WIND_INSIDE_DB if _inside else WIND_OUTSIDE_DB
	if _inside and not _inside_ambience.playing:
		_inside_ambience.play()
	elif not _inside:
		_inside_ambience.stop()


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


## Le joueur ouvre un livre : il le lit, et y trouve parfois un fragment de la conversation.
func _on_book_searched(book: SearchableBook) -> void:
	var text := book.body
	if book.fragment >= 0:
		text += "\n\nUn morceau de papier glisse d'entre les pages :\n" + FRAGMENTS[book.fragment]
		if not _found.has(book.fragment):
			_found[book.fragment] = FRAGMENTS[book.fragment]
			_hud.show_message("Fragment de conversation trouvé : %d / %d" % [_found.size(), FRAGMENTS.size()])
	book.mark_searched()
	_open_panel()
	_hud.show_text(book.title, text)


func _read_note(note: Readable) -> void:
	_open_panel()
	_hud.show_text(note.title, note.body)


func found_fragments() -> Dictionary:
	return _found


func _open_tablet() -> void:
	_open_panel()
	_hud.set_crosshair_visible(false)
	_puzzle.open(_found)


func _open_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_puzzle_validated(correct: bool) -> void:
	if correct:
		_on_puzzle_solved()
		return
	# Mauvais ordre : les inscriptions virent au rouge, le sol tremble et le volcan se rapproche de l'éruption.
	GameState.penalize()
	_set_tablet_glow(Color(1.0, 0.1, 0.05), 3.0)
	_set_inscription(INSCRIPTION_WRONG)
	_rumble.play()
	_shake(0.9, 0.07)
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_callback(_set_tablet_glow.bind(Color(0.95, 0.3, 0.08), 0.8, true))
	tween.tween_callback(_set_inscription.bind(INSCRIPTION_IDLE))


## Lueur de la tablette et de ses six emplacements ; au repos, les emplacements gardent leur braise discrète.
func _set_tablet_glow(color: Color, energy: float, resting := false) -> void:
	var material := _tablet_top.get_active_material(0) as StandardMaterial3D
	material.emission = color
	material.emission_energy_multiplier = energy
	_slot_material.emission = SLOTS_IDLE if resting else color
	_slot_material.emission_energy_multiplier = 0.3 if resting else energy * 0.8


## Couleur des lettres gravées près de la dalle : sombres au repos, lumineuses quand la tablette répond.
func _set_inscription(color: Color) -> void:
	_inscription.modulate = color
	_inscription.shaded = color == INSCRIPTION_IDLE


## Le sol tremble : la caméra du joueur vacille, de moins en moins.
func _shake(duration: float, strength: float) -> void:
	var tween := create_tween()
	tween.tween_method(_shake_step.bind(strength), 0.0, 1.0, duration)
	tween.tween_callback(_shake_step.bind(1.0, 0.0))


func _shake_step(progress: float, strength: float) -> void:
	var amount := strength * (1.0 - progress)
	_camera.h_offset = randf_range(-amount, amount)
	_camera.v_offset = randf_range(-amount, amount)


func _on_puzzle_solved() -> void:
	_close_panel()
	_set_tablet_glow(Color(0.3, 1.0, 0.45), 3.0)
	_set_inscription(INSCRIPTION_RIGHT)
	_tablet.enabled = false
	_hud.show_message("Les inscriptions s'illuminent de vert. Un grondement monte du sol : la dalle glisse et révèle un escalier oublié…")
	_rumble.play()
	_slab_sound.play()
	_shake(stone_duration, 0.03)
	var tween := create_tween()
	tween.tween_property(_stone, "position:x", _stone.position.x - stone_travel, stone_duration)
	tween.set_trans(Tween.TRANS_SINE)
	await tween.finished
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	_has_book = true
	# Le livre vole jusqu'à la main du joueur, qui le garde jusqu'au château.
	_player.receive_book(BOOK_ID, _book.global_position)
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("Le Projenomicon est à vous. Rapportez-le au château : le portail des plaines s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre des plaines d'Hexcole.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	GameState.return_to_hub(ZONE)


## Collision de chaque modèle dont le nom commence par l'un des préfixes : l'enveloppe convexe de ses maillages.
func _add_hull_collisions(models: Node3D, prefixes: Array[String]) -> void:
	var body := StaticBody3D.new()
	body.name = "Hulls"
	models.get_parent().add_child(body)
	for model: Node3D in models.get_children():
		if not prefixes.any(func(prefix: String) -> bool: return String(model.name).begins_with(prefix)):
			continue
		var points := PackedVector3Array()
		for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var to_body := body.global_transform.affine_inverse() * part.global_transform
			for vertex in part.mesh.get_faces():
				points.append(to_body * vertex)
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.name = String(model.name)
		collision.shape = shape
		body.add_child(collision)


func _apply_soot(root: Node, material: Material) -> void:
	if not material:
		return
	# Les MultiMesh des livres sont des enfants internes : on les parcourt aussi.
	for child in root.get_children(true):
		if child is GeometryInstance3D and not child is Label3D:
			(child as GeometryInstance3D).material_overlay = material
		_apply_soot(child, material)


## Poussière des archives : des grains qui flottent lentement autour du joueur et accrochent la lumière des bougies.
func _create_dust() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = Color(0.9, 0.7, 0.45)
	material.emission_energy_multiplier = 0.25
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.025)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.9, 0.8, 0.65, 0.0))
	gradient.set_color(1, Color(0.9, 0.8, 0.65, 0.0))
	gradient.add_point(0.3, Color(0.95, 0.85, 0.7, 0.55))
	gradient.add_point(0.7, Color(0.9, 0.8, 0.65, 0.45))
	var dust := CPUParticles3D.new()
	dust.mesh = quad
	dust.amount = 90
	dust.lifetime = 8.0
	dust.preprocess = 8.0
	dust.local_coords = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(4.5, 1.4, 4.5)
	dust.direction = Vector3(0.2, 0.1, 0.1)
	dust.spread = 180.0
	dust.gravity = Vector3(0.0, 0.01, 0.0)
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.08
	dust.color_ramp = gradient
	dust.emitting = false
	return dust


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
