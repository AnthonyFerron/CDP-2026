class_name Hub
extends Node3D
## Hub : le village de Codia, d'où partent les portails des zones. La partie commence dans le bunker, où les
## survivants s'abritent : le roi et Merlon y confient la mission. Les livres se posent sur leurs piédestaux,
## dans la salle du château, et le village se reconstruit à chaque livre posé. Tous les habitants restent au
## bunker jusqu'au quatrième livre : ils en sortent alors, et Merlon accomplit le rituel au château.

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
## Après la bonne fin, le joueur reprend la main devant le château, tourné vers le village.
const VICTORY_SPAWN := Vector3(0.0, 0.3, -60.0)
## Temps laissé au titre de la bonne fin avant de rendre la main, en secondes.
const VICTORY_TITLE_HOLD := 3.5
## Les deux personnages à écouter avant de sortir du bunker la première fois.
const INTRO_SPEAKERS: Array[StringName] = [&"Codeon", &"Merlon"]

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
@onready var _king: Readable = $Characters/Codeon
@onready var _bunker: Interactable = $Bunker
@onready var _bunker_exit: Interactable = $BunkerInterior/Exit
@onready var _bunker_spawn: Marker3D = $BunkerInterior/Spawn
@onready var _bunker_outside: Marker3D = $BunkerOutside
@onready var _default_spawn: Marker3D = $DefaultSpawn
@onready var _repairs: Node3D = $Props/Repairs
@onready var _repair_camera: Camera3D = $RepairCamera
@onready var _player_camera: Camera3D = $Player/CameraPivot/SpringArm3D/Camera3D
@onready var _volcano: Volcano = $Volcano
@onready var _ending: HubEnding = $Ending

var _life := 0.0
var _inside := false
var _busy := false
## Personnages de l'introduction déjà écoutés.
var _heard: Array[StringName] = []


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	for character: Readable in $Characters.get_children():
		character.interacted.connect(_read.bind(character))
	$Castle/Inscription.interacted.connect(_read.bind($Castle/Inscription))
	for sign: Readable in $Lore.get_children().filter(func(node: Node) -> bool: return node is Readable):
		sign.interacted.connect(_read.bind(sign))
	_bunker.interacted.connect(_travel.bind(true))
	_bunker_exit.interacted.connect(_on_bunker_exit)
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
	if placed_count() >= GameState.BOOK_COUNT:
		_release_survivors()
	_place_player()
	_volcano.set_state(Volcano.State.DORMANT if placed_count() >= GameState.BOOK_COUNT else Volcano.State.AWAKE)
	if GameState.ending != &"":
		_play_ending(GameState.ending)
		return
	if not GameState.intro_done:
		_hud.show_message("Le bunker des survivants. Le roi et Merlon vous attendent.")
	elif GameState.is_victory_pending():
		_hud.show_message("Les quatre livres sont posés, mais la victoire n'est pas encore validée : approchez-vous d'un piédestal du château.")
	else:
		_hud.show_message(_arrival_message())


## Joue une fin : le joueur et l'interface s'effacent derrière la caméra de la cinématique.
func _play_ending(ending: StringName) -> void:
	GameState.ending = &""
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_location(false)
	if ending == &"victory":
		_release_survivors()
		_set_repairs(GameState.BOOK_COUNT, false)
		_apply_life(1.0)
		await _ending.play_victory()
		await get_tree().create_timer(VICTORY_TITLE_HOLD).timeout
		_resume_after_victory()
	else:
		_ending.play_eruption()


## Fin de la cinématique de victoire : le joueur reprend la main devant le château, et tous les portails
## restent ouverts pour revisiter les zones.
func _resume_after_victory() -> void:
	_hud.visible = true
	await _hud.fade(true)
	_ending.stop()
	_player_camera.current = true
	var position := VICTORY_SPAWN
	position.y = _terrain.surface_height(position.x, position.z) + 0.3
	_player.global_position = position
	_player.velocity = Vector3.ZERO
	_player.get_node("CameraPivot").rotation.y = PI
	for zone in ZONES:
		_portal(zone).is_open = GameState.is_zone_unlocked(zone)
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	await _hud.fade(false)
	_hud.show_message("Codia renaît. Les portails restent ouverts : explorez le royaume à votre guise.")


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
	return "%s : posez d'abord %s au château" % [ZONE_NAMES[zone].capitalize(), _book_name(GameState.previous_zone(zone))]


func _closed_message(zone: StringName) -> String:
	if not GameState.is_zone_built(zone):
		return "Le passage vers %s n'est pas encore ouvert." % ZONE_NAMES[zone]
	var previous := GameState.previous_zone(zone)
	var book: StringName = GameState.ZONE_BOOKS[previous]
	if GameState.has_book(book):
		return "Le portail vers %s s'ouvrira quand %s sera posé sur son piédestal, au château." % [ZONE_NAMES[zone], _book_name(previous)]
	return "Le portail vers %s s'ouvrira quand %s, caché dans %s, sera posé au château." % [ZONE_NAMES[zone], _book_name(previous), ZONE_NAMES[previous]]


