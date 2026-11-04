extends SceneTree
## Teste le formulaire de connexion du menu de debug et en prend une capture.

const OUT := "user://captures/shots/"
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(label: String, ok: bool) -> void:
	print(("OK    " if ok else "ECHEC ") + label)
	if not ok:
		failures += 1


func frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(40)
	var menu: CanvasLayer = root.get_node("DebugMenu")
	menu.open()
	await frames(5)
	var username: LineEdit = menu.get_node("%Username")
	var password: LineEdit = menu.get_node("%Password")
	var login: Button = menu.get_node("%Login")
	var status: Label = menu.get_node("%LoginStatus")
	check("champ mot de passe masque", password.secret)
	login.pressed.emit()
	check("champs vides refuses : " + status.text, status.text.contains("Renseignez"))
	username.text = "devlyn"
	password.text = "codia5814"
	await frames(3)
	root.get_viewport().get_texture().get_image().save_png(OUT + "24_connexion.png")
	password.text_submitted.emit(password.text)
	# La connexion passe par Account, dont la réponse simulée arrive après un court délai.
	await create_timer(1.0).timeout
	check("connexion de test : " + status.text, status.text.contains("aucun serveur"))
	check("mot de passe efface", password.text.is_empty())
	check("identifiant conserve", username.text == "devlyn")
	root.get_node("Account").logout()
	root.get_node("GameState").use_profile("")
	menu.close()
	print("RESULTAT : %d echec(s)" % failures)
	quit(1 if failures else 0)
