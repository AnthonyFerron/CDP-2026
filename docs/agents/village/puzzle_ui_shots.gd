extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Captures du dispositif des cinq codes et du carnet des fragments : ouvert, après une erreur, sur une épreuve
## avancée, carnet ouvert, et la lumière bleutée de la réussite.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/village/ui/"


func _initialize() -> void:
	_run.call_deferred()


func shot(name: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await start_level("res://scenes/levels/village/village.tscn")
	# La fenêtre de capture perd le focus : le menu pause s'ouvrirait par-dessus les panneaux.
	for name in ["PauseMenu", "Pause"]:
		if root.has_node(name):
			root.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
	level.set("_inside", true)
	level.call("_apply_location")
	player.global_position = Vector3(-1.0, -35.4, -3.6)
	await wait(10)
	var found: Dictionary = level.get("_found")
	for number in [0, 1, 2, 5]:
		found[number] = level.FRAGMENTS[number]
	level.call("_open_device")
	await wait(5)
	await shot("1_dispositif")
	var puzzle: Node = level.get_node("CodePuzzle")
	puzzle.get_node("%Answer").text = "4"
	puzzle.get_node("%Validate").pressed.emit()
	await wait(8)
	await shot("2_erreur")
	await wait(90)
	puzzle.get_node("%Answer").text = "3"
	puzzle.get_node("%Validate").pressed.emit()
	await wait(20)
	await shot("3_html_resolu")
	await wait(60)
	await shot("4_css_suivant")
	for index in [1, 2, 3]:
		puzzle.select(index)
		puzzle.get_node("%Answer").text = ["3", "green", "10", "2"][index]
		puzzle.get_node("%Validate").pressed.emit()
		await wait(3)
	puzzle.select(4)
	await wait(4)
	await shot("5_typescript")
	puzzle.get_node("%Close").pressed.emit()
	await wait(4)
	level.get("_notebook").open(level.found_fragments(), 10)
	await wait(4)
	await shot("6_carnet")
	level.get("_notebook").get_node("%Root").hide()
	level.call("_open_device")
	await wait(4)
	puzzle.get_node("%Answer").text = "12"
	puzzle.get_node("%Validate").pressed.emit()
	await wait(12)
	await shot("7_lumiere_bleutee")
	check("carnet et dispositif capturés", true)
	finish()
