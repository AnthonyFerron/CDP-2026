extends SceneTree
## Hauteur réelle de la tête des personnages, en pose de repos puis pendant l'animation idle :
## boîte du maillage posé (bake_mesh_from_current_skeleton_pose) et pose de l'os de la tête.
func _initialize() -> void:
	_run.call_deferred()


func report(model: Node3D, label: String) -> void:
	var skeleton: Skeleton3D = model.get_node("Skeleton3D") if model.has_node("Skeleton3D") else model.find_children("*", "Skeleton3D", true, false)[0]
	var head := skeleton.find_bone("head")
	var pose := skeleton.get_bone_global_pose(head)
	var line := "%s : os tête %s rot %s" % [label, pose.origin.snappedf(0.001), pose.basis.get_euler().snappedf(0.01)]
	for bone_name in ["torso", "arm-left", "arm-right"]:
		var b := skeleton.get_bone_global_pose(skeleton.find_bone(bone_name))
		line += " | %s %s rot %s" % [bone_name, b.origin.snappedf(0.001), b.basis.get_euler().snappedf(0.01)]
	print(line)


func _run() -> void:
	for m in OS.get_cmdline_user_args():
		var model: Node3D = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(model)
		await process_frame
		report(model, m + " repos")
		var player: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
		var idle := player.get_animation(OS.get_environment("ANIM") if OS.get_environment("ANIM") != "" else "idle")
		print("  idle : %.2f s, boucle %d" % [idle.length, idle.loop_mode])
		player.play(idle.resource_name if idle.resource_name != "" else player.find_animation(idle))
		for t: float in [0.0, idle.length * 0.25, idle.length * 0.5, idle.length * 0.75]:
			player.seek(t, true)
			await process_frame
			report(model, "  idle %.2f" % t)
		model.queue_free()
		await process_frame
	quit()
