extends SceneTree
## Captures du panneau de la table des runes : ouvert, à moitié rempli avec une rune choisie, puis à l'erreur.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/puzzle/"


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func shot(name: String) -> void:
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	change_scene_to_file("res://scenes/levels/desert/desert.tscn")
	await frames(40)
	var level: Node = current_scene
	level.set("_inside", true)
	level.call("_apply_location")
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var puzzle: Node = level.get_node("RunePuzzle")
	var all: Array[StringName] = [&"porter", &"puiser", &"pour", &"tant_que", &"si", &"fermer", &"ouvrir", &"sinon"]
	puzzle.open(all)
	await shot("ouvert")
	puzzle.place(&"tant_que", 0)
	puzzle.place(&"puiser", 1)
	puzzle.place(&"si", 3)
	puzzle.call("_on_rune_pressed", &"ouvrir")
	await shot("en_cours")
	var wrong: Array[StringName] = [&"pour", &"puiser", &"porter", &"si", &"ouvrir", &"sinon"]
	for slot in 6:
		puzzle.place(wrong[slot], slot)
	await frames(3)
	puzzle.get_node("%Validate").pressed.emit()
	await frames(40)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "erreur.png")
	state.reset()
	quit()
