extends SceneTree


func _initialize() -> void:
	var box := BoxMesh.new()
	var tm: TriangleMesh = box.generate_triangle_mesh()
	print("tm ", tm)
	print("methods ", tm.get_method_list().map(func(m): return m.name))
	var hit = tm.intersect_segment(Vector3(0, 0, -3), Vector3(0, 0, 3))
	print("hit ", hit)
	quit()
