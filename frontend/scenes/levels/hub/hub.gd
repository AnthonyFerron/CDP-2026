class_name Hub
extends Node3D
## Hub : le village de Codia, d'où partent les portails des zones. La partie commence dans le bunker, où les
## survivants s'abritent : le roi et Merlon y confient la mission. Les livres se posent sur leurs piédestaux,
## autour du cercle magique de la salle du trône, et le village se reconstruit à chaque livre posé. Tous les
## habitants restent au bunker jusqu'au quatrième livre : ils en sortent alors, et Merlon accomplit le rituel.

const ZONES: Array[StringName] = [&"plaine", &"desert", &"marais", &"village"]
const ZONE_NAMES := {
	&"plaine": "les plaines d'Hexcole",
	&"desert": "le désert de Pythania",
	&"marais": "les marais de Kernel Swamp",
	&"village": "le village détruit",
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
## Couleur des lettres du cercle magique, éteintes (gravées) et allumées par leur livre.
const LETTER_DARK := Color(0.22, 0.2, 0.19)
const LETTER_LIT := Color(0.62, 0.86, 1.0)
## Bras de Merlon levés pendant l'incantation : rotation des os des bras.
const ARMS_RAISED := {&"arm-left": Vector3(-0.35, -0.3, 1.25), &"arm-right": Vector3(-0.35, 0.3, -1.25)}

@export_group("Ciel sans livre")
@export var dead_sky := Color(0.3, 0.29, 0.36)
@export var dead_horizon := Color(0.5, 0.45, 0.45)
@export var dead_fog := Color(0.45, 0.42, 0.42)
@export_group("Ciel de cendres, avant le rituel")
@export var ash_sky := Color(0.2, 0.15, 0.15)
@export var ash_horizon := Color(0.72, 0.3, 0.16)
@export var ash_fog := Color(0.42, 0.28, 0.24)
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
@onready var _river: HubRiver = $River
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
@onready var _circle: Node3D = $Castle/Circle

var _life := 0.0
var _inside := false
var _busy := false
## Personnages de l'introduction déjà écoutés.
var _heard: Array[StringName] = []
## Cendres dans le ciel et secousses : 1 quand les quatre livres sont trouvés mais pas encore posés.
var _ash := 0.0
var _next_tremor := 6.0
var _tremor := 0.0


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
	_refresh_circle()
	_animate_characters()
	_set_repairs(placed_count(), false)
	_life = float(placed_count()) / GameState.BOOK_COUNT
	_ash = _ash_target()
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
	elif not _arrival_message().is_empty():
		_hud.show_message(_arrival_message())


func _process(delta: float) -> void:
	# Le Mont Sam Altan gronde quand les quatre livres sont trouvés : de courtes secousses, de temps en temps.
	if _ash <= 0.0 or _inside or not _player_camera.current:
		_player_camera.h_offset = 0.0
		_player_camera.v_offset = 0.0
		return
	_next_tremor -= delta
	if _next_tremor <= 0.0:
		_next_tremor = randf_range(9.0, 16.0)
		_tremor = 1.1
		$TremorSound.play()
	if _tremor > 0.0:
		_tremor = maxf(_tremor - delta, 0.0)
		var strength := _tremor * 0.06 * _ash
		_player_camera.h_offset = randf_range(-1.0, 1.0) * strength
		_player_camera.v_offset = randf_range(-1.0, 1.0) * strength
	else:
		_player_camera.h_offset = 0.0
		_player_camera.v_offset = 0.0


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
		_ash = 0.0
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


## Première lettre en majuscule, sans toucher au reste (String.capitalize changerait « d'Hexcole »).
static func _upper_first(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


func _closed_prompt(zone: StringName) -> String:
	if not GameState.is_zone_built(zone) or GameState.previous_zone(zone).is_empty():
		return "%s : bientôt accessible" % _upper_first(ZONE_NAMES[zone])
	return "%s : posez d'abord %s au château" % [_upper_first(ZONE_NAMES[zone]), _book_name(GameState.previous_zone(zone))]


func _closed_message(zone: StringName) -> String:
	if not GameState.is_zone_built(zone):
		return "Le passage vers %s n'est pas encore ouvert." % ZONE_NAMES[zone]
	var previous := GameState.previous_zone(zone)
	var book: StringName = GameState.ZONE_BOOKS[previous]
	if GameState.has_book(book):
		return "Le portail vers %s s'ouvrira quand %s sera posé sur son piédestal, dans la salle du trône." % [ZONE_NAMES[zone], _book_name(previous)]
	return "Le portail vers %s s'ouvrira quand %s, caché dans %s, sera posé au château." % [ZONE_NAMES[zone], _book_name(previous), ZONE_NAMES[previous]]


## Les habitants quittent le bunker : chacun rejoint son repère, Merlon et le roi au château, les autres sur la place.
func _release_survivors() -> void:
	for character: Node3D in $Characters.get_children():
		character.global_transform = get_node("Spots/%sOutside" % character.name).global_transform


## Chaque personnage joue sa pose en boucle : le roi et Merlon tiennent sceptre et bâton, les autres respirent,
## chacun décalé dans son animation pour ne pas bouger ensemble.
func _animate_characters() -> void:
	var index := 0
	for character: Node3D in $Characters.get_children():
		var player := character.get_node_or_null("Model/AnimationPlayer") as AnimationPlayer
		if not player:
			continue
		var pose: StringName = character.get_meta(&"pose", &"idle")
		var animation := player.get_animation(pose)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR
		player.play(pose)
		player.speed_scale = 0.85 + 0.07 * (index % 4)
		player.seek(fmod(index * 0.37, maxf(animation.length if animation else 1.0, 0.01)), true)
		index += 1


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
		_hud.show_message("Le portail des plaines d'Hexcole vous attend au nord-ouest du village, non loin des ruines du château.")


## Cendres : le ciel s'assombrit et rougeoit quand le quatrième livre est trouvé, jusqu'au rituel.
func _ash_target() -> float:
	return 1.0 if GameState.books.size() >= GameState.BOOK_COUNT and placed_count() < GameState.BOOK_COUNT else 0.0


## Ciel, brume, lumière, herbe, eau et fleurs suivent les livres posés : de 0 à 1. Les cendres s'y ajoutent.
func _apply_life(life: float) -> void:
	var sky := _environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = dead_sky.lerp(living_sky, life).lerp(ash_sky, _ash)
	sky.sky_horizon_color = dead_horizon.lerp(living_horizon, life).lerp(ash_horizon, _ash)
	sky.ground_horizon_color = sky.sky_horizon_color
	# Sous l'horizon, le ciel prolonge la brume au lieu de laisser une bande de sol vide derrière les montagnes.
	sky.ground_bottom_color = sky.sky_horizon_color.darkened(0.15)
	_environment.fog_light_color = dead_fog.lerp(living_fog, life).lerp(ash_fog, _ash)
	_environment.fog_density = lerpf(lerpf(0.014, 0.004, life), 0.017, _ash)
	_environment.ambient_light_energy = lerpf(0.5, 0.7, life)
	_sun.light_energy = lerpf(lerpf(0.55, 1.0, life), 0.45, _ash)
	_sun.light_color = Color(1.0, 0.9, 0.78).lerp(Color(1.0, 0.62, 0.42), _ash)
	(_terrain.ground_material as ShaderMaterial).set_shader_parameter("life", life)
	_scatter.set_life(life)
	_river.set_life(life)


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


## Les lettres du cercle s'illuminent, quart par quart, pour chaque livre posé.
func _refresh_circle(animate := false) -> void:
	for zone in ZONES:
		var lit := GameState.has_placed(GameState.ZONE_BOOKS[zone])
		var group := _circle.get_node(String(zone).capitalize())
		var glow: OmniLight3D = group.get_node("Glow")
		if lit and animate and not glow.visible:
			glow.light_energy = 0.0
			create_tween().tween_property(glow, "light_energy", 1.2, 1.2)
		glow.visible = lit
		for letter in group.get_children():
			if letter is Label3D:
				letter.shaded = not lit
				letter.modulate = LETTER_LIT if lit else LETTER_DARK
	var all := placed_count() >= GameState.BOOK_COUNT
	var rings: StandardMaterial3D = (_circle.get_node("Outer") as MeshInstance3D).mesh.surface_get_material(0)
	rings.emission_energy_multiplier = 1.6 if all else 0.25 * placed_count()


## Le livre quitte la main du joueur et vole jusqu'à son piédestal ; le village se relève, puis, au quatrième,
## Merlon accomplit le rituel.
func _on_pedestal(zone: StringName) -> void:
	var book: StringName = GameState.ZONE_BOOKS[zone]
	if GameState.has_placed(book):
		_hud.show_message("%s repose sur son piédestal." % _book_name(zone).capitalize())
		return
	if not GameState.has_book(book):
		_hud.show_message("Ce piédestal attend %s, caché dans %s." % [_book_name(zone), ZONE_NAMES[zone]])
		return
	if _busy:
		return
	_busy = true
	GameState.place_book(book)
	_refresh_pedestals()
	var shown := _pedestal_book(zone)
	await _player.give_book(book, shown.global_position)
	shown.visible = true
	shown.scale = Vector3.ONE * 0.2
	create_tween().tween_property(shown, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	$PlaceSound.play()
	_refresh_circle(true)
	for next in ZONES:
		_portal(next).is_open = GameState.is_zone_unlocked(next)
	await _show_repairs()
	_busy = false
	if placed_count() >= GameState.BOOK_COUNT:
		_ritual()


## Plan large sur le village le temps qu'il se reconstruise, puis retour au joueur. Au quatrième livre, le rituel
## et la cinématique de la fin montrent le royaume restauré : pas de plan large.
func _show_repairs() -> void:
	var repaired := _set_repairs(placed_count(), true)
	var life := float(placed_count()) / GameState.BOOK_COUNT
	if placed_count() >= GameState.BOOK_COUNT:
		_hud.show_message("Les quatre livres sont réunis.")
		return
	create_tween().tween_method(_apply_life, _life, life, REPAIR_SHOT)
	_life = life
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


## Le rituel, dans la salle du trône : les habitants sortent du bunker, les piédestaux projettent leur lumière vers
## le centre du cercle, Merlon lève les mains et prononce l'incantation, une vague d'énergie part de la salle, les
## cendres se dissipent ; Merlon tombe à genoux, épuisé. Puis la bonne fin se joue.
func _ritual() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	# Temps réalisé, envoyé au classement si le joueur est connecté.
	Account.submit_run(GameState.elapsed_time())
	await _hud.fade(true)
	_release_survivors()
	var camera := Camera3D.new()
	camera.fov = 68.0
	add_child(camera)
	var center := _circle.global_position + Vector3.UP * 2.8
	camera.global_position = $Castle/RitualView.global_position
	camera.look_at(center + Vector3(1.0, -1.4, 1.0))
	camera.current = true
	await _hud.fade(false)
	_hud.show_message("Les survivants sortent du bunker. Merlon lève les mains au-dessus du cercle et prononce une ancienne incantation…")
	var beams := _raise_beams(center)
	_raise_arms(1.2)
	var orb: OmniLight3D = _merlon.find_child("OrbLight")
	create_tween().tween_property(orb, "light_energy", 12.0, 2.5)
	await get_tree().create_timer(2.6).timeout
	# La vague d'énergie : elle traverse la salle, puis tout le royaume, et emporte les cendres.
	$RepairSound.play()
	_energy_wave(center)
	create_tween().tween_method(_set_ash, _ash, 0.0, 2.0)
	create_tween().tween_method(_apply_life, _life, 1.0, 2.5)
	_life = 1.0
	await get_tree().create_timer(1.2).timeout
	for beam in beams:
		create_tween().tween_property(beam, "scale:z", 0.01, 0.6)
	_collapse_merlon()
	await get_tree().create_timer(1.6).timeout
	for beam in beams:
		beam.queue_free()
	camera.queue_free()
	_play_ending(&"victory")


func _set_ash(value: float) -> void:
	_ash = value
	_apply_life(_life)


## Faisceaux de lumière : de chaque livre posé vers un point au-dessus du centre du cercle.
func _raise_beams(target: Vector3) -> Array[Node3D]:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.7, 0.9, 1.0, 0.75)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.disable_fog = true
	var beams: Array[Node3D] = []
	for zone in ZONES:
		var start := _pedestal_book(zone).global_position + Vector3.UP * 0.1
		var pivot := Node3D.new()
		add_child(pivot)
		pivot.global_position = start
		pivot.look_at(target)
		var length := start.distance_to(target)
		var beam := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.05
		mesh.bottom_radius = 0.11
		mesh.height = 1.0
		mesh.radial_segments = 8
		mesh.material = material
		beam.mesh = mesh
		beam.rotation.x = -PI * 0.5
		beam.position = Vector3(0.0, 0.0, -length * 0.5)
		beam.scale = Vector3(1.0, length, 1.0)
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(beam)
		pivot.scale = Vector3(1.0, 1.0, 0.01)
		create_tween().tween_property(pivot, "scale:z", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		beams.append(pivot)
	var light := OmniLight3D.new()
	light.light_color = Color(0.6, 0.85, 1.0)
	light.omni_range = 14.0
	light.light_energy = 0.0
	add_child(light)
	light.global_position = target
	create_tween().tween_property(light, "light_energy", 6.0, 1.6)
	beams.append(light)
	return beams


## Sphère de lumière qui grandit depuis le centre du cercle jusqu'au-delà du village, en s'effaçant.
func _energy_wave(center: Vector3) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_fog = true
	material.albedo_color = Color(0.65, 0.88, 1.0, 0.7)
	var wave := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	sphere.material = material
	wave.mesh = sphere
	wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wave)
	wave.global_position = center
	wave.scale = Vector3.ONE * 0.5
	var tween := create_tween().set_parallel()
	tween.tween_property(wave, "scale", Vector3.ONE * 160.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "albedo_color:a", 0.0, 3.0)
	tween.chain().tween_callback(wave.queue_free)


## Merlon lève les deux mains pour l'incantation : son animation s'arrête, ses bras montent.
func _raise_arms(duration: float) -> void:
	var player: AnimationPlayer = _merlon.get_node("Model/AnimationPlayer")
	var skeleton: Skeleton3D = _merlon.get_node("Model").find_child("Skeleton3D", true, false)
	player.pause()
	for bone_name: StringName in ARMS_RAISED:
		var bone := skeleton.find_bone(bone_name)
		var from := skeleton.get_bone_pose_rotation(bone)
		var to := Quaternion.from_euler(ARMS_RAISED[bone_name])
		create_tween().tween_method(func(t: float) -> void: skeleton.set_bone_pose_rotation(bone, from.slerp(to, t)),
			0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## L'incantation achevée, Merlon s'effondre à genoux, épuisé ; le roi le rejoint.
func _collapse_merlon() -> void:
	var player: AnimationPlayer = _merlon.get_node("Model/AnimationPlayer")
	var crouch := player.get_animation(&"crouch")
	if crouch:
		crouch.loop_mode = Animation.LOOP_LINEAR
	player.play(&"crouch", 0.4)
	_merlon.set_meta(&"exhausted", true)
	var orb: OmniLight3D = _merlon.find_child("OrbLight")
	create_tween().tween_property(orb, "light_energy", 0.6, 1.0)
	var beside := _merlon.global_position + _merlon.global_basis.x * 1.3 + _merlon.global_basis.z * 0.3
	_king.global_position = Vector3(beside.x, _king.global_position.y, beside.z)
	_king.look_at(Vector3(_merlon.global_position.x, _king.global_position.y, _merlon.global_position.z), Vector3.UP, true)


func _arrival_message() -> String:
	var carried := GameState.carried_books()
	if not carried.is_empty():
		var names: Array[String] = []
		for book in carried:
			names.append(GameState.BOOK_NAMES[book])
		return "Vous portez %s. Posez-le sur son piédestal, dans la salle du trône, au cœur des ruines du château, au nord." % " et ".join(names)
	return ""


func _king_text() -> String:
	if not GameState.intro_done:
		return "Devlyn, approche. Pendant huit ans, tu as mené nos troupes contre Vibelandia, et je t'avais promis le repos. La guerre est finie… mais ses explosions ont réveillé le Mont Sam Altan. Dans une heure, il entrera en éruption, et plus rien ne survivra là-haut. Merlon connaît un moyen de l'apaiser : écoute-le. Je n'ai pas le droit de te demander une dernière mission… et pourtant, je le fais."
	if placed_count() >= GameState.BOOK_COUNT:
		return "Les quatre livres sont réunis, et le Mont Sam Altan s'est rendormi. Les vies perdues ne reviendront pas, Devlyn : Codia doit apprendre de son passé. Les livres resteront sous la garde du royaume, en lieu sûr, pour transmettre leur savoir aux générations futures. Merci, mon ami. Cette fois, ta retraite est bien méritée."
	return "Pose chaque livre sur son piédestal, autour du cercle magique de la salle du trône, au cœur des ruines du château. Chaque livre posé ouvre le portail suivant. Quand les quatre seront réunis, Merlon accomplira le rituel."


func _merlon_text() -> String:
	var placed := placed_count()
	if placed >= GameState.BOOK_COUNT:
		if _merlon.has_meta(&"exhausted"):
			return "Pardonne-moi de rester à genoux, Devlyn : ce rituel m'a pris mes dernières forces… Mais écoute : le Mont Sam Altan dort de nouveau, et Codia respire."
		return "Les quatre livres sont réunis. Écoute… le Mont Sam Altan se tait, et Codia respire à nouveau."
	if not GameState.intro_done or GameState.books.is_empty():
		return "Devlyn… Tu ne me connais pas, mais je sais qui tu es. Je vivais loin du royaume, au cœur d'une forêt enchantée, et personne ici ne savait que j'avais trouvé refuge parmi vous. Écoute-moi bien : les explosions de la guerre ont fragilisé les profondeurs, et le Mont Sam Altan se réveille. Dans une heure, il entrera en éruption. D'anciennes légendes parlent de quatre ouvrages magiques laissés par les anciens bâtisseurs de Codia : le Projenomicon, l'Algonicon, le Logiconomicon et le Codonomicon. Réunis, ils peuvent apaiser le volcan et rendre vie à nos terres. J'ai usé mes dernières réserves de magie pour ouvrir des portails vers les lieux où ils reposent : le premier t'attend dehors, non loin des ruines du château, vers les plaines d'Hexcole. Pose chaque livre sur son piédestal, autour du cercle de la salle du trône. Prends garde : leurs cachettes sont protégées par des épreuves, et chaque erreur réveille le volcan plus vite, cinq minutes de moins à chaque fois."
	if GameState.books.size() >= GameState.BOOK_COUNT:
		return "Te voilà ! J'ai senti le quatrième livre s'éveiller, et le ciel se couvre de cendres. Pose les livres qui te restent autour du cercle de la salle du trône : dès que les quatre seront réunis, nous remonterons tous, et j'accomplirai le rituel."
	if not GameState.carried_books().is_empty():
		return "Tu portes un livre, Devlyn. Ne le garde pas : va le poser sur son piédestal, dans la salle du trône du château. Le portail suivant ne s'ouvrira qu'à ce moment-là."
	var next := ""
	for zone in ZONES:
		if not GameState.has_book(GameState.ZONE_BOOKS[zone]):
			next = zone
			break
	return "Tu as posé %d livre%s sur quatre. Regarde : le village se relève déjà. Mais le Mont Sam Altan gronde encore : le portail vers %s t'attend." % [
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
		_hud.show_message("La mission commence : le Mont Sam Altan gronde. Remontez à la surface par la porte du bunker.")
