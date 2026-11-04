extends SceneTree
## Mesure la boîte englobante (échelle 1) de chaque modèle listé dans boxes_in.txt (« kit/modele » par ligne),
## et l'écrit dans boxes_out.txt : modèle, coin et taille, et hauteur du maillage le plus bas sous l'origine.
const DIR := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var lines := FileAccess.get_file_as_string(DIR + "boxes_in.txt").split("\n", false)
	var out := FileAccess.open(DIR + "boxes_out.txt", FileAccess.WRITE)
	var world := Node3D.new()
	root.add_child(world)
	for model in lines:
		model = model.strip_edges()
		var scene: PackedScene = load("res://assets/models/kenney/%s.glb" % model)
		if not scene:
			out.store_line("%s\tABSENT" % model)
			continue
		var node: Node3D = scene.instantiate()
		world.add_child(node)
		await process_frame
		var box := AABB()
		var first := true
		var parts := []
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			var part: AABB = mesh.global_transform * mesh.get_aabb()
			box = part if first else box.merge(part)
			first = false
			parts.append("%s:%.3f..%.3f" % [mesh.name, part.position.y, part.end.y])
		out.store_line("%s\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%s" % [model, box.position.x, box.position.y,
			box.position.z, box.size.x, box.size.y, box.size.z, " ".join(parts)])
		node.free()
	out.close()
	quit()
