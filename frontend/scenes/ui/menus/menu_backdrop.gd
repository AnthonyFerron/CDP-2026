class_name MenuBackdrop
extends Control
## Fond des menus, d'après les maquettes : nuit violette, ciel à facettes, lune, Mont Sam Altan au loin, collines,
## sapins et château sur la colline de droite. Il vit doucement, sans distraire de la lecture : les étoiles
## scintillent, la lueur de la lune respire, les fenêtres du château vacillent, la brume dérive entre les collines, le
## volcan rougeoie et fume, et de temps en temps une chauve-souris sort du château et passe devant la lune.
##
## Tout est en 2D légère, sans shader ni texture. Chaque plan du décor est un nœud, du plus lointain au plus proche,
## dessiné une seule fois. L'animation ne change que la position, l'échelle ou la teinte (modulate) de quelques petits
## nœuds, ce qui ne redessine rien ; seules les étoiles (20 fois par seconde), et la chauve-souris pendant son vol,
## refont leurs quelques formes. Au cran de qualité le plus bas (RenderQuality, cran 6), la brume et le scintillement
## s'arrêtent et la fumée est réduite. Voir docs/accueil-anime.md.

## Crans de qualité (les autoloads ne sont pas encore connus quand ce script est compilé avec un test).
const Quality := preload("res://scripts/render_quality.gd")

const W := 1920.0
const H := 1080.0
const MOON := Vector2(1720, 250)
## Cratère du Mont Sam Altan, au loin à gauche (caché par le cadre des commandes sur l'accueil, visible ailleurs).
const CRATER := Vector2(246, 446)
const WINDOWS: Array[Vector2] = [Vector2(1738, 400), Vector2(1806, 300), Vector2(1806, 380), Vector2(1742, 470)]
## Haut de la tour du château, d'où partent et où rentrent les chauves-souris.
const TOWER := Vector2(1815, 214)
## Collines, du plan le plus lointain au plus proche : couleur et crête. Chaque plan ne descend que jusqu'au point le
## plus bas de la crête du plan suivant, qui le recouvre en dessous : moins de pixels à remplir à chaque image.
const HILLS := [
	[Color(0.26, 0.15, 0.28), [Vector2(0, 640), Vector2(260, 560), Vector2(560, 610), Vector2(900, 540), Vector2(1240, 600), Vector2(1560, 520), Vector2(1920, 600)]],
	[Color(0.2, 0.11, 0.22), [Vector2(0, 760), Vector2(300, 700), Vector2(650, 760), Vector2(1000, 690), Vector2(1400, 760), Vector2(1700, 650), Vector2(1920, 700)]],
	[Color(0.15, 0.08, 0.17), [Vector2(0, 900), Vector2(380, 840), Vector2(760, 900), Vector2(1150, 840), Vector2(1500, 900), Vector2(1920, 830)]],
]
const SKY_TOP := Color(0.2, 0.1, 0.24)
const SKY_BOTTOM := Color(0.14, 0.07, 0.17)

## Étoiles : nombre, et rythme de leur redessin (par seconde) ; leur scintillement est lent.
const STAR_COUNT := 64
const STAR_RATE := 20.0
## Bouffées de fumée du volcan (3 au cran le plus bas), et durée de vie de chacune, en secondes.
const PUFFS := 7
const PUFFS_REDUCED := 4
const PUFF_LIFE := 18.0
const PUFF_RISE := 340.0
## Nappes de brume : plan (0 entre les collines lointaines et moyennes, 1 entre les moyennes et les proches),
## abscisse de départ, hauteur, longueur, épaisseur, vitesse (pixels par seconde, vers la droite) et opacité.
const WISPS := [
	[0, 180.0, 626.0, 560.0, 44.0, 7.0, 0.17],
	[0, 940.0, 606.0, 480.0, 38.0, 5.5, 0.15],
	[0, 1560.0, 640.0, 620.0, 48.0, 8.5, 0.17],
	[1, 420.0, 790.0, 700.0, 56.0, 13.0, 0.14],
	[1, 1320.0, 812.0, 600.0, 50.0, 11.0, 0.13],
	[1, 1980.0, 776.0, 520.0, 46.0, 15.0, 0.12],
]
const MIST := Color(0.6, 0.47, 0.68)
## Chauve-souris : premier passage, puis délai entre deux passages, et durée d'un vol, en secondes.
const BAT_FIRST := 4.0
const BAT_GAP := Vector2(18.0, 34.0)
const BAT_TIME := Vector2(8.5, 12.0)

