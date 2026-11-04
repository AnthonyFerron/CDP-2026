extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Audit des marais de Kernel Swamp : pour chaque point d'interaction (indices, portes, mécanisme, tombeaux,
## épitaphes, livre, portail), vérifie que son point n'est pas dans une collision, qu'un sol libre existe à portée
## (le joueur y tient debout, hors de l'eau profonde), que rien ne coupe la vue entre les yeux (1,65 m) et l'objet,
## puis y place le joueur, le tourne vers l'objet et lit l'invite. Vérifie aussi qu'aucun texte ne flotte.
## Avec un affichage (sans --headless), une capture de chaque point est enregistrée dans agents/marais/audit/.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/audit/"
const EYE := 1.65
const SINK := -0.85

var shots := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	shots = DisplayServer.get_name() != "headless"
	if shots:
		DirAccess.make_dir_recursive_absolute(OUT)
	await start_level("res://scenes/levels/marais/marais.tscn")
	hud().get_node("%Message").text = ""
	check_labels()
	print("--- dehors")
	for target in interactables(false):
		await audit(target)
	# Dans la crypte : tout sauf le livre, encore caché ; puis le tombeau s'ouvre et l'on audite le livre.
	level.set("_inside", true)
	level.call("_apply_location")
	await wait(4)
	print("--- crypte")
	for target in interactables(true):
		await audit(target)
	level.call("_on_mechanism_validated", true)
	await wait(240)
	var book: Interactable = level.get_node("Interior/Tomb/Book/Interactable")
	check("le livre est visible et actif", book.enabled and book.is_visible_in_tree())
	await audit(book)
	finish()


## Points d'interaction actifs et visibles, dehors ou dans la crypte (sous la carte).
func interactables(inside: bool) -> Array[Interactable]:
	var result: Array[Interactable] = []
	for node in root.get_tree().get_nodes_in_group(&"interactable"):
		var target := node as Interactable
		if target.enabled and target.is_visible_in_tree() and (target.global_position.y < -20.0) == inside:
			result.append(target)
	return result


func label_of(target: Interactable) -> String:
	return String(level.get_path_to(target)).replace("/", ".")


## Aucun texte flottant : pas de Label3D tourné vers la caméra, avec contour, ou visible à travers les murs.
func check_labels() -> void:
	var bad := 0
	for label: Label3D in level.find_children("*", "Label3D", true, false):
		if label.billboard != BaseMaterial3D.BILLBOARD_DISABLED or label.outline_size > 0 or label.no_depth_test:
			print("  texte flottant : ", level.get_path_to(label))
			bad += 1
	check("aucun texte flottant (%d)" % bad, bad == 0)


func audit(target: Interactable) -> void:
	var name := label_of(target)
	var point := target.global_position
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsPointQueryParameters3D.new()
	# Un point posé à même le sol (le portail) touche le sol sans y être enfoui : on le teste 10 cm plus haut.
	query.position = point + Vector3.UP * 0.1
	query.exclude = [player.get_rid()]
	check("%s : point hors collision" % name, space.intersect_point(query).is_empty())
	var spot := find_spot(target)
	if spot == Vector3.INF:
		check("%s : sol libre à portée, vue dégagée et bonne invite" % name, false)
		return
	player.global_position = spot + Vector3.UP * 0.05
	player.velocity = Vector3.ZERO
	await face(point)
	await wait(6)
	player.global_position = spot + Vector3.UP * 0.05
	await face(point)
	await wait(4)
	check("%s : invite « %s » depuis %s" % [name, prompt(), spot.snappedf(0.1)], prompt().contains(target.prompt))
	if shots:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + name + ".png")


## Un sol où le joueur tient debout, à portée de l'objet, d'où on le voit et d'où il serait choisi.
func find_spot(target: Interactable) -> Vector3:
	var point := target.global_position
	var space := player.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	# D'abord à bonne distance, comme on s'approche naturellement, puis de plus près.
	var distances: Array[float] = []
	var d := target.radius - 0.25
	while d > 0.8:
		distances.append(d)
		d -= 0.35
	for distance in distances:
		for step in 24:
			var angle := TAU * step / 24.0
			var x := point.x + cos(angle) * distance
			var z := point.z + sin(angle) * distance
			# Le sol sous le point, pas le dessus d'un tombeau ou d'un meuble plus haut que lui, ni le plafond.
			var ray := PhysicsRayQueryParameters3D.create(Vector3(x, point.y + 0.3, z), Vector3(x, point.y - 4.0, z))
			ray.exclude = [player.get_rid()]
			var hit := space.intersect_ray(ray)
			if hit.is_empty() or hit.normal.y < 0.7:
				continue
			var floor: Vector3 = hit.position
			# Un point au ras du sol (le portail) se lit depuis le sol même ; sinon, pas depuis le dessus d'un objet.
			var on_ground: bool = hit.collider == level.get_node("Terrain")
			if (floor.y > point.y - 0.5 and not on_ground) or absf(floor.y - point.y) > 2.9 or (floor.y > -20.0 and floor.y < SINK):
				continue
			var shape := PhysicsShapeQueryParameters3D.new()
			shape.shape = capsule
			shape.transform = Transform3D(Basis(), floor + Vector3.UP * 0.97)
			shape.exclude = [player.get_rid()]
			if not space.intersect_shape(shape, 1).is_empty():
				continue
			var eye := floor + Vector3.UP * EYE
			var sight := PhysicsRayQueryParameters3D.create(eye, point)
			sight.exclude = [player.get_rid()]
			var blocker := space.intersect_ray(sight)
			if not blocker.is_empty() and (blocker.position as Vector3).distance_to(point) > 0.12:
				continue
			if nearest_from(floor, point) != target:
				continue
			return floor
	return Vector3.INF


## Le point d'interaction que choisirait l'InteractionController depuis ce sol, tourné vers la cible.
func nearest_from(feet: Vector3, look_at: Vector3) -> Interactable:
	var forward := Vector2(look_at.x - feet.x, look_at.z - feet.z).normalized()
	var nearest: Interactable
	var best := INF
	for node in root.get_tree().get_nodes_in_group(&"interactable"):
		var other := node as Interactable
		if not other.enabled or not other.is_visible_in_tree():
			continue
		var offset := other.global_position - feet
		var flat := Vector2(offset.x, offset.z)
		var distance := flat.length()
		if distance > 1.0 and flat.normalized().dot(forward) < 0.2:
			continue
		if distance < other.radius and distance < best and absf(offset.y) < 3.0:
			nearest = other
			best = distance
	return nearest
