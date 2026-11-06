extends "res://tests/scenes/common_test.gd"
## Qualité adaptative (render_quality.gd), avec des images lentes simulées (forced_ms) : descente d'un cran à la
## fois, ombres allégées puis coupées, décor fin et particules réduits, mémorisation du cran, pas de remontée
## pendant un lieu, remontée d'un cran seulement au lieu suivant après un lieu très fluide, retour exact des
## réglages des scènes. Lancé avec --qualite-auto : en natif, l'adaptation est sinon coupée.

var rq: Node
## Crans vus, dans l'ordre, et état du soleil au cran 4.
var seen: Array[int] = []
var slow_until := 6
var sun_at_4 := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	rq = root.get_node("RenderQuality")
	check("adaptation active avec --qualite-auto", rq.adaptive)
	rq.window = 0.4
	rq.reset_tier()
	rq.tier_changed.connect(_on_tier)

	# Hub, images lentes : la qualité baisse d'un cran à chaque mesure. À 55 %, les images deviennent fluides :
	# le lieu ne remonte pas pour autant.
	rq.forced_ms = 30.0
	slow_until = 3
	seen = [rq.tier]
	await start_level("res://scenes/levels/hub/hub.tscn")
	var sun := _sun()
	var started := Time.get_ticks_msec()
	while rq.tier < 3 and Time.get_ticks_msec() - started < 20000:
		await process_frame
	check("descente d'un cran a la fois jusqu'a 3 (%s)" % [seen], seen == [0, 1, 2, 3])
	check("cran 3 : 3D a 55 %% (%.2f)" % root.scaling_3d_scale, is_equal_approx(root.scaling_3d_scale, 0.55))
	check("cran 3 : ombres du soleil intactes", sun.shadow_enabled and sun.directional_shadow_mode != DirectionalLight3D.SHADOW_ORTHOGONAL)
	await _wait_measure()
	check("lieu fluide apres une baisse : pas de remontee pendant le lieu (cran %d, %.1f ms)" % [rq.tier, rq.last_ms], rq.tier == 3)
	check("cran retenu dans le fichier de reglages", rq._load_tier() == 3)

	# Plaine : on arrive au cran retenu ; très fluide sans baisse, mais la remontée attend le lieu suivant.
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	check("plaine : arrivee au cran retenu (%d)" % rq.tier, rq.tier == 3)
	await _wait_measure()
	check("plaine tres fluide : toujours le cran 3 pendant le lieu", rq.tier == 3)
	var smoke := _first(level, "CPUParticles3D") as CPUParticles3D
	var amount := smoke.amount if smoke else 0
	rq.set_tier(6)
	check("cran 6 : particules reduites (%d -> %d)" % [amount, smoke.amount if smoke else 0], smoke != null and smoke.amount < amount)
	rq.set_tier(3)
	check("retour au cran 3 : particules d'origine", smoke != null and smoke.amount == amount)

	# Désert : un cran de plus, gagné par la plaine fluide. Puis images lentes jusqu'au cran le plus bas.
	await start_level("res://scenes/levels/desert/desert.tscn")
	check("desert : remontee d'un cran entre deux lieux (%d)" % rq.tier, rq.tier == 2)
	check("cran 2 : 3D a 70 %% (%.2f)" % root.scaling_3d_scale, is_equal_approx(root.scaling_3d_scale, 0.7))
	sun = _sun()
	var distance := sun.directional_shadow_max_distance
	var mode := sun.directional_shadow_mode
	var detail := _detail(level)
	var range_end := detail.visibility_range_end if detail else 0.0
	slow_until = 6
	seen = [rq.tier]
	rq.forced_ms = 30.0
	rq._start_measure()
	started = Time.get_ticks_msec()
	while rq.tier < 6 and Time.get_ticks_msec() - started < 20000:
		await process_frame
	check("desert : descente d'un cran a la fois (%s)" % [seen], seen == [2, 3, 4, 5, 6])
	check("cran 4 : ombres allegees (%s)" % [sun_at_4], sun_at_4.get("shadow", false)
			and sun_at_4.get("distance", 99.0) <= 30.0 and sun_at_4.get("mode", -1) == DirectionalLight3D.SHADOW_ORTHOGONAL)
	check("cran 6 atteint (%d)" % rq.tier, rq.tier == 6)
	check("cran 6 : ombres du soleil coupees", not sun.shadow_enabled)
	check("cran 6 : decor fin moins loin (%.0f -> %.0f m)" % [range_end, detail.visibility_range_end if detail else 0.0],
			detail != null and detail.visibility_range_end < range_end)
	check("cran 6 retenu", rq._load_tier() == 6)
	await _wait_measure()
	check("cran 6 : on ne descend pas plus bas", rq.tier == 6)

	# F4 : une résolution fixe garde son échelle, quel que soit le cran.
	rq._scale_index = 1
	rq._apply_scale()
	check("F4 a 100 %% : echelle fixe (%.2f)" % root.scaling_3d_scale, is_equal_approx(root.scaling_3d_scale, 1.0))
	rq._scale_index = 0
	rq._apply_scale()

	# Retour à la qualité pleine : la scène retrouve ses propres réglages.
	rq.reset_tier()
	check("cran 0 : 3D pleine (%.2f)" % root.scaling_3d_scale, root.scaling_3d_scale > 0.99)
	check("cran 0 : ombres du soleil d'origine", sun.shadow_enabled and is_equal_approx(sun.directional_shadow_max_distance, distance) and sun.directional_shadow_mode == mode)
	check("cran 0 : decor fin d'origine", detail != null and is_equal_approx(detail.visibility_range_end, range_end))
	rq.forced_ms = 0.0
	finish()


func _on_tier(value: int) -> void:
	seen.append(value)
	# Images redevenues fluides à partir de ce cran.
	if value >= slow_until:
		rq.forced_ms = 8.0
	if value == 4:
		var sun := _sun()
		sun_at_4 = {"shadow": sun.shadow_enabled, "distance": sun.directional_shadow_max_distance,
				"mode": sun.directional_shadow_mode}


## Attend la fin de la mesure en cours.
func _wait_measure() -> void:
	var started := Time.get_ticks_msec()
	while rq.is_measuring() and Time.get_ticks_msec() - started < 10000:
		await process_frame
	await process_frame


func _sun() -> DirectionalLight3D:
	return _first(current_scene, "DirectionalLight3D") as DirectionalLight3D


func _first(node: Node, type: String) -> Node:
	var found := node.find_children("*", type, true, false)
	return found[0] if not found.is_empty() else null


func _detail(node: Node) -> GeometryInstance3D:
	for mesh in node.find_children("*", "GeometryInstance3D", true, false):
		if (mesh as GeometryInstance3D).visibility_range_end > 0.0:
			return mesh
	return null