## Cran le plus bas : moins d'animation.
var reduced := false
## Temps écoulé, en secondes, à la vitesse du jeu (les captures à --fixed-fps sont reproductibles).
var elapsed := 0.0

var _star_clock := 0.0
var _stars: Stars
var _halo: Node2D
var _crater: Node2D
var _windows: Array[Node2D] = []
var _puffs: Array[Node2D] = []
var _wisps: Array[Node2D] = []
var _bat: Bat
var _bat_wait := BAT_FIRST
var _bat_from := Vector2.ZERO
var _bat_via := Vector2.ZERO
var _bat_to := Vector2.ZERO
var _bat_time := 0.0
var _bat_duration := 1.0
var _bat_out := true
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Le décor vit aussi pendant le fondu au noir d'une transition, qui met le jeu en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 1305
	_build()
	var quality := get_node_or_null(^"/root/RenderQuality")
	if quality:
		set_reduced(int(quality.get(&"tier")) >= Quality.TIER_LESS_DETAIL)
		quality.connect(&"tier_changed", _on_tier_changed)


func _on_tier_changed(tier: int) -> void:
	set_reduced(tier >= Quality.TIER_LESS_DETAIL)


## Animation réduite (cran le plus bas) : ni brume ni scintillement, moins de fumée.
func set_reduced(value: bool) -> void:
	reduced = value
	for wisp in _wisps:
		wisp.visible = not value
	_stars.twinkle = not value
	_stars.queue_redraw()


