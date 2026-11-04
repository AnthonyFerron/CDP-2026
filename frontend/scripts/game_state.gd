extends Node
## État de la partie, chargé au démarrage : livres retrouvés et posés au château, dernière zone visitée
## et chronomètre du volcan.
## Il est sauvegardé à chaque changement, ce qui fait une sauvegarde entre chaque énigme.

signal book_collected(book_id: StringName)
## Un livre vient d'être posé sur son piédestal, au château du hub.
signal book_placed(book_id: StringName)
## Une validation fausse vient de coûter du temps.
signal time_penalized(seconds: float)
## Le chronomètre est tombé à zéro : le volcan entre en éruption et la partie est perdue.
signal erupted

## Sauvegarde de l'invité ; un compte a la sienne, nommée d'après son profil (use_profile).
const SAVE_PATH := "user://sauvegarde.cfg"
const HUB_SCENE := "res://scenes/levels/hub/hub.tscn"
## Scène de chaque zone ; une zone sans scène n'est pas encore construite.
const ZONE_SCENES := {
	&"plaine": "res://scenes/levels/plaine/plaine.tscn",
	&"desert": "res://scenes/levels/desert/desert.tscn",
	&"marais": "res://scenes/levels/marais/marais.tscn",
	&"village": "res://scenes/levels/village/village.tscn",
}
## Zones dans l'ordre du jeu : chacune s'ouvre une fois le livre de la précédente trouvé.
const ZONE_ORDER: Array[StringName] = [&"plaine", &"desert", &"marais", &"village"]
## Livre que garde chaque zone.
const ZONE_BOOKS := {
	&"plaine": &"projenomicon",
	&"desert": &"algonicon",
	&"marais": &"logiconomicon",
	&"village": &"codonomicon",
}
const BOOK_NAMES := {
	&"projenomicon": "le Projenomicon",
	&"algonicon": "l'Algonicon",
	&"logiconomicon": "le Logiconomicon",
	&"codonomicon": "le Codonomicon",
}
## Couleur de la couverture de chaque livre, sur les piédestaux et dans la main du joueur.
const BOOK_COLORS := {
	&"projenomicon": Color(0.5, 0.08, 0.05),
	&"algonicon": Color(0.55, 0.35, 0.08),
	&"logiconomicon": Color(0.1, 0.35, 0.25),
	&"codonomicon": Color(0.3, 0.15, 0.5),
}
const BOOK_COUNT := 4
## Lignes de la transition à l'entrée de chaque lieu, d'après le scénario : chapitre, nom du lieu, énigme.
const ZONE_TITLES := {
	&"plaine": ["Chapitre III", "Les plaines d'Hexcole", "Énigme 1 — Les fragments du passé"],
	&"desert": ["Chapitre IV", "Le désert de Pythania", "Énigme 2 — Les algorithmes oubliés"],
	&"marais": ["Chapitre V", "Les marais de Kernel Swamp", "Énigme 3 — Le tombeau du chiffrement"],
	&"village": ["Chapitre VI", "Le village détruit", "Énigme 4 — Les cinq langages oubliés"],
}
## Temps laissé au joueur avant l'éruption du Mont Sam Altan (une heure, choix de l'équipe : le scénario
## en annonce quarante), et coût d'une validation fausse, en secondes.
const TOTAL_TIME := 60.0 * 60.0
const PENALTY := 5.0 * 60.0
## Intervalle entre deux sauvegardes du chronomètre.
const SAVE_INTERVAL := 15.0

## Livres trouvés dans les zones, qu'ils soient encore portés ou déjà posés.
var books: Array[StringName] = []
## Livres posés sur leur piédestal, au château.
var placed_books: Array[StringName] = []
## Zone d'où revient le joueur, pour le faire réapparaître devant son portail dans le hub.
var last_zone: StringName = &""
var time_left := TOTAL_TIME
## Vrai une fois la mission reçue du roi et de Merlon, dans le bunker : le chronomètre part de là.
var intro_done := false
var has_erupted := false
## Fin à jouer au prochain chargement du hub : &"eruption", &"victory", ou rien. Elle n'est pas sauvegardée.
var ending: StringName = &""

var _since_save := 0.0
var _save_path := SAVE_PATH


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	if not is_timer_running():
		return
	time_left = maxf(time_left - delta, 0.0)
	_since_save += delta
	if time_left <= 0.0:
		_erupt()
	elif _since_save >= SAVE_INTERVAL:
		save_game()


## Le chronomètre tourne pendant la partie, sauf en pause, après l'éruption ou une fois les livres posés.
func is_timer_running() -> bool:
	return intro_done and not has_erupted and not get_tree().paused and placed_books.size() < BOOK_COUNT 		and get_tree().current_scene != null