## Les habitants quittent le bunker : chacun rejoint son repère, Merlon et le roi au château, les autres sur la place.
func _release_survivors() -> void:
	for character: Node3D in $Characters.get_children():
		character.global_transform = get_node("Spots/%sOutside" % character.name).global_transform


## Fait apparaître le joueur dans le bunker au début de la partie, ou devant le portail d'où il revient.
func _place_player() -> void:
	if not GameState.intro_done:
		_set_location(true)
		_player.global_position = _bunker_spawn.global_position
		_player.get_node("CameraPivot").rotation.y = 0.0
		return
	_set_location(false)
	var position := _default_spawn.global_position
	if GameState.last_zone in ZONES:
		var portal := _portal(GameState.last_zone)
		var toward_camp := -Vector3(portal.global_position.x, 0.0, portal.global_position.z).normalized()
		position = portal.global_position + toward_camp * RETURN_DISTANCE
		position.y = _terrain.surface_height(position.x, position.z) + 0.3
	var look := -Vector3(position.x, 0.0, position.z).normalized() if position.length() > 1.0 else Vector3.FORWARD
	_player.global_position = position
	_player.get_node("CameraPivot").rotation.y = atan2(-look.x, -look.z)


## Dans l'abri, ni soleil ni brume : seules ses lampes l'éclairent.
func _set_location(inside: bool) -> void:
	_inside = inside
	_sun.visible = not inside
	_environment.fog_enabled = not inside
	$Ambience.volume_db = -20.0 if inside else -8.0


func _travel(inside: bool) -> void:
	if _busy:
		return
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_set_location(inside)
	var spot: Marker3D = _bunker_spawn if inside else _bunker_outside
	_player.global_position = spot.global_position
	_player.velocity = Vector3.ZERO
	# Dedans, face au fond de l'abri ; dehors, tourné vers le village.
	var look := Vector3.FORWARD if inside else -Vector3(spot.global_position.x, 0.0, spot.global_position.z).normalized()
	_player.get_node("CameraPivot").rotation.y = atan2(-look.x, -look.z)
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


## La première sortie attend que le roi et Merlon aient confié la mission.
func _on_bunker_exit() -> void:
	if not GameState.intro_done:
		var missing: Array[String] = []
		for speaker in INTRO_SPEAKERS:
			if not speaker in _heard:
				missing.append("au roi" if speaker == &"Codeon" else "à Merlon")
		_hud.show_message("Avant de partir, parlez %s." % " et ".join(missing))
		return
	await _travel(false)
	if GameState.books.is_empty():
		_hud.show_message("Le portail de la Plaine vous attend, au nord-ouest du village.")


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


