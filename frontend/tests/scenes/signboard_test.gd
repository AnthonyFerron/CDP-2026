extends SceneTree
## Collision des SignBoard : sur poteaux, les deux poteaux et la planche, rien dessous ; au mur et suspendu, inchangé.
var failures := 0

func check(label: String, ok: bool) -> void:
	print(("OK    " if ok else "ECHEC ") + label)
	if not ok:
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func hit(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	return not root.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _run() -> void:
	var board: Node3D = load("res://scripts/sign_board.gd").new()
	board.text = "Essai"
	board.board_size = Vector2(1.4, 0.8)
	board.board_height = 1.5
	root.add_child(board)
	for i in 3:
		await physics_frame
	var shapes := board.find_children("*", "CollisionShape3D", true, false)
	check("poteaux : trois formes (%d)" % shapes.size(), shapes.size() == 3)
	check("le vide sous la planche ne bloque pas", not hit(Vector3(0, 0.5, 2), Vector3(0, 0.5, -2)))
	check("la planche bloque", hit(Vector3(0, 1.5, 2), Vector3(0, 1.5, -2)))
	check("le poteau gauche bloque", hit(Vector3(-0.73, 0.5, 2), Vector3(-0.73, 0.5, -2)))
	check("le poteau droit bloque", hit(Vector3(0.73, 0.5, 2), Vector3(0.73, 0.5, -2)))
	board.mount = 2  # suspendu
	for i in 3:
		await physics_frame
	check("suspendu : une forme, le montant", board.find_children("*", "CollisionShape3D", true, false).size() == 1)
	board.mount = 1  # au mur
	for i in 3:
		await physics_frame
	check("au mur : une forme, la planche", board.find_children("*", "CollisionShape3D", true, false).size() == 1)
	check("au mur : rien sous la planche", not hit(Vector3(0, 0.5, 2), Vector3(0, 0.5, -2)))
	print("RESULTAT : %d echec(s)" % failures)
	quit(1 if failures else 0)
