extends Node
## Plein écran, sur ordinateur comme dans le navigateur : F ou F11 bascule l'affichage, même en pause.
## Dans un champ de saisie, la touche F s'écrit normalement : le champ garde la frappe pour lui.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		get_viewport().set_input_as_handled()
		toggle_fullscreen()


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN)
