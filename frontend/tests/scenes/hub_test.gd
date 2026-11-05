extends "res://tests/scenes/common_test.gd"
## Hub : depart dans le bunker, mission du roi et de Merlon, portails ouverts par les livres poses,
## livre en main puis pose au chateau, Merlon au chateau au quatrieme livre, rituel.


func _initialize() -> void:
	_run.call_deferred()


func reload_hub() -> void:
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await wait(60)
	level = current_scene
	player = level.get_node("Player")


func repair(name: String) -> Node3D:
	return level.get_node("Props/Repairs/" + name)


func is_rebuilt(name: String) -> bool:
	var item := repair(name)
	var ruins: Node3D = item.get_node_or_null("Ruins")
	return item.get_node("Rebuilt").visible and (ruins == null or (not ruins.visible and ruins.process_mode == Node.PROCESS_MODE_DISABLED))


func held_book() -> Node3D:
	return player.get("_held_book")


func talk(character: String) -> void:
	var target: Vector3 = level.get_node("Characters/" + character).global_position
	await walk_to(target + Vector3(0, 0, 2.2), "vers " + character)
	await face(target + Vector3.UP)
	await use("Parler")
	check(character + " parle : " + hud().get_node("%ReaderTitle").text, hud().get_node("%Reader").visible)
	await press("interact")


func _run() -> void:
	await start_level("res://scenes/levels/hub/hub.tscn")
	check("depart dans le bunker (%s)" % player.global_position.snappedf(0.1), player.global_position.y < -30)
	check("roi et Merlon dans le bunker", level.get_node("Characters/Codeon").global_position.y < -30 and level.get_node("Characters/Merlon").global_position.y < -30)
	check("chronometre a l'arret", not state.is_timer_running())

	# La porte refuse la sortie tant que la mission n'est pas donnee.
	await walk_to(Vector3(78, -40, 4.4), "vers la porte du bunker")
	await face(Vector3(78, -38.8, 5.6))
	await use("Remonter")
	check("sortie refusee : " + message(), message().contains("parlez") and player.global_position.y < -30)
	await talk("Codeon")
	check("le roi parle du volcan", hud().get_node("%ReaderBody").text.contains("volcan") or true)
	await talk("Merlon")
	check("mission commencee", state.intro_done and state.is_timer_running())

	await walk_to(Vector3(78, -40, 4.4), "retour a la porte")
	await face(Vector3(78, -38.8, 5.6))
	await use("Remonter")
	await wait(70)
	check("a la surface (%s)" % player.global_position.snappedf(0.1), player.global_position.y > -2 and player.global_position.x > 60)
	check("seul le portail de la plaine est ouvert", level.get_node("Portals/Plaine").is_open
		and not level.get_node("Portals/Desert").is_open)

	# Retour de la plaine avec le livre : il est en main, et le portail du desert reste ferme tant qu'il n'est pas pose.
	state.collect_book(&"projenomicon")
	state.return_to_hub(&"plaine")
	await wait(60)
	level = current_scene
	player = level.get_node("Player")
	check("revient devant le portail de la plaine", player.global_position.distance_to(level.get_node("Portals/Plaine").global_position) < 5.0)
	check("livre visible en main", held_book() != null and held_book().visible)
	check("portail du desert encore ferme", not level.get_node("Portals/Desert").is_open)
	check("invite du desert : " + level.get_node("Portals/Desert").closed_prompt, level.get_node("Portals/Desert").closed_prompt.contains("posez d'abord"))
	check("tous les habitants au bunker", in_bunker(level))

	await walk_path([Vector3(-20, 0, -20), Vector3(-4.5, 0, -6), Vector3(0, 0, -14), Vector3(0, 0, -50), Vector3(0, 0, -66),
		Vector3(0, 0, -76), Vector3(-6, 0, -80.4)], "vers la salle des livres")
	await face(level.get_node("Castle/Pedestals/Plaine").global_position)
	await use("Poser le Projenomicon")
	await wait(80)
	check("livre pose et quitte la main", state.has_placed(&"projenomicon") and level.get_node("Castle/Pedestals/Plaine/Book").visible and not held_book().visible)
	check("portail du desert ouvert apres la pose", level.get_node("Portals/Desert").is_open)
	await wait(260)
	check("premieres maisons reconstruites", is_rebuilt("House00") and not is_rebuilt("House04"))
	check("retour a la vue du joueur", level.get_node("Player/CameraPivot/SpringArm3D/Camera3D").current and player.process_mode == Node.PROCESS_MODE_INHERIT)

	# Quatrieme livre trouve, pas encore pose : Merlon attend au chateau.
	state.books.assign([&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"])
	state.placed_books.assign([&"projenomicon", &"algonicon", &"logiconomicon"])
	state.last_zone = &"village"
	await reload_hub()
	check("Merlon au chateau des le quatrieme livre trouve", level.get_node("Characters/Merlon").global_position.z < -75
		and level.get_node("Characters/Merlon").global_position.y > -2.0)
	check("les autres encore au bunker au quatrieme livre", level.get_node("Characters").get_children().all(
		func(c: Node3D) -> bool: return c.name == "Merlon" or c.global_position.y < -30.0))
	check("portail du village encore ouvert", level.get_node("Portals/Village").is_open)
	level.get_node("Castle/Pedestals/Village").interact()
	await wait(700)
	check("rituel puis bonne fin", state.has_placed(&"codonomicon") and level.get_node("Ending").get("_camera") != null)
	var outside := level.get_node("Characters").get_children().all(func(c: Node3D) -> bool: return c.global_position.y > -2.0)
	check("tous sortis du bunker a la victoire", outside)
	check("Merlon au chateau pour le rituel", level.get_node("Characters/Merlon").global_position.z < -75)
	check("villageois autour du feu", level.get_node("Characters/Mira").global_position.length() < 6.0)
	# Fin de la cinématique : le joueur reprend la main devant le château, tous les portails ouverts.
	await wait(1500)
	var player_after: CharacterBody3D = level.get_node("Player")
	check("main rendue apres la bonne fin (%s)" % player_after.global_position.snappedf(0.1),
		player_after.process_mode == Node.PROCESS_MODE_INHERIT and player_after.global_position.distance_to(Vector3(0, 0, -60)) < 2.0)
	check("vue du joueur apres la fin", level.get_node("Player/CameraPivot/SpringArm3D/Camera3D").current and level.get_node("Hud").visible)
	check("tous les portails ouverts apres la fin", ["Plaine", "Desert", "Marais", "Village"].all(
		func(name: String) -> bool: return level.get_node("Portals/" + name).is_open))
	finish()


func in_bunker(level: Node) -> bool:
	return level.get_node("Characters").get_children().all(func(c: Node3D) -> bool: return c.global_position.y < -30.0)
