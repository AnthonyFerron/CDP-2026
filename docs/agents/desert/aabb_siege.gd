extends SceneTree
const MODELS := ["castle_kit/siege-catapult-demolished", "castle_kit/siege-ballista-demolished", "castle_kit/siege-trebuchet-demolished", "castle_kit/siege-ram-demolished"]
func _initialize():
	for m in MODELS:
		var res = load("res://assets/models/kenney/%s.glb" % m)
		if res == null:
			print("%-40s MANQUANT" % m)
			continue
		var s: Node = res.instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		var count := 0
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
			count += 1
		print("BOX %-40s pos %s size %s meshes %d" % [m, box.position.snappedf(0.01), box.size.snappedf(0.01), count])
		s.free()
	quit()
