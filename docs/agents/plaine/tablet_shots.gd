extends SceneTree
## Captures du panneau de la tablette : ouvert à moitié rempli, en erreur, en réussite.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/tablet/"


func _initialize() -> void:
	_run.call_deferred()


func shot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file("res://scenes/levels/plaine/plaine.tscn")
	for i in 30:
		await process_frame
	var level: Node = current_scene
	level.set("_inside", true)
	level.call("_apply_location")
	var found: Dictionary = level.found_fragments()
	for index in 6:
		found[index] = level.FRAGMENTS[index]
	level.call("_open_tablet")
	var puzzle: Node = level.get_node("TabletPuzzle")
	puzzle.place(1, 0)
	puzzle.place(0, 1)
	puzzle.call("_on_fragment_pressed", 3)
	await shot("tablette_ouverte")
	for slot in 6:
		puzzle.place([1, 0, 2, 3, 4, 5][slot], slot)
	puzzle.get_node("%Validate").pressed.emit()
	await shot("tablette_erreur")
	for i in 100:
		await process_frame
	for slot in 6:
		puzzle.place(slot, slot)
	puzzle.get_node("%Validate").pressed.emit()
	await shot("tablette_reussite")
	state.reset()
	quit()