## Ciel : dégradé et facettes claires, à la manière d'un ciel low-poly. Il ne descend que jusqu'à la crête la plus
## basse des collines lointaines, avec la couleur du dégradé à cette hauteur.
func _draw() -> void:
	var low := HILLS[0][1].reduce(func(deepest: float, point: Vector2) -> float: return maxf(deepest, point.y), 0.0) as float
	var bottom := SKY_TOP.lerp(SKY_BOTTOM, low / H)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, low), Vector2(0, low)]),
		PackedColorArray([SKY_TOP, SKY_TOP, bottom, bottom]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5814
	for i in 26:
		var c := Vector2(rng.randf_range(0, W), rng.randf_range(0, H * 0.8))
		var r := rng.randf_range(60, 170)
		var tri := PackedVector2Array([c + Vector2(-r, r * 0.4), c + Vector2(r * rng.randf_range(0.3, 1.0), -r * 0.5), c + Vector2(r, r * 0.6)])
		draw_colored_polygon(tri, Color(0.32, 0.18, 0.36, rng.randf_range(0.18, 0.4)))


# --- Construction des plans ---------------------------------------------------------------------------------

func _layer(paint: Callable, at := Vector2.ZERO) -> Node2D:
	var layer := Layer.new()
	layer.paint = paint
	layer.position = at
	add_child(layer)
	return layer


func _build() -> void:
	_stars = Stars.new()
	_stars.name = "Etoiles"
	_stars.scatter(STAR_COUNT, _rng)
	add_child(_stars)
	_layer(_paint_volcano).name = "Volcan"
	_crater = _layer(_paint_crater_glow, CRATER)
	_crater.name = "LueurDuCratere"
	for index in PUFFS:
		var puff := _layer(_paint_puff.bind(index), CRATER)
		puff.name = "Fumee%d" % (index + 1)
		puff.modulate.a = 0.0
		_puffs.append(puff)
	_halo = _layer(_paint_halo, MOON)
	_halo.name = "HaloDeLaLune"
	_layer(_paint_moon, MOON).name = "Lune"
	_bat = Bat.new()
	_bat.name = "ChauveSouris"
	_bat.visible = false
	_bat.scale = Vector2(1.35, 1.35)
	add_child(_bat)
	_layer(_paint_castle).name = "Chateau"
	for spot in WINDOWS:
		var window := _layer(_paint_window, spot)
		window.name = "Fenetre%d" % (_windows.size() + 1)
		_windows.append(window)
	for plane in HILLS.size():
		_layer(_paint_hills.bind(plane)).name = "Collines%d" % (plane + 1)
		for item: Array in WISPS:
			if int(item[0]) == plane:
				var wisp := _layer(_paint_wisp.bind(item[3], item[4], item[6], _wisps.size()), Vector2(item[1], item[2]))
				wisp.name = "Brume%d" % (_wisps.size() + 1)
				wisp.set_meta(&"wisp", item)
				_wisps.append(wisp)
	_layer(_paint_pines).name = "Sapins"


func _paint_volcano(item: CanvasItem) -> void:
	# Cône un peu dissymétrique, plus chaud vers le cratère, qui plonge derrière les collines lointaines.
	var points := PackedVector2Array([Vector2(-90, 660), Vector2(30, 566), Vector2(120, 504), Vector2(190, 458),
		Vector2(212, 448), Vector2(230, 457), Vector2(262, 459), Vector2(282, 446), Vector2(304, 455),
		Vector2(372, 500), Vector2(470, 566), Vector2(610, 660)])
	var colors := PackedColorArray()
	for point in points:
		var heat := clampf((520.0 - point.y) / 80.0, 0.0, 1.0)
		colors.append(Color(0.27, 0.15, 0.29).lerp(Color(0.36, 0.17, 0.27), heat))
	item.draw_polygon(points, colors)
	# Coulée qui rougeoie sur le flanc droit, et s'éteint en descendant.
	var lava := PackedVector2Array([Vector2(262, 459), Vector2(272, 456), Vector2(300, 500), Vector2(318, 548), Vector2(306, 548), Vector2(286, 502)])
	var glow := Color(1.0, 0.45, 0.15, 0.45)
	item.draw_polygon(lava, PackedColorArray([glow, glow, Color(glow, 0.3), Color(glow, 0.0), Color(glow, 0.0), Color(glow, 0.3)]))


func _paint_crater_glow(item: CanvasItem) -> void:
	for ring in range(6, 0, -1):
		item.draw_circle(Vector2(0, 4), 10.0 + ring * 11.0, Color(1.0, 0.42, 0.12, 0.032))
	# Lave au fond du cratère, entre ses deux lèvres.
	item.draw_colored_polygon(PackedVector2Array([Vector2(-30, 5), Vector2(-16, 2), Vector2(14, 3), Vector2(32, 5), Vector2(14, 10), Vector2(-14, 10)]),
		Color(1.0, 0.55, 0.2, 0.5))


## Bouffée de fumée, dessinée petite (rayon 26) : sa taille, sa place et son opacité changent par le nœud. Un voile
## plus large et plus clair l'entoure : les bouffées se fondent en un panache.
func _paint_puff(item: CanvasItem, index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + index
	var radii := PackedFloat32Array()
	for corner in 9:
		radii.append(rng.randf_range(0.8, 1.15))
	for layer: Array in [[38.0, 0.16], [25.0, 0.22]]:
		var points := PackedVector2Array()
		for corner in 9:
			var angle := TAU * corner / 9.0
			points.append(Vector2(cos(angle), sin(angle) * 0.8) * float(layer[0]) * radii[corner])
		item.draw_colored_polygon(points, Color(0.43, 0.31, 0.43, layer[1]))


func _paint_halo(item: CanvasItem) -> void:
	for ring in range(6, 0, -1):
		item.draw_circle(Vector2.ZERO, 92 + ring * 22, Color(0.98, 0.75, 0.35, 0.029))


func _paint_moon(item: CanvasItem) -> void:
	item.draw_circle(Vector2.ZERO, 94, Color(0.98, 0.76, 0.38))
	item.draw_circle(Vector2(-26, -22), 66, Color(1.0, 0.82, 0.48, 0.5))


func _paint_castle(item: CanvasItem) -> void:
	var castle := Color(0.1, 0.05, 0.1)
	item.draw_rect(Rect2(1700, 330, 130, 330), castle)
	item.draw_rect(Rect2(1780, 250, 70, 410), castle)
	for x in [1700, 1726, 1752, 1780, 1806, 1832]:
		item.draw_rect(Rect2(x, 316 if x < 1780 else 236, 16, 16), castle)
	item.draw_colored_polygon(PackedVector2Array([Vector2(1776, 250), Vector2(1815, 196), Vector2(1854, 250)]), castle)


## Fenêtre allumée et son halo : la flamme vacille par la teinte du nœud.
func _paint_window(item: CanvasItem) -> void:
	item.draw_rect(Rect2(-5, -5, 24, 32), Color(1.0, 0.6, 0.25, 0.14))
	item.draw_rect(Rect2(Vector2.ZERO, Vector2(14, 22)), Color(1.0, 0.74, 0.32))


func _paint_hills(item: CanvasItem, plane: int) -> void:
	var points := PackedVector2Array(HILLS[plane][1])
	var floor_y := H
	if plane + 1 < HILLS.size():
		floor_y = HILLS[plane + 1][1].reduce(func(deepest: float, point: Vector2) -> float: return maxf(deepest, point.y), 0.0) + 2.0
	points.append(Vector2(W, floor_y))
	points.append(Vector2(0, floor_y))
	item.draw_colored_polygon(points, HILLS[plane][0])


## Nappe de brume : une bande allongée, opaque au milieu et transparente sur ses bords, en un seul tracé.
func _paint_wisp(item: CanvasItem, length: float, thickness: float, alpha: float, index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 301 + index
	var segments := 12
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for step in segments + 1:
		var t := float(step) / segments
		var envelope := sin(PI * t)
		var x := (t - 0.5) * length
		var spine := rng.randf_range(-3.0, 3.0) * envelope
		points.append(Vector2(x, spine - thickness * envelope * rng.randf_range(0.8, 1.1)))
		points.append(Vector2(x, spine))
		points.append(Vector2(x, spine + thickness * 0.45 * envelope))
		colors.append(Color(MIST, 0.0))
		colors.append(Color(MIST, alpha * pow(envelope, 0.6)))
		colors.append(Color(MIST, 0.0))
	var indices := PackedInt32Array()
	for step in segments:
		var a := step * 3
		var b := a + 3
		indices.append_array([a, b, a + 1, b, b + 1, a + 1, a + 1, b + 1, a + 2, b + 1, b + 2, a + 2])
	RenderingServer.canvas_item_add_triangle_array(item.get_canvas_item(), indices, points, colors)


func _paint_pines(item: CanvasItem) -> void:
	for tree: Vector2 in [Vector2(40, 780), Vector2(110, 820), Vector2(1580, 760), Vector2(1660, 720), Vector2(1880, 760), Vector2(1790, 820)]:
		var height := 210.0 if tree.x > 1500 else 180.0
		var color := Color(0.09, 0.05, 0.1)
		for tier in 3:
			var y := tree.y - height * (0.25 + tier * 0.25)
			var half := height * (0.32 - tier * 0.07)
			item.draw_colored_polygon(PackedVector2Array([Vector2(tree.x - half, y + height * 0.32), Vector2(tree.x, y - height * 0.18),
				Vector2(tree.x + half, y + height * 0.32)]), color)
		item.draw_rect(Rect2(tree.x - 8, tree.y - height * 0.12, 16, height * 0.14), color)


# --- Animation ----------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	elapsed += delta
	var t := elapsed
	if not reduced:
		_star_clock += delta
		if _star_clock >= 1.0 / STAR_RATE:
			_star_clock = fmod(_star_clock, 1.0 / STAR_RATE)
			_stars.time = t
			_stars.queue_redraw()
	# La lueur de la lune respire, sur huit secondes.
	var breath := sin(t * TAU / 8.0)
	_halo.modulate.a = 0.86 + 0.14 * breath
	_halo.scale = Vector2.ONE * (1.0 + 0.03 * breath)
	# Flammes des chandelles derrière les fenêtres : plusieurs ondes sans rapport, chacune à sa phase.
	for index in _windows.size():
		var phase := index * 1.7
		var flame := 0.87 + 0.07 * sin(t * 5.3 + phase) + 0.04 * sin(t * 11.9 + phase * 2.3) + 0.02 * sin(t * 23.7 + phase * 3.1)
		_windows[index].modulate = Color(flame, flame, flame)
	# Le volcan gronde : sa lueur monte et retombe, la fumée s'élève et s'étire vers la droite.
	_crater.modulate.a = 0.62 + 0.24 * sin(t * 0.9) + 0.14 * sin(t * 2.3 + 1.0)
	var count := PUFFS_REDUCED if reduced else PUFFS
	for index in _puffs.size():
		var puff := _puffs[index]
		puff.visible = index < count
		if not puff.visible:
			continue
		var life := fposmod(t / PUFF_LIFE + float(index) / count, 1.0)
		# Le vent couche le panache vers la droite à mesure qu'il monte.
		puff.position = CRATER + Vector2(90.0 * pow(life, 1.4) + 8.0 * sin(life * 5.0 + index * 1.3), -6.0 - PUFF_RISE * life)
		puff.scale = Vector2.ONE * (0.7 + 1.6 * life)
		puff.rotation = 0.6 * life + index
		var ember := pow(1.0 - life, 5.0)
		puff.modulate = Color(1.0 + 0.7 * ember, 1.0 + 0.15 * ember, 1.0 - 0.15 * ember,
			smoothstep(0.0, 0.15, life) * pow(1.0 - life, 1.5))
	if not reduced:
		for wisp in _wisps:
			var item: Array = wisp.get_meta(&"wisp")
			var length: float = item[3]
			var span := W + length + 80.0
			wisp.position = Vector2(fposmod(float(item[1]) + float(item[5]) * t + length / 2.0 + 40.0, span) - length / 2.0 - 40.0,
				float(item[2]) + 4.0 * sin(t * 0.25 + float(item[1])))
			wisp.modulate.a = 0.8 + 0.2 * sin(t * 0.17 + float(item[2]))
	_fly(delta)


## Chauve-souris : de temps en temps, elle sort de la tour du château, passe devant la lune et file vers la gauche,
## ou revient de la gauche et rentre derrière la tour.
func _fly(delta: float) -> void:
	if not _bat.visible:
		_bat_wait -= delta
		if _bat_wait > 0.0:
			return
		_bat_out = not _bat_out if _bat_time > 0.0 else true
		var far := Vector2(-60.0, _rng.randf_range(90.0, 260.0))
		# Caché derrière la tour, ailes comprises.
		var home := TOWER + Vector2(0, 40)
		_bat_from = home if _bat_out else far
		_bat_to = far if _bat_out else home
		_bat_via = Vector2(_rng.randf_range(1100.0, 1500.0), _rng.randf_range(60.0, 200.0))
		_bat_duration = _rng.randf_range(BAT_TIME.x, BAT_TIME.y)
		_bat_time = 0.0
		_bat.position = _bat_from
		_bat.visible = true
	_bat_time += delta
	var u := clampf(_bat_time / _bat_duration, 0.0, 1.0)
	# Un peu plus lente au départ et à l'arrivée, près de la tour.
	var eased := lerpf(u, u * u * (3.0 - 2.0 * u), 0.4)
	var a := _bat_from.lerp(_bat_via, eased)
	var b := _bat_via.lerp(_bat_to, eased)
	_bat.position = a.lerp(b, eased) + Vector2(0, 7.0 * sin(_bat_time * 4.1))
	_bat.flap = sin(_bat_time * TAU * 5.5)
	_bat.queue_redraw()
	if u >= 1.0:
		_bat.visible = false
		_bat_wait = _rng.randf_range(BAT_GAP.x, BAT_GAP.y)


# --- Nœuds du décor -----------------------------------------------------------------------------------------

class Layer:
	extends Node2D
	## Un plan du décor, dessiné une fois par `paint` (qui reçoit le nœud).

	var paint: Callable

	func _draw() -> void:
		paint.call(self)


class Stars:
	extends Node2D
	## Étoiles du ciel, petits losanges ; les plus grosses sont des étincelles à quatre branches. Chacune scintille à
	## son rythme : son éclat suit une onde lente, avec sa vitesse et sa phase.

	var time := 0.0
	var twinkle := true
	var _points := PackedVector2Array()
	var _sizes := PackedFloat32Array()
	var _bright := PackedFloat32Array()
	var _speeds := PackedFloat32Array()
	var _phases := PackedFloat32Array()
	var _tints := PackedColorArray()

	## Sème les étoiles dans le ciel, plus nombreuses en haut, loin de la lune, du château et du volcan.
	func scatter(count: int, rng: RandomNumberGenerator) -> void:
		while _points.size() < count:
			var point := Vector2(rng.randf_range(8.0, 1912.0), 520.0 * pow(rng.randf(), 1.35) + 8.0)
			if point.distance_to(MenuBackdrop.MOON) < 250.0:
				continue
			if point.x > 1680.0 and point.y > 180.0:
				continue
			if point.x < 520.0 and point.y > 420.0:
				continue
			var spark := rng.randf() < 0.14
			_points.append(point)
			_sizes.append(rng.randf_range(5.0, 8.0) if spark else rng.randf_range(1.8, 3.0))
			_bright.append(rng.randf_range(0.6, 0.95) if spark else rng.randf_range(0.35, 0.9))
			_speeds.append(rng.randf_range(0.5, 1.7))
			_phases.append(rng.randf_range(0.0, TAU))
			_tints.append(Color(1.0, 0.93, 0.82) if rng.randf() < 0.6 else Color(0.86, 0.86, 1.0))

	func _draw() -> void:
		var none := PackedVector2Array()
		for index in _points.size():
			var p := _points[index]
			var r := _sizes[index]
			var glow := 0.7
			if twinkle:
				glow = 0.5 + 0.5 * (0.5 + 0.5 * sin(time * _speeds[index] + _phases[index]))
			var color := Color(_tints[index], _bright[index] * glow)
			if r < 3.0:
				draw_primitive(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]),
					PackedColorArray([color]), none)
				continue
			# Étincelle : deux losanges fins en croix, plus longs quand elle brille, et un cœur plus vif.
			var arm := r * (0.75 + 0.4 * glow)
			var width := r * 0.2
			draw_primitive(PackedVector2Array([p + Vector2(0, -arm), p + Vector2(width, 0), p + Vector2(0, arm), p + Vector2(-width, 0)]),
				PackedColorArray([color]), none)
			draw_primitive(PackedVector2Array([p + Vector2(-arm, 0), p + Vector2(0, -width), p + Vector2(arm, 0), p + Vector2(0, width)]),
				PackedColorArray([color]), none)
			var core := r * 0.3
			draw_primitive(PackedVector2Array([p + Vector2(0, -core), p + Vector2(core, 0), p + Vector2(0, core), p + Vector2(-core, 0)]),
				PackedColorArray([Color(color, minf(1.0, color.a * 1.4))]), none)


class Bat:
	extends Node2D
	## Chauve-souris en silhouette : un corps, deux oreilles et deux ailes festonnées qui battent (`flap`, de -1 à 1).
	## Chaque forme est faite de triangles, sans découpage de polygone.

	var flap := 0.0

	func _draw() -> void:
		var color := Color(0.07, 0.03, 0.08)
		var colors := PackedColorArray([color])
		var none := PackedVector2Array()
		var lift := flap * 9.0
		for side in [-1.0, 1.0]:
			var shoulder := Vector2(side * 2.5, 0.0)
			var edge := [Vector2(side * 4, -3), Vector2(side * 10, -5 - lift * 0.6), Vector2(side * 19, -3 - lift),
				Vector2(side * 15, 2 - lift * 0.5), Vector2(side * 12, -lift * 0.3), Vector2(side * 8, 4 - lift * 0.2), Vector2(side * 3, 3)]
			for index in edge.size() - 1:
				draw_primitive(PackedVector2Array([shoulder, edge[index], edge[index + 1]]), colors, none)
		draw_primitive(PackedVector2Array([Vector2(0, -6), Vector2(3.5, -1), Vector2(0, 7), Vector2(-3.5, -1)]), colors, none)
		for side in [-1.0, 1.0]:
			draw_primitive(PackedVector2Array([Vector2(side * 3, -4), Vector2(side * 2.5, -9), Vector2(side * 0.5, -5)]), colors, none)
