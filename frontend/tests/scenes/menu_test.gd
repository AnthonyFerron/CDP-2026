extends "res://tests/scenes/common_test.gd"
## Menus : accueil invité et connecté, connexion, vérification, création de compte, nouvelle partie,
## introduction, pause, retour au menu, chargement, confirmation, indices et écran de fin.

func _initialize() -> void:
	_run.call_deferred()


func screen() -> Node:
	return current_scene

func find(name: String) -> Node:
	return current_scene.find_child(name, true, false)

func click(name: String) -> void:
	var button := find(name) as BaseButton
	check("bouton %s present" % name, button != null)
	if button:
		button.pressed.emit()
	await wait(3)

func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	await wait(2)
	var release := InputEventAction.new()
	release.action = name
	release.pressed = false
	Input.parse_input_event(release)
	await wait(2)

func _run() -> void:
	var account: Node = root.get_node("Account")
	var game: Node = root.get_node("GameState")
	state = game
	var pause: Node = root.get_node("PauseMenu")
	var hints: Node = root.get_node("Hints")
	account.logout()
	# Depuis l'intégration de l'API (PR #12), le parcours de connexion se teste en mode simulé, sans serveur.
	if "simulated" in account:
		account.simulated = true
	game.use_profile("")
	game.reset()
	change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	await wait(10)

	# Accueil invité.
	check("accueil", screen().current_screen() == &"home")
	check("jouer en tant qu'invite", find("NewGame").caption == "Jouer en tant qu'invité")
	check("charger grise pour l'invite", find("LoadGame").disabled)
	check("classement grise pour l'invite", find("Leaderboard").disabled)
	check("carte invite : se connecter et creer un compte", find("Seconnecter") != null and find("Créeruncompte") != null)

	# Connexion : adresse invalide, puis valide, puis code.
	await click("Seconnecter")
	check("ecran de connexion", screen().current_screen() == &"login")
	find("Email").text = "aziz"
	find("Password").text = "secret"
	await click("Submit")
	await wait(30)
	check("adresse refusee : " + find("Status").text, screen().current_screen() == &"login" and find("Status").text.contains("pas valide"))
	await click("Forgot")
	await wait(30)
	find("Email").text = "aziz@codia.fr"
	await click("Forgot")
	await wait(30)
	check("mot de passe oublie : " + find("Status").text, find("Status").text.contains("e-mail vient") or find("Status").text.contains("pas encore disponible"))
	await click("Submit")
	await wait(40)
	check("ecran de verification", screen().current_screen() == &"verify")
	var boxes: Node = find("Code")
	check("valider grise sans code", find("Submit").disabled)
	boxes.fill("12345")
	await wait(2)
	check("valider grise avec cinq chiffres", find("Submit").disabled)
	boxes.fill("12a3456")
	await wait(2)
	check("code colle reparti dans les cases (%s)" % boxes.code(), boxes.code() == "123456")
	check("valider actif avec six chiffres", not find("Submit").disabled)
	await click("Submit")
	await wait(40)
	check("connecte : retour a l'accueil", screen().current_screen() == &"home" and account.is_logged_in())
	check("pseudo affiche : " + find("Pseudo").text, find("Pseudo").text == "Aziz")
	check("nouvelle partie", find("NewGame").caption == "Nouvelle partie")
	check("charger grise sans partie", find("LoadGame").disabled)
	check("classement actif", not find("Leaderboard").disabled)

	# Classement.
	await click("Leaderboard")
	await wait(40)
	check("classement vide : " + find("Status").text, screen().current_screen() == &"leaderboard" and find("Status").text.begins_with("Aucun temps"))
	await click("Retour")
	check("retour du classement", screen().current_screen() == &"home")

	# Nouvelle partie : introduction puis hub, dans la sauvegarde du compte.
	await click("NewGame")
	check("introduction", screen().current_screen() == &"intro")
	await click("Commencer")
	await wait(40)
	check("hub charge", current_scene.scene_file_path.ends_with("hub.tscn"))
	check("partie neuve dans le bunker", not game.intro_done and current_scene.get_node("Player").global_position.y < -30)

	# Pause : Échap ouvre et ferme, puis retour au menu.
	await action("pause")
	check("pause ouverte", pause.is_open() and paused)
	await action("pause")
	check("pause fermee", not pause.is_open() and not paused)
	await action("hint")
	check("indice du hub : " + hints.get_node("Hint").find_child("Body", true, false).text, hints.is_open() and paused)
	await action("hint")
	check("indice ferme", not hints.is_open() and not paused)
	game.intro_done = true
	game.save_game()
	await action("pause")
	pause.get_node("Pause").find_child("MainMenu", true, false).pressed.emit()
	await wait(20)
	check("menu principal depuis la pause", current_scene.scene_file_path.ends_with("main_menu.tscn") and not paused)
	check("charger actif avec une partie en cours", not find("LoadGame").disabled)

	# Nouvelle partie avec une partie en cours : confirmation.
	await click("NewGame")
	check("confirmation avant d'effacer la partie", find("Confirm") != null)
	await click("Cancel")
	await wait(2)
	check("annuler garde l'accueil", screen().current_screen() == &"home" and game.intro_done)
	await click("LoadGame")
	await wait(40)
	check("partie chargee au hub, hors du bunker", current_scene.scene_file_path.ends_with("hub.tscn") and current_scene.get_node("Player").global_position.y > -5)

	# Indices progressifs dans la Plaine.
	change_scene_to_file("res://scenes/levels/plaine/plaine.tscn")
	await wait(40)
	hints.revealed.clear()
	var counter: Label = hints.get_node("Hint").find_child("Counter", true, false)
	await action("hint")
	check("premier indice de la plaine : " + counter.text, hints.is_open() and counter.text.begins_with("Indice 1 sur 3"))
	await action("hint")
	await action("hint")
	check("deuxieme indice : " + counter.text, counter.text.begins_with("Indice 2 sur 3"))
	await action("hint")
	await action("hint")
	await action("hint")
	check("troisieme et dernier indice : " + counter.text, counter.text == "Indice 3 sur 3")
	check("indice ferme apres le troisieme", not hints.is_open())
	await action("pause")
	check("pause apres la fermeture de l'indice", pause.is_open())
	await action("pause")
	check("pause refermee", not pause.is_open() and not paused)

	# Écran de fin : bouton du menu principal.
	game.time_left = 1.0
	await wait(90)
	var game_over_menu := current_scene.get_node("Hud").find_child("MainMenu", true, false) as Button
	check("menu principal sur l'ecran de fin", game_over_menu != null and game_over_menu.is_visible_in_tree())
	await action("pause")
	check("pas de pause sur l'ecran de fin", not pause.is_open())
	if game_over_menu:
		game_over_menu.pressed.emit()
	await wait(20)
	check("retour au menu apres l'eruption", current_scene.scene_file_path.ends_with("main_menu.tscn") and not game.has_erupted)

	# Création de compte, puis déconnexion.
	await click("Sedéconnecter")
	check("deconnecte", not account.is_logged_in() and find("NewGame").caption == "Jouer en tant qu'invité")
	# La déconnexion quitte aussi le mode simulé : il est remis pour la création de compte, sans serveur.
	if "simulated" in account:
		account.simulated = true
	await click("Créeruncompte")
	check("ecran de creation", screen().current_screen() == &"register")
	find("Pseudo").text = "Al"
	find("Email").text = "nexor@codia.fr"
	find("Password").text = "12345678"
	await click("Submit")
	await wait(30)
	check("pseudo trop court : " + find("Status").text, find("Status").text.contains("pseudo"))
	find("Pseudo").text = "Nexor"
	find("Password").text = "court"
	await click("Submit")
	await wait(30)
	check("mot de passe trop court : " + find("Status").text, find("Status").text.contains("8 caract"))
	find("Password").text = "un mot de passe 2026"
	await click("Submit")
	await wait(40)
	check("verification apres creation", screen().current_screen() == &"verify")
	await click("Resend")
	await wait(30)
	check("code renvoye : " + find("Status").text, find("Status").text.contains("nouveau code"))
	await click("Retour")
	check("retour vers la creation de compte", screen().current_screen() == &"register")
	await click("ToLogin")
	check("lien vers la connexion", screen().current_screen() == &"login")
	await click("Retour")
	check("retour a l'accueil", screen().current_screen() == &"home")
	account.logout()
	game.use_profile("")
	game.reset()
	finish()
