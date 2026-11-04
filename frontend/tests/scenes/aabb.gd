extends SceneTree
const MODELS := ["graveyard_kit/gravestone-round", "graveyard_kit/gravestone-cross", "graveyard_kit/candle-multiple"]
func _initialize():
	for m in MODELS:
		var s: Node = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
		print("%-40s pos %s size %s" % [m, box.position.snappedf(0.01), box.size.snappedf(0.01)])
		s.free()
	quit()
