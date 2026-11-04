extends CanvasLayer
## Menu de debug : F1 ouvre, sur toute la page, les niveaux, les livres et leurs piédestaux, la partie
## (chronomètre, introduction, fins) et un compte de test. Il ne s'affiche que dans les versions de debug,
## jamais dans le jeu publié.
##
## « Poser » un livre amène au château, met le livre en main et joue la vraie pose du hub (`_on_pedestal`) :
## vol du livre, plan large sur la reconstruction, et le rituel au quatrième livre.

## Un niveau est un fichier .tscn de ce dossier, ou un sous-dossier qui contient <nom>/<nom>.tscn.
const LEVELS_DIR := "res://scenes/levels"
const LEVEL_NAMES := {
	"hub/hub": "Hub — Codia et le château",
	"plaine/plaine": "Plaines d'Hexcole",
	"desert/desert": "Désert de Pythania",
	"marais/marais": "Marais de Kernel Swamp",
	"village/village": "Village détruit",
}
## Images laissées au hub pour se construire avant la pose d'un livre.
const HUB_SETTLE_FRAMES := 30

var _mouse_was_captured := false

@onready var _root: Control = %Root
@onready var _state: Label = %State
@onready var _levels: VBoxContainer = %Levels
@onready var _books: VBoxContainer = %Books
@onready var _book_actions: VBoxContainer = %BookActions
@onready var _game_box: VBoxContainer = %GameBox
@onready var _reload: Button = %Reload
@onready var _reset: Button = %Reset
@onready var _close: Button = %Close
@onready var _account_state: Label = %AccountState
@onready var _account_box: VBoxContainer = %AccountBox
@onready var _username: LineEdit = %Username
@onready var _password: LineEdit = %Password
@onready var _login: Button = %Login
@onready var _login_status: Label = %LoginStatus


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()
	_reload.pressed.connect(_on_reload_pressed)
	_reset.pressed.connect(_on_reset_pressed)
	_close.pressed.connect(close)
	_login.pressed.connect(_on_login_pressed)
	_password.text_submitted.connect(_on_login_pressed.unbind(1))
	_build_game_column()
	_build_book_actions()
	var quick := _button("Connexion rapide : Aziz", _quick_login)
	_account_box.add_child(quick)
	_account_box.move_child(quick, _account_state.get_index() + 1)
	_account_box.add_child(_button("Se déconnecter", _logout))


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F1:
		get_viewport().set_input_as_handled()
		if _root.visible:
			close()
		else:
			open()


func open() -> void:
	_mouse_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_refresh()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_root.show()


func close() -> void:
	_root.hide()
	get_tree().paused = false
	if _mouse_was_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


static func find_levels() -> PackedStringArray:
	var levels := PackedStringArray()
	for file in DirAccess.get_files_at(LEVELS_DIR):
		file = file.trim_suffix(".remap")
		if file.ends_with(".tscn"):
			levels.append(LEVELS_DIR.path_join(file))
	for folder in DirAccess.get_directories_at(LEVELS_DIR):
		var scene := LEVELS_DIR.path_join(folder).path_join(folder + ".tscn")
		if ResourceLoader.exists(scene):
			levels.append(scene)
	levels.sort()
	return levels


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 21)
	button.pressed.connect(action)
	return button