## Le livre quitte la main du joueur et vole jusqu'à son piédestal ; le village se relève, puis, au quatrième,
## Merlon accomplit le rituel.
func _on_pedestal(zone: StringName) -> void:
	var book: StringName = GameState.ZONE_BOOKS[zone]
	if _busy:
		return
	# Livres posés, mais la victoire n'a pas encore pu être validée par le serveur : nouvel essai.
	if GameState.is_victory_pending():
		_ritual()
		return
	if GameState.has_placed(book):
		_hud.show_message("%s repose sur son piédestal." % _book_name(zone).capitalize())
		return
	if not GameState.has_book(book):
		_hud.show_message("Ce piédestal attend %s, caché dans %s." % [_book_name(zone), ZONE_NAMES[zone]])
		return
	_busy = true
	# Partie connectée : le livre n'est posé qu'une fois le dépôt enregistré par le serveur.
	var placed: Dictionary = await GameState.request_place_book(book)
	if not placed.ok:
		_busy = false
		if not placed.get("stale", false):
			_hud.show_message("Le livre n'a pas pu être posé : %s" % placed.get("error", "réessayez."))
		return
	_refresh_pedestals()
	var shown := _pedestal_book(zone)
	await _player.give_book(book, shown.global_position)
	shown.visible = true
	shown.scale = Vector3.ONE * 0.2
	create_tween().tween_property(shown, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	$PlaceSound.play()
	for next in ZONES:
		_portal(next).is_open = GameState.is_zone_unlocked(next)
	await _show_repairs()
	_busy = false
	if placed_count() >= GameState.BOOK_COUNT:
		_ritual()


## Plan large sur le village le temps qu'il se reconstruise, puis retour au joueur.
func _show_repairs() -> void:
	var repaired := _set_repairs(placed_count(), true)
	var life := float(placed_count()) / GameState.BOOK_COUNT
	create_tween().tween_method(_apply_life, _life, life, REPAIR_SHOT)
	_life = life
	if placed_count() >= GameState.BOOK_COUNT:
		_hud.show_message("Les quatre livres sont réunis.")
	else:
		var next := ZONES[placed_count()]
		_hud.show_message("Le village reprend vie… %d livre%s sur quatre. Le portail vers %s s'est ouvert." % [
			placed_count(), "s" if placed_count() > 1 else "", ZONE_NAMES[next]])
	if repaired.is_empty():
		return
	$RepairSound.play()
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_repair_camera.current = true
	await get_tree().create_timer(REPAIR_SHOT).timeout
	_player_camera.current = true
	_player.process_mode = Node.PROCESS_MODE_INHERIT


## Le rituel, dans la salle du château : les habitants sortent du bunker, Merlon lève son bâton, puis la bonne fin se joue.
func _ritual() -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	# Partie connectée : la victoire n'est jouée qu'une fois validée par le serveur, qui vérifie les quatre
	# dépôts et le temps restant, et fige le temps du classement.
	if GameSync.is_tracking():
		_hud.show_message("Validation de la victoire…")
	var victory: Dictionary = await GameState.request_victory()
	if not victory.ok:
		_busy = false
		if GameState.has_erupted:
			return
		_player.process_mode = Node.PROCESS_MODE_INHERIT
		_hud.show_message("La victoire n'a pas pu être validée : %s Approchez-vous d'un piédestal pour réessayer." % victory.get("error", ""))
		return
	_busy = false
	await _hud.fade(true)
	_release_survivors()
	await _hud.fade(false)
	_hud.show_message("Les survivants sortent du bunker. Merlon lève son bâton au-dessus des quatre livres : le rituel commence…")
	var orb: OmniLight3D = _merlon.get_node("Wizard/OrbLight")
	create_tween().tween_property(orb, "light_energy", 12.0, 2.5)
	await get_tree().create_timer(3.0).timeout
	_play_ending(&"victory")


func _arrival_message() -> String:
	var carried := GameState.carried_books()
	if not carried.is_empty():
		var names: Array[String] = []
		for book in carried:
			names.append(GameState.BOOK_NAMES[book])
		return "Vous portez %s. Posez-le sur son piédestal, dans la salle du château, au nord." % " et ".join(names)
	return "Le village de Codia"


func _king_text() -> String:
	if not GameState.intro_done:
		return "Devlyn, approche. Depuis la guerre, ce qui reste de Codia se terre dans ce bunker. Et voilà que le volcan s'est réveillé : s'il entre en éruption, plus rien ne survivra là-haut. Merlon connaît un moyen de l'apaiser, écoute-le. Tu as déjà sauvé ces terres des Quatre Dragons du Chaos. Je n'ai pas le droit de te le demander une seconde fois… et pourtant, je le fais."
	if placed_count() >= GameState.BOOK_COUNT:
		return "Les quatre livres sont réunis. Codia te doit sa seconde vie, Devlyn."
	return "Pose chaque livre sur son piédestal, dans la salle du château, devant mon trône. Chaque livre posé ouvre le portail suivant. Quand les quatre seront réunis, nous sortirons tous de ce bunker, et Merlon accomplira le rituel."


func _merlon_text() -> String:
	var placed := placed_count()
	if not GameState.intro_done or GameState.books.is_empty():
		return "Devlyn, mon vieil ami. La guerre a rompu l'équilibre du volcan. J'ai eu une vision : quatre ouvrages oubliés, le Projenomicon, l'Algonicon, le Logiconomicon et le Codonomicon, peuvent apaiser sa colère et rendre vie à Codia. Chacun repose au-delà d'un portail du village. Rapporte chaque livre au château du roi et pose-le sur son piédestal : le portail suivant s'ouvrira alors. Quand les quatre seront réunis, j'accomplirai le rituel. Commence par la Plaine, et fais vite : le volcan n'attendra pas."
	if placed >= GameState.BOOK_COUNT:
		return "Les quatre livres sont réunis. Écoute… le volcan se tait, et Codia respire à nouveau."
	if GameState.books.size() >= GameState.BOOK_COUNT:
		return "Te voilà ! J'ai senti le quatrième livre s'éveiller. Pose les livres qui te restent sur leurs piédestaux : dès que les quatre seront réunis, nous remonterons tous, et j'accomplirai le rituel au château."
	if not GameState.carried_books().is_empty():
		return "Tu portes un livre, Devlyn. Ne le garde pas : va le poser sur son piédestal, dans la salle du château. Le portail suivant ne s'ouvrira qu'à ce moment-là."
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
	elif readable == _king:
		readable.body = _king_text()
	if not GameState.intro_done and StringName(readable.name) in INTRO_SPEAKERS and not StringName(readable.name) in _heard:
		_heard.append(StringName(readable.name))
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_text(readable.title, readable.body)


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not GameState.intro_done and _heard.size() == INTRO_SPEAKERS.size():
		GameState.begin_mission()
		_hud.show_message("La mission commence : le volcan gronde. Remontez à la surface par la porte du bunker.")
