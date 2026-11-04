extends SceneTree
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 30:
		await process_frame
	var level: Node = current_scene
	var merlon: Node3D = level.get_node("Characters/Merlon")
	var skeleton: Skeleton3D = merlon.get_node("Model").find_child("Skeleton3D", true, false)
	var bone := skeleton.find_bone("arm-left")
	print("avant : ", skeleton.get_bone_pose_rotation(bone).get_euler())
	level.call("_raise_arms", 0.2)
	for i in 30:
		await process_frame
	print("après : ", skeleton.get_bone_pose_rotation(bone).get_euler(), " lecture : ", merlon.get_node("Model/AnimationPlayer").is_playing())
	var hand: Node3D = merlon.find_child("Hand", true, false)
	print("main : ", hand.global_position if hand else "?")
	quit()
