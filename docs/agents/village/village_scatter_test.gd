extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Village : les herbes et gravats qui s'effacent au loin ne clignotent plus sous les pieds. Le joueur parcourt le
## bourg et ses abords (cercles de 10 à 62 m, tous les 3 m) ; à chaque pas, toute case de détails qui a des copies à
## moins de 12 m de lui doit être entièrement visible (sa distance d'effacement se mesure jusqu'au centre de la case).

const NEAR := 12.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	var chunks: Array[MultiMeshInstance3D] = []
	for node in level.get_node("Scatter").find_children("*", "MultiMeshInstance3D", true, false):
		if (node as MultiMeshInstance3D).visibility_range_end > 0.0:
			chunks.append(node)
	check("détails découpés en cases (%d cases qui s'effacent)" % chunks.size(), chunks.size() > 8)
	# Les petits objets du décor (vivres, outils, bougies), dessinés en une fois par VillageInstances.
	var small := 0
	for group in level.get_node("Props/Instances").get_children():
		for node in group.get_children(true):
			if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).visibility_range_end > 0.0:
				chunks.append(node)
				small += 1
	check("petits objets découpés en cases (%d cases)" % small, small > 8)
	var biggest := 0.0
	for chunk in chunks:
		var box := chunk_box(chunk)
		biggest = maxf(biggest, maxf(box.size.x, box.size.z))
	check("aucune case de plus de 32 m de côté (la plus grande : %.1f m)" % biggest, biggest <= 32.0 + 6.0)
	var steps := 0
	var failures_here := []
	for radius in [10.0, 22.0, 34.0, 46.0, 54.0, 62.0]:
		var count := int(TAU * radius / 3.0)
		for index in count:
			var angle := TAU * index / count
			var eye := Vector3(cos(angle) * radius, 1.65, sin(angle) * radius)
			steps += 1
			for chunk in chunks:
				var box := chunk_box(chunk)
				var flat := Vector2(eye.x, eye.z)
				var nearest := flat.clamp(Vector2(box.position.x, box.position.z), Vector2(box.end.x, box.position.z + box.size.z))
				if nearest.distance_to(flat) > NEAR:
					continue
				var to_center := eye.distance_to(box.get_center())
				if to_center > chunk.visibility_range_end - chunk.visibility_range_end_margin:
					failures_here.append("%s : case à %.0f m de son centre" % [eye.snappedf(0.1), to_center])
	for line in failures_here.slice(0, 10):
		print("       " + line)
	check("%d pas autour du bourg : aucun détail proche effacé (%d)" % [steps, failures_here.size()], failures_here.is_empty())
	finish()


## Boîte d'une case, calculée sur ses copies comme le fait le serveur de rendu (le MultiMesh ne la donne pas sans
## affichage).
func chunk_box(chunk: MultiMeshInstance3D) -> AABB:
	var multimesh := chunk.multimesh
	var local := multimesh.mesh.get_aabb()
	var box := AABB()
	for index in multimesh.instance_count:
		var part := chunk.global_transform * multimesh.get_instance_transform(index) * local
		box = part if index == 0 else box.merge(part)
	return box
