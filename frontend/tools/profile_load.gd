extends SceneTree
## Temps de chargement d'un lieu, poste par poste : lecture de la ressource (.tscn et tout ce qu'elle charge),
## instanciation, _ready de chaque nœud (les plus chers d'abord), puis les premières images jusqu'au rythme stable.
## Un lieu par lancement, pour mesurer un chargement à froid comme celui du jeu :
##   cd frontend && godot --path . --script res://tools/profile_load.gd -- <lieu> [--images N] [--api=…]
## <lieu> : hub, plaine, desert, marais ou village. Sans --headless (sous Xvfb sur un serveur), les images comptent le
## rendu ; avec, seulement le processeur. Dernière ligne : « PROFIL <lieu> … », facile à relever par un script.

const LEVELS := {
	"hub": "res://scenes/levels/hub/hub.tscn",
	"plaine": "res://scenes/levels/plaine/plaine.tscn",
	"desert": "res://scenes/levels/desert/desert.tscn",
	"marais": "res://scenes/levels/marais/marais.tscn",
	"village": "res://scenes/levels/village/village.tscn",
}
## Nombre de _ready affichés, des plus chers aux moins chers.
const TOP := 25

## [instant en µs, chemin du nœud] à chaque fin de _ready, dans l'ordre.
var _marks: Array = []
var _level: Node


func _initialize() -> void:
	_run.call_deferred()


func _mark(node: Node) -> void:
	_marks.append([Time.get_ticks_usec(), str(_level.get_path_to(node)) if _level else str(node.name)])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var place := args[0] if not args.is_empty() else "village"
	var frames := 90
	var index := args.find("--images")
	if index >= 0 and index + 1 < args.size():
		frames = int(args[index + 1])
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	for frame in 5:
		await process_frame

	var start := Time.get_ticks_usec()
	var packed := ResourceLoader.load(LEVELS[place]) as PackedScene
	var loaded := Time.get_ticks_usec()
	_level = packed.instantiate()
	var instanced := Time.get_ticks_usec()
	var nodes: Array[Node] = [_level]
	nodes.append_array(_level.find_children("*", "", true, false))
	for node in nodes:
		node.ready.connect(_mark.bind(node), CONNECT_ONE_SHOT)
	var entered := [0]
	_level.tree_entered.connect(func() -> void: entered[0] = Time.get_ticks_usec())
	var before_add := Time.get_ticks_usec()
	root.add_child(_level)
	current_scene = _level
	var added := Time.get_ticks_usec()

	# Coût de chaque _ready : l'écart avec la fin du _ready précédent (les enfants sont prêts avant leur parent).
	var costs: Array = []
	var previous := before_add
	for mark: Array in _marks:
		costs.append([mark[0] - previous, mark[1]])
		previous = mark[0]
	costs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	print("Lieu : %s (%d nœuds dans la scène)" % [place, nodes.size()])
	print("  lecture de la ressource : %.0f ms" % ((loaded - start) / 1000.0))
	print("  instanciation : %.0f ms" % ((instanced - loaded) / 1000.0))
	print("  entrée dans l'arbre et _ready : %.0f ms" % ((added - before_add) / 1000.0))
	print("  _ready les plus chers :")
	for cost: Array in costs.slice(0, TOP):
		print("    %7.1f ms  %s" % [cost[0] / 1000.0, cost[1]])

	var times := PackedFloat64Array()
	var last := Time.get_ticks_usec()
	for frame in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	var steady := Array(times.slice(times.size() / 2))
	steady.sort()
	var median: float = steady[steady.size() / 2]
	var excess := 0.0
	var settle := times.size()
	for frame in times.size():
		if times[frame] > median * 1.5 + 5.0:
			settle = frame + 1
	for frame in settle:
		excess += maxf(times[frame] - median, 0.0)
	var first := []
	for frame in mini(12, times.size()):
		first.append("%.0f" % times[frame])
	print("  premières images (ms) : %s" % ", ".join(first))
	print("  image stable (médiane de la seconde moitié) : %.1f ms ; rythme stable après %d images ; surcoût des premières images : %.0f ms" % [median, settle, excess])
	print("PROFIL %s ressource=%.0f instance=%.0f ready=%.0f images=%.0f total=%.0f" % [place,
		(loaded - start) / 1000.0, (instanced - loaded) / 1000.0, (added - before_add) / 1000.0, excess,
		(added - start) / 1000.0 + excess])
	state.reset()
	quit()
