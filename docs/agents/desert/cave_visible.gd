extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_audit_test.gd"
## Dans la cave : ce qui reste visible hors de l'intérieur, et le nombre d'objets visibles par branche.


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	await wait(5)
	level.set("_inside", true)
	level.call("_apply_location")
	await wait(5)
	var counts := {}
	for node: Node in level.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		if not geometry.is_visible_in_tree():
			continue
		var path := str(level.get_path_to(geometry)).split("/")
		var key := "/".join(path.slice(0, mini(3, path.size() - 1)))
		counts[key] = counts.get(key, 0) + 1
	var keys := counts.keys()
	keys.sort()
	for key in keys:
		print("CAVE %s : %d" % [key, counts[key]])
	finish()
