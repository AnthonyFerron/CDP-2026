extends Node
## État de la partie, chargé au démarrage : livres retrouvés et dernière zone visitée.
## Il est sauvegardé à chaque changement, ce qui fait une sauvegarde entre chaque énigme.

signal book_collected(book_id: StringName)

const SAVE_PATH := "user://sauvegarde.cfg"
const HUB_SCENE := "res://scenes/levels/hub/hub.tscn"
## Scène de chaque zone ; une zone sans scène n'est pas encore construite.
const ZONE_SCENES := {
	&"plaine": "res://scenes/levels/plaine/plaine.tscn",
	&"desert": "res://scenes/levels/desert/desert.tscn",
	&"marais": "res://scenes/levels/marais/marais.tscn",
	&"village": "res://scenes/levels/village/village.tscn",
}
const BOOK_COUNT := 4

var books: Array[StringName] = []
## Zone d'où revient le joueur, pour le faire réapparaître devant son portail dans le hub.
var last_zone: StringName = &""


func _ready() -> void:
	load_game()


func has_book(book_id: StringName) -> bool:
	return book_id in books


func collect_book(book_id: StringName) -> void:
	if has_book(book_id):
		return
	books.append(book_id)
	save_game()
	book_collected.emit(book_id)


func is_zone_built(zone: StringName) -> bool:
	return not String(ZONE_SCENES.get(zone, "")).is_empty()


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


func reset() -> void:
	books.clear()
	last_zone = &""
	save_game()


func save_game() -> void:
	var file := ConfigFile.new()
	file.set_value("partie", "livres", books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "derniere_zone", String(last_zone))
	file.save(SAVE_PATH)


func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	books.clear()
	for book: String in file.get_value("partie", "livres", []):
		books.append(StringName(book))
	last_zone = StringName(file.get_value("partie", "derniere_zone", ""))