func _label(text: String, size := 21, color := Color(0.85, 0.85, 0.88)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


# --- Remplissage ---------------------------------------------------------------------------------------------

func _refresh() -> void:
	_fill_levels()
	_fill_books()
	var remaining := int(ceil(GameState.time_left))
	_state.text = "%d livre(s) trouvé(s), %d posé(s)   ·   chronomètre %d:%02d   ·   %s" % [
		GameState.books.size(), GameState.placed_books.size(), remaining / 60, remaining % 60,
		"mission commencée" if GameState.intro_done else "introduction du bunker"]
	if not Account.is_logged_in():
		_account_state.text = "Invité"
	elif Account.simulated:
		_account_state.text = "Connecté : %s (compte de test simulé, aucun serveur)" % Account.pseudo
	else:
		_account_state.text = "Connecté : %s (serveur %s) ; les réglages de ce menu ne changent que la partie locale" % [Account.pseudo, Api.base_url]


func _fill_levels() -> void:
	for child in _levels.get_children():
		child.queue_free()
	var current := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	# Dans l'ordre du jeu, puis les autres scènes de niveau éventuelles.
	var keys := LEVEL_NAMES.keys()
	var levels := Array(find_levels())
	levels.sort_custom(func(a: String, b: String) -> bool:
		var ia := keys.find(a.trim_prefix(LEVELS_DIR + "/").trim_suffix(".tscn"))
		var ib := keys.find(b.trim_prefix(LEVELS_DIR + "/").trim_suffix(".tscn"))
		return (ia if ia >= 0 else 99) < (ib if ib >= 0 else 99) or (ia == ib and a < b))
	for path: String in levels:
		var key := path.trim_prefix(LEVELS_DIR + "/").trim_suffix(".tscn")
		var button := _button(LEVEL_NAMES.get(key, key), _go_to.bind(path))
		button.disabled = path == current
		_levels.add_child(button)
	var menu := _button("Menu principal", _go_to.bind(MainMenu.SCENE))
	menu.disabled = current == MainMenu.SCENE
	_levels.add_child(menu)


func _fill_books() -> void:
	for child in _books.get_children():
		child.queue_free()
	for zone in GameState.ZONE_ORDER:
		var book: StringName = GameState.ZONE_BOOKS[zone]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var status := "posé" if GameState.has_placed(book) else ("en main" if GameState.has_book(book) else "à trouver")
		var name := _label("%s\n%s · %s" % [GameState.BOOK_NAMES[book].capitalize(), GameState.ZONE_TITLES[zone][1], status], 19)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.add_theme_color_override("font_color", GameState.BOOK_COLORS[book].lightened(0.55))
		row.add_child(name)
		var find := _button("Trouver", _find.bind(zone))
		find.custom_minimum_size = Vector2(120, 50)
		find.disabled = GameState.has_book(book)
		row.add_child(find)
		var place := _button("Poser", _place.bind(zone))
		place.custom_minimum_size = Vector2(120, 50)
		place.disabled = GameState.has_placed(book)
		row.add_child(place)
		_books.add_child(row)


func _build_book_actions() -> void:
	_book_actions.add_child(_button("Poser le livre suivant", _place_next))
	_book_actions.add_child(_button("Trouver les quatre livres", _find_all))
	_book_actions.add_child(_button("Tout poser d'un coup, sans animation", _place_all_instantly))
	_book_actions.add_child(_button("Retirer tous les livres", _clear_books))


func _build_game_column() -> void:
	var at := _reload.get_index()
	var items: Array[Control] = [
		_label("Chronomètre", 19, Color(0.7, 0.7, 0.72)),
		_button("−5 minutes", _shift_time.bind(-300.0)),
		_button("+5 minutes", _shift_time.bind(300.0)),
		_button("Plus qu'une minute", _set_time.bind(60.0)),
		_button("Temps complet", _set_time.bind(GameState.TOTAL_TIME)),
		_label("Déroulé", 19, Color(0.7, 0.7, 0.72)),
		_button("Passer l'introduction du bunker", _skip_intro),
		_button("Fin : éruption du volcan", _play_ending.bind(&"eruption")),
		_button("Fin : Codia renaît", _play_ending.bind(&"victory")),
		_label("Niveau", 19, Color(0.7, 0.7, 0.72)),
	]
	for item in items:
		_game_box.add_child(item)
		_game_box.move_child(item, at)
		at += 1


# --- Niveaux et partie ---------------------------------------------------------------------------------------

func _go_to(path: String) -> void:
	close()
	# Aller droit dans une zone saute l'introduction du bunker : la mission commence.
	if path != GameState.HUB_SCENE and path != MainMenu.SCENE:
		GameState.begin_mission()
	get_tree().change_scene_to_file(path)


func _play_ending(ending: StringName) -> void:
	GameState.ending = ending
	_go_to(GameState.HUB_SCENE)


func _shift_time(seconds: float) -> void:
	GameState.time_left = clampf(GameState.time_left + seconds, 1.0, GameState.TOTAL_TIME)
	GameState.save_game()
	_refresh()


func _set_time(seconds: float) -> void:
	GameState.time_left = seconds
	GameState.has_erupted = false
	GameState.save_game()
	_refresh()


func _skip_intro() -> void:
	GameState.begin_mission()
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == GameState.HUB_SCENE:
		_on_reload_pressed()
	else:
		_refresh()


func _on_reload_pressed() -> void:
	close()
	get_tree().reload_current_scene()


## Efface les livres rapportés et la dernière zone, puis recharge le niveau courant.
func _on_reset_pressed() -> void:
	GameState.reset()
	_on_reload_pressed()


# --- Livres --------------------------------------------------------------------------------------------------

func _find(zone: StringName) -> void:
	GameState.begin_mission()
	GameState.collect_book(GameState.ZONE_BOOKS[zone])
	_refresh()


func _find_all() -> void:
	for zone in GameState.ZONE_ORDER:
		_find(zone)


func _place_next() -> void:
	for zone in GameState.ZONE_ORDER:
		if not GameState.has_placed(GameState.ZONE_BOOKS[zone]):
			_place(zone)
			return


## Pose le livre de la zone comme le joueur le ferait : au château, livre en main, avec toutes les animations.
func _place(zone: StringName) -> void:
	var book: StringName = GameState.ZONE_BOOKS[zone]
	if GameState.has_placed(book):
		return
	close()
	GameState.begin_mission()
	GameState.collect_book(book)
	var tree := get_tree()
	if not tree.current_scene or tree.current_scene.scene_file_path != GameState.HUB_SCENE:
		GameState.last_zone = &""
		tree.change_scene_to_file(GameState.HUB_SCENE)
		for frame in HUB_SETTLE_FRAMES:
			await tree.process_frame
	var hub := tree.current_scene
	if not hub or not hub.has_method("_on_pedestal"):
		return
	var player := hub.get_node_or_null("Player") as Player
	var pedestal := hub.get_node_or_null("Castle/Pedestals/" + String(zone).capitalize()) as Node3D
	if player and pedestal:
		# Hors du bunker, debout devant le piédestal, tourné vers lui, le livre en main.
		if hub.has_method("_set_location"):
			hub.call("_set_location", false)
		player.global_position = pedestal.global_position + Vector3(0.0, 0.3, 3.2)
		player.velocity = Vector3.ZERO
		player.get_node("CameraPivot").rotation = Vector3.ZERO
		player.call("_hold", book)
		for frame in 25:
			await tree.process_frame
	hub.call("_on_pedestal", zone)


func _place_all_instantly() -> void:
	GameState.begin_mission()
	for zone in GameState.ZONE_ORDER:
		var book: StringName = GameState.ZONE_BOOKS[zone]
		GameState.collect_book(book)
		GameState.place_book(book)
	_go_to(GameState.HUB_SCENE)


func _clear_books() -> void:
	GameState.books.clear()
	GameState.placed_books.clear()
	GameState.save_game()
	_on_reload_pressed()


# --- Compte de test ------------------------------------------------------------------------------------------

## Connexion de test par l'autoload Account, en mode simulé : aucune requête au serveur, le code est validé
## d'office. Pour un vrai compte, passer par le menu principal (code reçu par e-mail).
func _on_login_pressed() -> void:
	var identifier := _username.text.strip_edges()
	if identifier.is_empty() or _password.text.is_empty():
		_login_status.text = "Renseignez l'identifiant et le mot de passe."
		return
	var address := identifier if identifier.contains("@") else "%s@test.codia" % identifier
	var password := _password.text
	_password.clear()
	if Account.is_online():
		Account.logout()
	Account.simulated = true
	var result: Dictionary = await Account.login(address, password)
	if result.ok:
		result = await Account.verify_code("000000")
	if result.ok:
		GameState.use_profile(Account.profile_id())
		_login_status.text = "Connecté en test : %s (réponses simulées, aucun serveur)." % Account.pseudo
	else:
		Account.simulated = false
		_login_status.text = result.error
	_refresh()


func _quick_login() -> void:
	_username.text = "aziz@codia.fr"
	_password.text = "motdepasse"
	await _on_login_pressed()


func _logout() -> void:
	Account.logout()
	GameState.use_profile(Account.profile_id())
	_login_status.text = "Déconnecté : la partie de l'invité est rechargée."
	_refresh()
