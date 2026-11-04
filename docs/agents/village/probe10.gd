extends SceneTree
## Durée de chargement du Village et part de la dispersion (herbes, arbres, rochers).

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var start := Time.get_ticks_msec()
	var scene: Node = (load("res://scenes/levels/village/village.tscn") as PackedScene).instantiate()
	var loaded := Time.get_ticks_msec()
	root.add_child(scene)
	var ready := Time.get_ticks_msec()
	print("chargement %d ms, _ready %d ms" % [loaded - start, ready - loaded])
	var scatter: Node = scene.get_node("Scatter")
	var shapes := 0
	var points := 0
	for body in scatter.get_children():
		if body is StaticBody3D:
			for child in body.get_children():
				if child is CollisionShape3D and child.shape is ConvexPolygonShape3D:
					shapes += 1
					points += (child.shape as ConvexPolygonShape3D).points.size()
	print("formes convexes %d, points %d" % [shapes, points])
	var t0 := Time.get_ticks_msec()
	var fresh: Node = (load("res://scenes/levels/village/village_scatter.gd") as Script).new()
	fresh.free()
	quit()