func penalize() -> void:
	if has_erupted:
		return
	time_left = maxf(time_left - PENALTY, 0.0)
	time_penalized.emit(PENALTY)
	if time_left <= 0.0:
		_erupt()
	else:
		save_game()


func has_book(book_id: StringName) -> bool:
	return book_id in books


func collect_book(book_id: StringName) -> void:
	if has_book(book_id):
		return
	books.append(book_id)
	save_game()
	book_collected.emit(book_id)


## Livres trouvés que le joueur porte encore, en attendant de les poser au château.
func carried_books() -> Array[StringName]:
	return books.filter(func(book: StringName) -> bool: return not has_placed(book))


func has_placed(book_id: StringName) -> bool:
	return book_id in placed_books


func place_book(book_id: StringName) -> void:
	if not has_book(book_id) or has_placed(book_id):
		return
	placed_books.append(book_id)
	save_game()
	book_placed.emit(book_id)


func is_zone_built(zone: StringName) -> bool:
	return not String(ZONE_SCENES.get(zone, "")).is_empty()


## Une zone s'ouvre quand elle est construite et que le livre de la zone précédente est posé au château.
func is_zone_unlocked(zone: StringName) -> bool:
	var index := ZONE_ORDER.find(zone)
	if not is_zone_built(zone) or index < 0:
		return false
	return index == 0 or has_placed(ZONE_BOOKS[ZONE_ORDER[index - 1]])


## La mission commence : le roi et Merlon l'ont confiée, le chronomètre du volcan se met en marche.
func begin_mission() -> void:
	if intro_done:
		return
	intro_done = true
	save_game()


## Zone à terminer avant celle-ci, ou rien pour la première.
func previous_zone(zone: StringName) -> StringName:
	var index := ZONE_ORDER.find(zone)
	return ZONE_ORDER[index - 1] if index > 0 else &""


func enter_zone(zone: StringName) -> void:
	if not is_zone_built(zone):
		return
	last_zone = zone
	save_game()
	Transition.change_scene(ZONE_SCENES[zone], ZONE_TITLES[zone])


func return_to_hub(zone: StringName) -> void:
	last_zone = zone
	save_game()
	Transition.change_scene(HUB_SCENE, hub_title())


## Lignes de la transition vers le hub, selon l'avancée de la quête.
func hub_title() -> Array:
	if not intro_done:
		return ["Chapitre II", "Le réveil du Mont Sam Altan", "An 5814"]
	if placed_books.size() >= BOOK_COUNT:
		return ["Épilogue", "La renaissance d'un royaume", "Codia"]
	if books.size() >= BOOK_COUNT:
		return ["Chapitre VII", "Le dernier espoir de Codia", "Les ruines du château"]
	var count := books.size()
	return ["Codia", "Les ruines du château", "%d livre%s sur quatre" % [count, "s" if count > 1 else ""]]


## Repart d'une partie neuve : aucun livre, chronomètre plein.
func reset() -> void:
	_clear()
	save_game()


func _clear() -> void:
	books.clear()
	placed_books.clear()
	last_zone = &""
	intro_done = false
	time_left = TOTAL_TIME
	has_erupted = false


## Change de joueur : l'invité (profil vide) ou un compte. Sa sauvegarde est chargée, s'il en a une.
func use_profile(profile: String) -> void:
	var path := SAVE_PATH if profile.is_empty() else "user://sauvegarde_%s.cfg" % profile
	if path == _save_path:
		return
	_save_path = path
	load_game()


## Une partie commencée, et pas encore perdue, peut être reprise depuis le menu.
func can_continue() -> bool:
	return intro_done and not has_erupted


## Temps mis depuis le début de la mission, en secondes, pénalités comprises.
func elapsed_time() -> float:
	return TOTAL_TIME - time_left


func save_game() -> void:
	_since_save = 0.0
	var file := ConfigFile.new()
	file.set_value("partie", "livres", books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "livres_poses", placed_books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "derniere_zone", String(last_zone))
	file.set_value("partie", "temps_restant", time_left)
	file.set_value("partie", "eruption", has_erupted)
	file.set_value("partie", "introduction", intro_done)
	file.save(_save_path)


func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(_save_path) != OK:
		_clear()
		return
	books.clear()
	for book: String in file.get_value("partie", "livres", []):
		books.append(StringName(book))
	placed_books.clear()
	for book: String in file.get_value("partie", "livres_poses", []):
		placed_books.append(StringName(book))
	last_zone = StringName(file.get_value("partie", "derniere_zone", ""))
	time_left = float(file.get_value("partie", "temps_restant", TOTAL_TIME))
	has_erupted = bool(file.get_value("partie", "eruption", false))
	intro_done = bool(file.get_value("partie", "introduction", false))


func _erupt() -> void:
	has_erupted = true
	save_game()
	erupted.emit()
