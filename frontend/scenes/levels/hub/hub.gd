class_name Hub
extends Node3D
## Hub : le village de Codia, d'où partent les portails des zones. Merlon y donne la mission, les livres
## se posent sur leurs piédestaux dans la salle du château, et le village se reconstruit à chaque livre posé.

const ZONES: Array[StringName] = [&"plaine", &"desert", &"marais", &"village"]
const ZONE_NAMES := {
	&"plaine": "la Plaine",
	&"desert": "le Désert",
	&"marais": "le Marais",
	&"village": "le Village détruit",
}
## Distance à laquelle le joueur réapparaît devant le portail d'où il revient.
const RETURN_DISTANCE := 3.5
## Durée du plan large sur le village qui se reconstruit, en secondes.
const REPAIR_SHOT := 4.0

@export_group("Ciel sans livre")
@export var dead_sky := Color(0.3, 0.29, 0.36)
@export var dead_horizon := Color(0.5, 0.45, 0.45)
@export var dead_fog := Color(0.45, 0.42, 0.42)
@export_group("Ciel avec les quatre livres")
@export var living_sky := Color(0.33, 0.55, 0.86)
@export var living_horizon := Color(0.78, 0.82, 0.85)
@export var living_fog := Color(0.62, 0.7, 0.78)

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _terrain: HubTerrain = $Terrain
@onready var _scatter: HubScatter = $Scatter
@onready var _merlon: Readable = $Characters/Merlon
@onready var _bunker: Interactable = $Bunker
@onready var _default_spawn: Marker3D = $DefaultSpawn
@onready var _repairs: Node3D = $Props/Repairs
@onready var _repair_camera: Camera3D = $RepairCamera
@onready var _player_camera: Camera3D = $Player/CameraPivot/SpringArm3D/Camera3D
@onready var _volcano: Volcano = $Volcano
@onready var _ending: HubEnding = $Ending

var _life := 0.0


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	for character: Readable in $Characters.get_children():
		character.interacted.connect(_read.bind(character))
	$Castle/Inscription.interacted.connect(_read.bind($Castle/Inscription))
	_bunker.interacted.connect(_on_bunker)
	for zone in ZONES:
		var portal := _portal(zone)
		portal.closed_prompt = _closed_prompt(zone)
		portal.is_open = GameState.is_zone_unlocked(zone)
		portal.travel_requested.connect(GameState.enter_zone.bind(zone))
		portal.refused.connect(func() -> void: _hud.show_message(_closed_message(zone)))
		_pedestal(zone).interacted.connect(_on_pedestal.bind(zone))
		_pedestal_book(zone).visible = GameState.has_placed(GameState.ZONE_BOOKS[zone])
	_refresh_pedestals()
	_set_repairs(placed_count(), false)
	_life = float(placed_count()) / GameState.BOOK_COUNT
	_apply_life(_life)
	_place_player()
	_volcano.set_state(Volcano.State.DORMANT if placed_count() >= GameState.BOOK_COUNT else Volcano.State.AWAKE)
	if GameState.ending != &"":
		_play_ending(GameState.ending)
		return
	_hud.show_message(_arrival_message())


## Joue une fin : le joueur et l'interface s'effacent derrière la caméra de la cinématique.
func _play_ending(ending: StringName) -> void:
	GameState.ending = &""
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if ending == &"victory":
		_set_repairs(GameState.BOOK_COUNT, false)
		_apply_life(1.0)
		_ending.play_victory()
	else:
		_ending.play_eruption()


func placed_count() -> int:
	return GameState.placed_books.size()


func _portal(zone: StringName) -> Portal:
	return get_node("Portals/" + String(zone).capitalize())


func _pedestal(zone: StringName) -> Interactable:
	return get_node("Castle/Pedestals/" + String(zone).capitalize())


func _pedestal_book(zone: StringName) -> Node3D:
	return _pedestal(zone).get_node("Book")


func _book_name(zone: StringName) -> String:
	return GameState.BOOK_NAMES[GameState.ZONE_BOOKS[zone]]


