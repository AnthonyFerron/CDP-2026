extends SceneTree
## Charge le Marais, attend quelques images et affiche le nombre de nœuds : vérifie qu'il n'y a pas d'erreur de script.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	for i in 30:
		await process_frame
	var level := current_scene
	print("CHARGE : ", level.name, " ", level.get_child_count(), " enfants")
	state.reset()
	quit()
