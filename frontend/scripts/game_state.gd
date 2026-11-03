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
const BOOK_COUNT := 4
## Temps laissé au joueur avant l'éruption, et coût d'une validation fausse, en secondes.
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
var has_erupted := false

var _since_save := 0.0


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
	return not has_erupted and not get_tree().paused and placed_books.size() < BOOK_COUNT and get_tree().current_scene != null


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


## Une zone s'ouvre quand elle est construite et que le livre de la zone précédente est trouvé.
func is_zone_unlocked(zone: StringName) -> bool:
	var index := ZONE_ORDER.find(zone)
	if not is_zone_built(zone) or index < 0:
		return false
	return index == 0 or has_book(ZONE_BOOKS[ZONE_ORDER[index - 1]])


## Zone à terminer avant celle-ci, ou rien pour la première.
func previous_zone(zone: StringName) -> StringName:
	var index := ZONE_ORDER.find(zone)
	return ZONE_ORDER[index - 1] if index > 0 else &""


func enter_zone(zone: StringName) -> void:
	if not is_zone_built(zone):
		return
	last_zone = zone
	save_game()
	get_tree().change_scene_to_file(ZONE_SCENES[zone])


func return_to_hub(zone: StringName) -> void:
	last_zone = zone
	save_game()
	get_tree().change_scene_to_file(HUB_SCENE)


## Repart d'une partie neuve : aucun livre, chronomètre plein.
func reset() -> void:
	books.clear()
	placed_books.clear()
	last_zone = &""
	time_left = TOTAL_TIME
	has_erupted = false
	save_game()


func save_game() -> void:
	_since_save = 0.0
	var file := ConfigFile.new()
	file.set_value("partie", "livres", books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "livres_poses", placed_books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "derniere_zone", String(last_zone))
	file.set_value("partie", "temps_restant", time_left)
	file.set_value("partie", "eruption", has_erupted)
	file.save(SAVE_PATH)


func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
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


func _erupt() -> void:
	has_erupted = true
	save_game()
	erupted.emit()
