extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	level.set("_inside", true)
	level.call("_apply_location")
	var target: Vector3 = level.get_node("Interior/Fragments/Fragment7").global_position
	for spot in [Vector3(1.5, -40, -3.5), Vector3(1.0, -40, -3.8), Vector3(1.7, -40, -3.6), Vector3(0.6, -40, -4.4)]:
		player.global_position = spot + Vector3.UP * 0.05
		var offset := target - player.global_position
		player.get_node("CameraPivot").rotation.y = atan2(-offset.x, -offset.z)
		await wait(6)
		print("%s -> pos %s prompt %s" % [spot, player.global_position.snappedf(0.01), prompt()])
	finish()
