extends "res://tests/scenes/common_test.gd"
## Menu de debug : capture du menu, puis pose de deux livres par le menu (animation complète), et pose instantanée.
const OUT := "user://captures/debug/"

func _initialize() -> void:
	_run.call_deferred()

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	state = root.get_node("GameState")
	var menu: Node = root.get_node("DebugMenu")
	state.reset()
	change_scene_to_file("res://scenes/levels/plaine/plaine.tscn")
	await wait(40)
	menu.open()
	await wait(5)
	await shot("01_menu")
	check("menu ouvert et pause", paused and menu.get_node("%Root").visible)
	# Pose du Projenomicon depuis la Plaine : le hub se charge, le livre vole jusqu'au piédestal.
	menu._place(&"plaine")
	await wait(60)
	check("au hub", current_scene.scene_file_path.ends_with("hub.tscn"))
	await wait(40)
	await shot("02_pose_en_cours")
	await wait(320)
	check("projenomicon pose", state.has_placed(&"projenomicon") and current_scene.get_node("Castle/Pedestals/Plaine/Book").visible)
	check("portail du desert ouvert", current_scene.get_node("Portals/Desert").is_open)
	# Livre suivant, directement dans le hub.
	menu._place_next()
	await wait(80)
	await shot("03_reconstruction")
	await wait(320)
	check("algonicon pose", state.has_placed(&"algonicon"))
	menu.open()
	await wait(5)
	await shot("04_menu_deux_livres")
	check("etat affiche : " + menu.get_node("%State").text, menu.get_node("%State").text.begins_with("2 livre(s) trouvé(s), 2 posé(s)"))
	menu._place_all_instantly()
	await wait(60)
	check("quatre livres poses d'un coup", state.placed_books.size() == 4 and current_scene.scene_file_path.ends_with("hub.tscn"))
	menu._clear_books()
	await wait(40)
	check("livres retires", state.books.is_empty() and state.placed_books.is_empty())
	finish()
