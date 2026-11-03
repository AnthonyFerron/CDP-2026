class_name Hub
extends Node3D
## Hub : le camp des survivants, d'où partent les portails des zones. Merlon y donne la mission,
## l'autel garde les livres rapportés, et le plateau reverdit à mesure qu'ils reviennent.

const ZONES: Array[StringName] = [&"plaine", &"desert", &"marais", &"village"]
const ZONE_NAMES := {
	&"plaine": "la Plaine",
	&"desert": "le Désert",
	&"marais": "le Marais",
	&"village": "le Village détruit",
}
## Livre que garde chaque zone.
const ZONE_BOOKS := {
	&"plaine": &"projenomicon",
	&"desert": &"algonicon",
	&"marais": &"logiconomicon",
	&"village": &"codonomicon",
}
## Distance à laquelle le joueur réapparaît devant le portail d'où il revient.
const RETURN_DISTANCE := 3.5

@export_group("Ciel sans livre")
@export var dead_sky := Color(0.3, 0.29, 0.36)
@export var dead_horizon := Color(0.5, 0.45, 0.45)
@export var dead_fog := Color(0.45, 0.42, 0.42)
@export_group("Ciel avec les quatre livres")
@export var living_sky := Color(0.33, 0.55, 0.86)
@export var living_horizon := Color(0.78, 0.82, 0.85)
@export var living_fog := Color(0.72, 0.78, 0.84)

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _terrain: HubTerrain = $Terrain
@onready var _scatter: HubScatter = $Scatter
@onready var _merlon: Readable = $Characters/Merlon
@onready var _bunker: Interactable = $Bunker
@onready var _default_spawn: Marker3D = $DefaultSpawn


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	for character: Readable in $Characters.get_children():
		character.interacted.connect(_read.bind(character))
	$Altar/Inscription.interacted.connect(_read.bind($Altar/Inscription))
	_bunker.interacted.connect(_on_bunker)
	for zone in ZONES:
		var portal := _portal(zone)
		portal.is_open = GameState.is_zone_built(zone)
		portal.travel_requested.connect(GameState.enter_zone.bind(zone))
		portal.refused.connect(_hud.show_message.bind("Le passage vers %s n'est pas encore ouvert." % ZONE_NAMES[zone]))
		_altar_book(zone).visible = GameState.has_book(ZONE_BOOKS[zone])
	_apply_life(float(GameState.books.size()) / GameState.BOOK_COUNT)
	_place_player()
	_hud.show_message(_arrival_message())


func book_count() -> int:
	return GameState.books.size()


func _portal(zone: StringName) -> Portal:
	return get_node("Portals/" + String(zone).capitalize())


func _altar_book(zone: StringName) -> Node3D:
	return get_node("Altar/" + String(zone).capitalize() + "/Book")


## Fait réapparaître le joueur devant le portail d'où il revient, tourné vers le camp.
func _place_player() -> void:
	var position := _default_spawn.global_position
	if GameState.last_zone in ZONES:
		var portal := _portal(GameState.last_zone)
		var toward_camp := -Vector3(portal.global_position.x, 0.0, portal.global_position.z).normalized()
		position = portal.global_position + toward_camp * RETURN_DISTANCE
		position.y = _terrain.height_at(position.x, position.z) + 0.3
	var look := -Vector3(position.x, 0.0, position.z).normalized() if position.length() > 1.0 else Vector3.FORWARD
	_player.global_position = position
	_player.get_node("CameraPivot").rotation.y = atan2(-look.x, -look.z)


## Ciel, brume, lumière, herbe et fleurs suivent les livres rapportés : de 0 à 1.
func _apply_life(life: float) -> void:
	var sky := _environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = dead_sky.lerp(living_sky, life)
	sky.sky_horizon_color = dead_horizon.lerp(living_horizon, life)
	sky.ground_horizon_color = sky.sky_horizon_color
	_environment.fog_light_color = dead_fog.lerp(living_fog, life)
	_environment.fog_density = lerpf(0.02, 0.006, life)
	_environment.ambient_light_energy = lerpf(0.5, 0.85, life)
	_sun.light_energy = lerpf(0.55, 1.2, life)
	(_terrain.ground_material as ShaderMaterial).set_shader_parameter("life", life)
	_scatter.set_life(life)


func _arrival_message() -> String:
	if GameState.last_zone in ZONES and GameState.has_book(ZONE_BOOKS[GameState.last_zone]):
		return "Le livre de %s repose sur l'autel." % ZONE_NAMES[GameState.last_zone]
	return "Le camp des survivants"


func _merlon_text() -> String:
	var count := book_count()
	if count == 0:
		return "Devlyn, mon vieil ami. Le volcan endormi près du royaume se réveille : la guerre a rompu son équilibre. J'ai eu une vision : quatre ouvrages oubliés, l'Algonicon, le Projenomicon, le Logiconomicon et le Codonomicon, peuvent apaiser sa colère et rendre vie à Codia. Chacun repose au-delà d'un de ces portails. Rapporte-les sur l'autel avant l'éruption, et nous accomplirons le rituel."
	if count >= GameState.BOOK_COUNT:
		return "Les quatre livres sont réunis. Écoute… le volcan se tait, et Codia respire à nouveau. Le rituel peut commencer."
	var missing: Array[String] = []
	for zone in ZONES:
		if not GameState.has_book(ZONE_BOOKS[zone]):
			missing.append(ZONE_NAMES[zone])
	return "Tu as rapporté %d livre%s sur quatre. Regarde : l'herbe repousse déjà autour du camp. Mais le volcan gronde encore : il te reste %s." % [
		count, "s" if count > 1 else "", ", ".join(missing)
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
	if book_count() >= GameState.BOOK_COUNT:
		_hud.show_message("La grille du bunker se soulève dans un grondement…")
	else:
		_hud.show_message("Le bunker est scellé. Il ne s'ouvrira qu'avec les quatre livres (%d / %d)." % [book_count(), GameState.BOOK_COUNT])
