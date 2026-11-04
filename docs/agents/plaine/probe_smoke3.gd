extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Sonde : quelle propriété de SmokeEffect retient ses particules au sol (hauteur atteinte au bout de 8 s).


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var variants := {}
	for name in ["tel quel", "sans courbe d'échelle", "sans gravité", "sans préchauffe", "courbe de 0 à 1"]:
		var smoke := SmokeEffect.new()
		world.add_child(smoke)
		match name:
			"sans courbe d'échelle":
				smoke.scale_amount_curve = null
			"sans gravité":
				smoke.gravity = Vector3.ZERO
			"sans préchauffe":
				smoke.preprocess = 0.0
				smoke.restart()
			"courbe de 0 à 1":
				var curve := Curve.new()
				curve.add_point(Vector2(0.0, 0.5))
				curve.add_point(Vector2(1.0, 1.0))
				smoke.scale_amount_curve = curve
		variants[name] = smoke
	for i in 480:
		await process_frame
	for name in variants:
		var smoke: CPUParticles3D = variants[name]
		print("%s : hauteur %.2f m (aabb %s), courbe max %s" % [name, smoke.capture_aabb().size.y, smoke.capture_aabb(),
			smoke.scale_amount_curve.max_value if smoke.scale_amount_curve else "-"])
	finish()


func finish() -> void:
	print("RESULTAT : 0 echec(s)")
	quit(0)
