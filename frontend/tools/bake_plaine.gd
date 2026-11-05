extends SceneTree
## Calcule d'avance ce que la Plaine calculait à chaque chargement (6 s sur ordinateur, bien plus dans un
## navigateur) et l'écrit dans scenes/levels/plaine/plaine_bake.res (PlaineBake) :
## - le sol de PlaineTerrain : hauteurs de la grille et maillage (sommets, normales, couleurs, lueurs) ;
## - les bandes de la zone qui brûle de PlaineScatter.
## Ce sont les mêmes fonctions qu'au chargement, lancées ici sans données d'avance : le résultat est identique,
## et deux passages écrivent le même fichier.
## À relancer après tout changement du relief, des cratères, de la coulée ou de la zone qui brûle (sinon la Plaine
## le signale au chargement et recalcule tout) :
##   cd frontend && godot --headless --path . --script res://tools/bake_plaine.gd
## Avec « -- --check », rien n'est écrit : le script compare le fichier au calcul, et sort en erreur s'ils diffèrent.

const PATH := "res://scenes/levels/plaine/plaine_bake.res"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var check := OS.get_cmdline_user_args().has("--check")
	var start := Time.get_ticks_msec()
	var terrain := PlaineTerrain.new()
	root.add_child(terrain)
	var ground := (terrain.get_child(0) as MeshInstance3D).mesh as ArrayMesh
	var scatter := PlaineScatter.new()
	scatter.terrain = terrain
	scatter.compute_lava_pools()
	var strips := scatter.lava_hazard_strips()
	scatter.free()

	var bake := PlaineBake.new()
	bake.terrain_signature = PlaineTerrain.settings_signature()
	bake.heights = terrain.grid_heights()
	var levels := PackedFloat32Array()
	for index in PlaineTerrain.CRATERS.size():
		levels.append(terrain.crater_lava_level(index))
	bake.pool_levels = levels
	# Le maillage même du terrain, sans matériau : le terrain pose le sien au chargement. Son identifiant fixe garde
	# le fichier identique d'un passage à l'autre.
	var mesh := ground
	mesh.surface_set_material(0, null)
	mesh.resource_scene_unique_id = "ground"
	bake.ground = mesh
	bake.hazard_signature = PlaineScatter.hazard_signature()
	bake.hazard_positions = strips[0]
	bake.hazard_sizes = strips[1]
	terrain.queue_free()
	print("Plaine : sol de %d sommets, %d bandes de lave, calculés en %d ms" % [
		mesh.surface_get_array_len(0), strips[0].size(), Time.get_ticks_msec() - start])

	if check:
		var saved := load(PATH) as PlaineBake
		var same := saved != null and saved.terrain_signature == bake.terrain_signature \
			and saved.heights == bake.heights and saved.pool_levels == bake.pool_levels \
			and saved.hazard_signature == bake.hazard_signature and saved.hazard_positions == bake.hazard_positions \
			and saved.hazard_sizes == bake.hazard_sizes and saved.ground != null \
			and saved.ground.surface_get_arrays(0) == mesh.surface_get_arrays(0)
		print("Plaine : %s" % ("données d'avance à jour" if same else "DONNÉES D'AVANCE PÉRIMÉES, relancer tools/bake_plaine.gd"))
		quit(0 if same else 1)
		return
	var error := ResourceSaver.save(bake, PATH, ResourceSaver.FLAG_COMPRESS)
	print("Plaine : %s écrit (%d octets)" % [PATH, FileAccess.get_file_as_bytes(PATH).size()] if error == OK
		else "Plaine : écriture impossible (%s)" % error_string(error))
	quit(0 if error == OK else 1)
