extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Sonde : dans le niveau, les particules de fumée avancent-elles ? Hauteur à 1 s et à 8 s, pour la fumée du
## trébuchet (SmokeEffect de la scène), une fumée de cratère, et un SmokeEffect ajouté après le chargement.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var fresh := SmokeEffect.new()
	fresh.position = Vector3(-16.4, 1.2, 45.0)
	level.get_node("Exterior/Ambience").add_child(fresh)
	var trebuchet: CPUParticles3D = level.get_node("Exterior/Ambience/TrebuchetSmoke")
	var crater: CPUParticles3D
	for node in level.get_node("Exterior/Scatter").get_children():
		if node is CPUParticles3D and (node as CPUParticles3D).mesh is QuadMesh:
			crater = node
			break
	for seconds in [1, 8]:
		for i in 60 * (seconds if seconds == 1 else 7):
			paused = false
			await process_frame
		for item in [["trébuchet", trebuchet], ["cratère", crater], ["ajoutée", fresh]]:
			var particles: CPUParticles3D = item[1]
			print("t %d s, %s : hauteur %.2f, émet %s, visible %s, processus %s, preprocess %.1f" % [seconds, item[0],
				particles.capture_aabb().size.y, particles.emitting, particles.is_visible_in_tree(),
				particles.can_process(), particles.preprocess])
	finish()
