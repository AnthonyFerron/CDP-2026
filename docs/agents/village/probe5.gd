extends SceneTree
## Profil du tablier du pont (nature_kit/bridge_wood) à l'échelle 6,5, sans rotation : hauteur le long de x et de z.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var bridge: Node3D = load("res://assets/models/kenney/nature_kit/bridge_wood.glb").instantiate()
	bridge.scale = Vector3.ONE * 6.5
	root.add_child(bridge)
	for mesh: MeshInstance3D in bridge.find_children("*", "MeshInstance3D", true, false):
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = mesh.mesh.create_trimesh_shape()
		body.add_child(shape)
		mesh.add_child(body)
	for i in 3:
		await physics_frame
	var space := bridge.get_world_3d().direct_space_state
	for axis in ["x", "z"]:
		var line := []
		for i in range(-8, 9):
			var t := i * 0.45
			var at := Vector3(t, 10, 0) if axis == "x" else Vector3(0, 10, t)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 20))
			line.append("%.1f:%s" % [t, ("%.2f" % hit.position.y) if hit else "-"])
		print(axis, " ", " ".join(line))
	quit()
