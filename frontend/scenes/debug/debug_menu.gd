extends CanvasLayer
## Menu de debug temporaire : F1 ouvre la liste des niveaux pour passer de l'un à l'autre.
## Il ne s'affiche que dans les versions de debug, jamais dans le jeu publié.

## Un niveau est un fichier .tscn de ce dossier, ou un sous-dossier qui contient <nom>/<nom>.tscn.
const LEVELS_DIR := "res://scenes/levels"

var _mouse_was_captured := false

@onready var _root: Control = %Root
@onready var _levels: VBoxContainer = %Levels
@onready var _reload: Button = %Reload
@onready var _reset: Button = %Reset
@onready var _close: Button = %Close


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()
	_reload.pressed.connect(_on_reload_pressed)
	_reset.pressed.connect(_on_reset_pressed)
	_close.pressed.connect(close)


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


func _on_reload_pressed() -> void:
	close()
	get_tree().reload_current_scene()


## Efface les livres rapportés et la dernière zone, puis recharge le niveau courant.
func _on_reset_pressed() -> void:
	GameState.reset()
	_on_reload_pressed()