func _closed_prompt(zone: StringName) -> String:
	if not GameState.is_zone_built(zone) or GameState.previous_zone(zone).is_empty():
		return "%s : bientôt accessible" % ZONE_NAMES[zone].capitalize()
	return "%s : terminez d'abord %s" % [ZONE_NAMES[zone].capitalize(), ZONE_NAMES[GameState.previous_zone(zone)]]


func _closed_message(zone: StringName) -> String:
	if not GameState.is_zone_built(zone):
		return "Le passage vers %s n'est pas encore ouvert." % ZONE_NAMES[zone]
	var previous := GameState.previous_zone(zone)
	return "Le portail vers %s s'ouvrira quand %s aura été retrouvé, dans %s." % [ZONE_NAMES[zone], _book_name(previous), ZONE_NAMES[previous]]


## Fait réapparaître le joueur devant le portail d'où il revient, tourné vers le village.
func _place_player() -> void:
	var position := _default_spawn.global_position
	if GameState.last_zone in ZONES:
		var portal := _portal(GameState.last_zone)
		var toward_camp := -Vector3(portal.global_position.x, 0.0, portal.global_position.z).normalized()
		position = portal.global_position + toward_camp * RETURN_DISTANCE
		position.y = _terrain.surface_height(position.x, position.z) + 0.3
	var look := -Vector3(position.x, 0.0, position.z).normalized() if position.length() > 1.0 else Vector3.FORWARD
	_player.global_position = position
	_player.get_node("CameraPivot").rotation.y = atan2(-look.x, -look.z)


## Ciel, brume, lumière, herbe et fleurs suivent les livres posés : de 0 à 1.
func _apply_life(life: float) -> void:
	var sky := _environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = dead_sky.lerp(living_sky, life)
	sky.sky_horizon_color = dead_horizon.lerp(living_horizon, life)
	sky.ground_horizon_color = sky.sky_horizon_color
	# Sous l'horizon, le ciel prolonge la brume au lieu de laisser une bande de sol vide derrière les montagnes.
	sky.ground_bottom_color = sky.sky_horizon_color.darkened(0.15)
	_environment.fog_light_color = dead_fog.lerp(living_fog, life)
	_environment.fog_density = lerpf(0.014, 0.004, life)
	_environment.ambient_light_energy = lerpf(0.5, 0.7, life)
	_sun.light_energy = lerpf(0.55, 1.0, life)
	(_terrain.ground_material as ShaderMaterial).set_shader_parameter("life", life)
	_scatter.set_life(life)


## Montre la version reconstruite des éléments dont le palier est atteint, la ruine des autres.
## Les éléments qui viennent d'être réparés s'élèvent du sol.
func _set_repairs(count: int, animate: bool) -> Array[Node3D]:
	var repaired: Array[Node3D] = []
	for item: Node3D in _repairs.get_children():
		var done: bool = count >= int(item.get_meta(&"stage", 1))
		var rebuilt := item.get_node_or_null("Rebuilt") as Node3D
		var ruins := item.get_node_or_null("Ruins") as Node3D
		if animate and done and rebuilt and not rebuilt.visible:
			repaired.append(item)
		for part: Node3D in [rebuilt, ruins]:
			if part:
				var shown := done == (part == rebuilt)
				part.visible = shown
				part.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
	for item in repaired:
		var rebuilt: Node3D = item.get_node("Rebuilt")
		rebuilt.scale = Vector3(1.0, 0.02, 1.0)
		create_tween().tween_property(rebuilt, "scale", Vector3.ONE, REPAIR_SHOT * 0.7) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.4)
	return repaired


func _refresh_pedestals() -> void:
	for zone in ZONES:
		var book: StringName = GameState.ZONE_BOOKS[zone]
		var pedestal := _pedestal(zone)
		if GameState.has_placed(book):
			pedestal.prompt = "%s repose ici" % _book_name(zone).capitalize()
		elif GameState.has_book(book):
			pedestal.prompt = "Poser %s" % _book_name(zone)
		else:
			pedestal.prompt = "Piédestal de %s" % _book_name(zone)


