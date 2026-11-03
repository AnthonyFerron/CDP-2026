extends CanvasLayer
## Menu de debug temporaire : F1 ouvre la liste des niveaux pour passer de l'un à l'autre.
## Il ne s'affiche que dans les versions de debug, jamais dans le jeu publié.
## Il porte aussi un formulaire de connexion de test, relié à rien pour le moment.

## Un niveau est un fichier .tscn de ce dossier, ou un sous-dossier qui contient <nom>/<nom>.tscn.
const LEVELS_DIR := "res://scenes/levels"

var _mouse_was_captured := false

@onready var _root: Control = %Root
@onready var _levels: VBoxContainer = %Levels
@onready var _reload: Button = %Reload
@onready var _reset: Button = %Reset
@onready var _close: Button = %Close
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
	# Boutons des deux fins, pour les voir sans finir une partie.
	for ending: Array in [["Fin : éruption du volcan", &"eruption"], ["Fin : Codia renaît", &"victory"]]:
		var button := Button.new()
		button.text = ending[0]
		button.custom_minimum_size = Vector2(0, 52)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_play_ending.bind(ending[1]))
		_reset.get_parent().add_child(button)
		_reset.get_parent().move_child(button, _reset.get_index())


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
	_fill_levels()
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


func _fill_levels() -> void:
	for child in _levels.get_children():
		child.queue_free()
	var current := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	for path in find_levels():
		var button := Button.new()
		button.text = path.trim_prefix(LEVELS_DIR + "/").trim_suffix(".tscn")
		button.disabled = path == current
		button.custom_minimum_size = Vector2(0, 60)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_go_to.bind(path))
		_levels.add_child(button)


func _go_to(path: String) -> void:
	close()
	get_tree().change_scene_to_file(path)


func _play_ending(ending: StringName) -> void:
	GameState.ending = ending
	_go_to(GameState.HUB_SCENE)


## Le formulaire n'envoie rien : il vérifie seulement que les deux champs sont remplis.
func _on_login_pressed() -> void:
	if _username.text.strip_edges().is_empty() or _password.text.is_empty():
		_login_status.text = "Renseignez l'identifiant et le mot de passe."
		return
	_login_status.text = "Formulaire de test : la connexion n'est reliée à aucun serveur."
	_password.clear()


func _on_reload_pressed() -> void:
	close()
	get_tree().reload_current_scene()


## Efface les livres rapportés et la dernière zone, puis recharge le niveau courant.
func _on_reset_pressed() -> void:
	GameState.reset()
	_on_reload_pressed()
