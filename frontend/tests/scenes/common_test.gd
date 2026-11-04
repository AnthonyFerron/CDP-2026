extends SceneTree
## Outils partages par les tests de parcours : deplacements, touche d'interaction, verifications.

var failures := 0
var level: Node
var player: Node3D
var state: Node


func check(label: String, ok: bool) -> void:
	print(("OK    " if ok else "ECHEC ") + label)
	if not ok:
		failures += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func hud() -> Node:
	return level.get_node("Hud")


func prompt() -> String:
	var label: Label = hud().get_node("%Prompt")
	return label.text if label.visible else ""


func message() -> String:
	return hud().get_node("%Message").text


func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await wait(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await wait(3)


func hold(action: String, frames: int) -> void:
	Input.action_press(action)
	await wait(frames)
	Input.action_release(action)
	await wait(3)


func walk_to(target: Vector3, label: String, limit := 900) -> bool:
	var pivot: Node3D = player.get_node("CameraPivot")
	Input.action_press("move_forward")
	var best := INF
	var stuck := 0
	var reached := false
	for i in limit:
		await physics_frame
		if not is_instance_valid(player) or player.process_mode == Node.PROCESS_MODE_DISABLED:
			break
		var offset := target - player.global_position
		var flat := Vector2(offset.x, offset.z)
		if flat.length() < 0.5:
			reached = true
			break
		pivot.rotation.y = atan2(-offset.x, -offset.z)
		if flat.length() < best - 0.01:
			best = flat.length()
			stuck = 0
		else:
			stuck += 1
			if stuck > 120:
				break
	Input.action_release("move_forward")
	await wait(4)
	if is_instance_valid(player):
		check("%s (pos %s)" % [label, player.global_position.snappedf(0.1)], reached)
	return reached


func walk_path(points: Array, label: String) -> void:
	for point: Vector3 in points:
		await walk_to(point, label)


func face(target: Vector3) -> void:
	var offset := target - player.global_position
	player.get_node("CameraPivot").rotation.y = atan2(-offset.x, -offset.z)
	await wait(3)


func use(expected: String) -> void:
	check("invite : " + prompt(), prompt().contains(expected))
	await press("interact")


func read(expected: String) -> void:
	await use(expected)
	check("texte ouvert", hud().get_node("%Reader").visible)
	await press("interact")


func start_level(path: String) -> void:
	state = root.get_node("GameState")
	state.reset()
	# Hors du hub, la mission est déjà en cours : le chronomètre tourne.
	if not path.ends_with("hub.tscn"):
		state.begin_mission()
	change_scene_to_file(path)
	await wait(60)
	level = current_scene
	player = level.get_node("Player")


func finish() -> void:
	state.reset()
	print("RESULTAT : %d echec(s)" % failures)
	quit(1 if failures else 0)