func _on_pedestal(zone: StringName) -> void:
	var book: StringName = GameState.ZONE_BOOKS[zone]
	if GameState.has_placed(book):
		_hud.show_message("%s repose sur son piédestal." % _book_name(zone).capitalize())
		return
	if not GameState.has_book(book):
		_hud.show_message("Ce piédestal attend %s, caché dans %s." % [_book_name(zone), ZONE_NAMES[zone]])
		return
	GameState.place_book(book)
	var shown := _pedestal_book(zone)
	shown.visible = true
	shown.scale = Vector3.ONE * 0.2
	create_tween().tween_property(shown, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	$PlaceSound.play()
	_refresh_pedestals()
	_show_repairs()


## Plan large sur le village le temps qu'il se reconstruise, puis retour au joueur.
func _show_repairs() -> void:
	var repaired := _set_repairs(placed_count(), true)
	var life := float(placed_count()) / GameState.BOOK_COUNT
	create_tween().tween_method(_apply_life, _life, life, REPAIR_SHOT)
	_life = life
	if placed_count() >= GameState.BOOK_COUNT:
		_hud.show_message("Les quatre livres sont réunis. Codia renaît : le rituel peut commencer.")
	else:
		_hud.show_message("Le village reprend vie… %d livre%s sur quatre." % [placed_count(), "s" if placed_count() > 1 else ""])
	if repaired.is_empty():
		return
	$RepairSound.play()
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_repair_camera.current = true
	await get_tree().create_timer(REPAIR_SHOT).timeout
	_player_camera.current = true
	_player.process_mode = Node.PROCESS_MODE_INHERIT


func _arrival_message() -> String:
	var carried := GameState.carried_books()
	if not carried.is_empty():
		var names: Array[String] = []
		for book in carried:
			names.append(GameState.BOOK_NAMES[book])
		return "Vous portez %s. Posez-le sur son piédestal, dans la salle du château, au nord." % " et ".join(names)
	return "Le village de Codia"


func _merlon_text() -> String:
	var placed := placed_count()
	if GameState.books.is_empty():
		return "Devlyn, mon vieil ami. Le volcan endormi près du royaume se réveille : la guerre a rompu son équilibre. J'ai eu une vision : quatre ouvrages oubliés, l'Algonicon, le Projenomicon, le Logiconomicon et le Codonomicon, peuvent apaiser sa colère et rendre vie à Codia. Chacun repose au-delà d'un de ces portails, et chaque portail ne s'ouvre qu'une fois le livre du précédent retrouvé. Commence par la Plaine. Rapporte chaque livre dans la salle du château, sur son piédestal, avant l'éruption."
	if placed >= GameState.BOOK_COUNT:
		return "Les quatre livres sont réunis. Écoute… le volcan se tait, et Codia respire à nouveau. Le rituel peut commencer."
	if not GameState.carried_books().is_empty():
		return "Tu portes un livre, Devlyn. Ne le garde pas : va le poser sur son piédestal, dans la salle du château. Chaque livre posé rend un peu de vie au village."
	var next := ""
	for zone in ZONES:
		if not GameState.has_book(GameState.ZONE_BOOKS[zone]):
			next = zone
			break
	return "Tu as posé %d livre%s sur quatre. Regarde : les maisons se relèvent déjà. Mais le volcan gronde encore : le portail vers %s t'attend." % [
		placed, "s" if placed > 1 else "", ZONE_NAMES[next]
	]


func _read(readable: Readable) -> void:
	if readable == _merlon:
		readable.body = _merlon_text()
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_text(readable.title, readable.body)


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_bunker() -> void:
	if placed_count() >= GameState.BOOK_COUNT:
		_hud.show_message("La porte du bunker se déverrouille dans un grondement…")
	else:
		_hud.show_message("Le bunker est scellé. Sa porte ne cède à rien pour l'instant.")
