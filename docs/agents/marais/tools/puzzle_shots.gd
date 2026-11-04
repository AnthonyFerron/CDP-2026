extends SceneTree
## Captures du panneau du mécanisme : ouvert, après une erreur, après la réussite.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/puzzle/"

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func shot(name: String) -> void:
	# La fenêtre des captures perd le focus : le menu de pause, s'il s'est ouvert, est refermé avant la capture.
	var pause_menu: Node = root.get_node("PauseMenu")
	if pause_menu.is_open():
		pause_menu.close()
		await process_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func set_word(puzzle: Node, mechanism: Node, word: String) -> void:
	for ring in 5:
		var target: int = mechanism.LETTERS.find(word[ring])
		while mechanism.letters[ring] != target:
			puzzle.turn(ring, 1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	await frames(40)
	var level: Node = current_scene
	# La fenêtre perd le focus pendant les captures : le menu de pause ne doit pas s'ouvrir.
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	level.set("_inside", true)
	level.call("_apply_location")
	level.get_node("Player").global_position = Vector3(0, -40, -6)
	await frames(5)
	level.call("_open_mechanism")
	var puzzle: Node = level.get_node("RingPuzzle")
	var mechanism: Node = level.mechanism()
	await frames(10)
	await shot("1_ouvert")
	set_word(puzzle, mechanism, "CODIA")
	await frames(20)
	await shot("2_codia")
	puzzle.get_node("%Validate").pressed.emit()
	await frames(8)
	await shot("3_erreur")
	await frames(120)
	set_word(puzzle, mechanism, "FLGFD")
	await frames(20)
	puzzle.get_node("%Validate").pressed.emit()
	await frames(10)
	await shot("4_reussite")
	await frames(30)
	await shot("5_reussite_fondu")
	state.reset()
	quit()
