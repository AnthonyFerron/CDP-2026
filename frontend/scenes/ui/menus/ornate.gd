class_name Ornate
## Habillage des menus de CodeQuest, d'après les maquettes : nuit violette, cadres sombres à bordure dorée et coins
## coupés, boutons hexagonaux, touches du clavier, champs de saisie et icônes. Tout est dessiné, à la résolution de
## référence 1920 × 1080 : aucun symbole ne dépend d'une police, la version web n'en ayant pas d'autre que les nôtres.
## Titres et boutons en Cinzel Bold, textes en Lora, comme dans tout le jeu.

const GOLD := Color(0.96, 0.65, 0.2)
const GOLD_LIGHT := Color(1.0, 0.85, 0.48)
const GOLD_DARK := Color(0.58, 0.35, 0.11)
const PANEL := Color(0.14, 0.08, 0.07, 0.97)
const PANEL_LIGHT := Color(0.27, 0.15, 0.08)
const CREAM := Color(0.98, 0.92, 0.8)
const MUTED := Color(0.72, 0.64, 0.55)
const INK := Color(0.1, 0.05, 0.04)
const ERROR := Color(1.0, 0.58, 0.45)
const SUCCESS := Color(0.62, 0.92, 0.6)
const SILVER := Color(0.78, 0.79, 0.82)
const BRONZE := Color(0.86, 0.5, 0.22)
const SERIF: Font = preload("res://ui/cinzel_bold.tres")
const TEXT: Font = preload("res://assets/fonts/Lora.ttf")
const PORTRAIT: Texture2D = preload("res://assets/ui/devlyn_portrait.png")
const STUDIO: Texture2D = preload("res://assets/ui/ruminate_studio.png")
## Touches rappelées dans les panneaux de commandes.
const KEYS := [["Z", "Avancer"], ["Q", "Aller à gauche"], ["S", "Reculer"], ["D", "Aller à droite"], ["E", "Interagir / Action"]]
const WIDE_KEYS := [["Espace", "Sauter"], ["Shift", "Courir"]]
## Raccourcis du jeu, rappelés en pied d'écran.
const SHORTCUTS := "Échap : pause     H : indice     F : plein écran"


## Texte prêt à placer : Cinzel pour les titres, Lora pour le reste.
static func label(text: String, size: int, color := CREAM, serif := false, outline := 0) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", SERIF if serif else TEXT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if outline > 0:
		node.add_theme_constant_override("outline_size", outline)
		node.add_theme_color_override("font_outline_color", INK)
	return node


## Place un nœud dans son parent, en coordonnées de référence.
static func place(parent: Node, node: Control, position: Vector2, size: Vector2) -> Control:
	node.position = position
	node.size = size
	parent.add_child(node)
	return node


## Écrit un texte centré sur un point, en tenant compte de la hauteur de la police.
static func centered_text(item: CanvasItem, font: Font, center: Vector2, text: String, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := center.y + (font.get_ascent(size) - font.get_descent(size)) / 2.0
	item.draw_string(font, Vector2(center.x - width / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Losange doré, ornement des cadres et des boutons.
static func diamond(item: CanvasItem, center: Vector2, radius: float, fill := GOLD) -> void:
	var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
	item.draw_colored_polygon(points, GOLD_DARK)
	var inner := PackedVector2Array()
	for point in points:
		inner.append(center + (point - center) * 0.62)
	item.draw_colored_polygon(inner, fill)
	item.draw_polyline(closed(points), GOLD_LIGHT, 2.0)


## Contour à coins coupés d'un rectangle, dans le sens des aiguilles d'une montre.
static func chamfered(rect: Rect2, cut: float) -> PackedVector2Array:
	var a := rect.position
	var b := rect.end
	return PackedVector2Array([
		Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut), Vector2(b.x, b.y - cut),
		Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y), Vector2(a.x, b.y - cut), Vector2(a.x, a.y + cut)])


## Hexagone allongé, pointu à gauche et à droite : la forme des boutons et des plaques de titre.
static func hexagon(rect: Rect2, point: float) -> PackedVector2Array:
	var a := rect.position
	var b := rect.end
	var mid := a.y + rect.size.y / 2.0
	return PackedVector2Array([Vector2(a.x + point, a.y), Vector2(b.x - point, a.y), Vector2(b.x, mid),
		Vector2(b.x - point, b.y), Vector2(a.x + point, b.y), Vector2(a.x, mid)])


static func closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result


## Ligne dorée qui s'efface vers ses bouts, avec un losange au milieu.
static func divider(item: CanvasItem, from: Vector2, to: Vector2, with_diamond := true) -> void:
	var middle := (from + to) / 2.0
	item.draw_polygon(PackedVector2Array([from, middle + Vector2(0, -2), to, middle + Vector2(0, 2)]),
		PackedColorArray([Color(GOLD, 0.0), GOLD, Color(GOLD, 0.0), GOLD]))
	if with_diamond:
		diamond(item, middle, 11)


## Plaque de titre hexagonale, centrée sur un point.
static func plaque(item: CanvasItem, center: Vector2, text: String, size: int) -> Rect2:
	var width := SERIF.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 2.6
	var height := size * 1.9
	var rect := Rect2(center - Vector2(width, height) / 2.0, Vector2(width, height))
	var shape := hexagon(rect, height * 0.42)
	var top := Color(0.38, 0.22, 0.1)
	var low := Color(0.22, 0.12, 0.07)
	item.draw_polygon(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
	item.draw_polyline(closed(shape), GOLD, 5.0)
	var inset := PackedVector2Array()
	for point in shape:
		inset.append(center + (point - center) * Vector2(0.97, 0.8))
	item.draw_polyline(closed(inset), GOLD_DARK, 2.0)
	centered_text(item, SERIF, center, text, size, CREAM)
	diamond(item, Vector2(center.x, rect.end.y), 11)
	return rect


## Icônes au trait, dessinées dans un carré de demi-côté s autour du centre.
static func icon(item: CanvasItem, kind: String, c: Vector2, s: float, color := CREAM, w := 3.0) -> void:
	match kind:
		"user":
			item.draw_arc(c + Vector2(0, -0.4 * s), 0.34 * s, 0.0, TAU, 28, color, w)
			item.draw_arc(c + Vector2(0, 0.95 * s), 0.78 * s, PI, TAU, 28, color, w)
			item.draw_line(c + Vector2(-0.78 * s, 0.95 * s), c + Vector2(0.78 * s, 0.95 * s), color, w)
		"user_add":
			icon(item, "user", c + Vector2(-0.22 * s, 0.0), 0.85 * s, color, w)
			item.draw_line(c + Vector2(0.72 * s, 0.05 * s), c + Vector2(0.72 * s, 0.65 * s), color, w)
			item.draw_line(c + Vector2(0.42 * s, 0.35 * s), c + Vector2(1.02 * s, 0.35 * s), color, w)
		"mail":
			item.draw_rect(Rect2(c - Vector2(s, 0.7 * s), Vector2(2.0 * s, 1.4 * s)), color, false, w)
			item.draw_polyline(PackedVector2Array([c + Vector2(-s, -0.7 * s), c + Vector2(0, 0.12 * s), c + Vector2(s, -0.7 * s)]), color, w)
		"lock":
			item.draw_arc(c + Vector2(0, -0.12 * s), 0.42 * s, PI, TAU, 18, color, w * 1.2)
			item.draw_line(c + Vector2(-0.42 * s, -0.12 * s), c + Vector2(-0.42 * s, 0.0), color, w * 1.2)
			item.draw_line(c + Vector2(0.42 * s, -0.12 * s), c + Vector2(0.42 * s, 0.0), color, w * 1.2)
			item.draw_rect(Rect2(c + Vector2(-0.64 * s, -0.04 * s), Vector2(1.28 * s, 1.0 * s)), color)
			item.draw_circle(c + Vector2(0, 0.36 * s), 0.13 * s, INK)
			item.draw_rect(Rect2(c + Vector2(-0.05 * s, 0.36 * s), Vector2(0.1 * s, 0.32 * s)), INK)
		"eye", "eye_off":
			var top := PackedVector2Array()
			var bottom := PackedVector2Array()
			for step in 17:
				var t := step / 16.0
				var x := -s + 2.0 * s * t
				top.append(c + Vector2(x, -0.58 * s * sin(PI * t)))
				bottom.append(c + Vector2(x, 0.58 * s * sin(PI * t)))
			item.draw_polyline(top, color, w)
			item.draw_polyline(bottom, color, w)
			item.draw_circle(c, 0.27 * s, color)
			if kind == "eye_off":
				item.draw_line(c + Vector2(-0.85 * s, 0.85 * s), c + Vector2(0.85 * s, -0.85 * s), color, w * 1.2)
		"login":
			item.draw_polyline(PackedVector2Array([c + Vector2(0.15 * s, -0.9 * s), c + Vector2(0.9 * s, -0.9 * s),
				c + Vector2(0.9 * s, 0.9 * s), c + Vector2(0.15 * s, 0.9 * s)]), color, w)
			item.draw_line(c + Vector2(-0.95 * s, 0.0), c + Vector2(0.45 * s, 0.0), color, w)
			item.draw_polyline(PackedVector2Array([c + Vector2(0.05 * s, -0.4 * s), c + Vector2(0.45 * s, 0.0), c + Vector2(0.05 * s, 0.4 * s)]), color, w)
		"logout":
			item.draw_polyline(PackedVector2Array([c + Vector2(-0.15 * s, -0.9 * s), c + Vector2(-0.9 * s, -0.9 * s),
				c + Vector2(-0.9 * s, 0.9 * s), c + Vector2(-0.15 * s, 0.9 * s)]), color, w)
			item.draw_line(c + Vector2(-0.45 * s, 0.0), c + Vector2(0.95 * s, 0.0), color, w)
			item.draw_polyline(PackedVector2Array([c + Vector2(0.55 * s, -0.4 * s), c + Vector2(0.95 * s, 0.0), c + Vector2(0.55 * s, 0.4 * s)]), color, w)
		"check":
			item.draw_polyline(PackedVector2Array([c + Vector2(-0.78 * s, 0.0), c + Vector2(-0.22 * s, 0.56 * s), c + Vector2(0.82 * s, -0.62 * s)]), color, w * 1.5)
		"arrow_left":
			item.draw_line(c + Vector2(0.9 * s, 0.0), c + Vector2(-0.82 * s, 0.0), color, w * 1.2)
			item.draw_polyline(PackedVector2Array([c + Vector2(-0.3 * s, -0.5 * s), c + Vector2(-0.88 * s, 0.0), c + Vector2(-0.3 * s, 0.5 * s)]), color, w * 1.2)
		"close":
			item.draw_line(c + Vector2(-0.6 * s, -0.6 * s), c + Vector2(0.6 * s, 0.6 * s), color, w * 1.5)
			item.draw_line(c + Vector2(0.6 * s, -0.6 * s), c + Vector2(-0.6 * s, 0.6 * s), color, w * 1.5)
		"bulb":
			item.draw_arc(c + Vector2(0, -0.1 * s), 0.46 * s, deg_to_rad(125.0), deg_to_rad(415.0), 28, color, w * 1.3)
			item.draw_line(c + Vector2(-0.26 * s, 0.28 * s), c + Vector2(-0.22 * s, 0.56 * s), color, w * 1.3)
			item.draw_line(c + Vector2(0.26 * s, 0.28 * s), c + Vector2(0.22 * s, 0.56 * s), color, w * 1.3)
			item.draw_line(c + Vector2(-0.24 * s, 0.56 * s), c + Vector2(0.24 * s, 0.56 * s), color, w * 1.3)
			item.draw_line(c + Vector2(-0.16 * s, 0.72 * s), c + Vector2(0.16 * s, 0.72 * s), color, w * 1.3)
			for ray in 5:
				var angle := deg_to_rad(-160.0 + ray * 35.0)
				var direction := Vector2(cos(angle), sin(angle))
				item.draw_line(c + Vector2(0, -0.1 * s) + direction * 0.66 * s, c + Vector2(0, -0.1 * s) + direction * 0.92 * s, color, w * 1.3)
		"book":
			_book(item, c + Vector2(0, 0.35 * s), s, color)
		"question_book":
			_book(item, c + Vector2(0, 0.45 * s), s, color)
			centered_text(item, SERIF, c + Vector2(0, -0.32 * s), "?", int(s * 1.1), color)
			for ray in 4:
				var angle := deg_to_rad([-150.0, -120.0, -60.0, -30.0][ray])
				var direction := Vector2(cos(angle), sin(angle))
				item.draw_line(c + Vector2(0, -0.32 * s) + direction * 0.55 * s, c + Vector2(0, -0.32 * s) + direction * 0.78 * s, color, w)
		"stopwatch":
			item.draw_arc(c + Vector2(0, 0.12 * s), 0.72 * s, 0.0, TAU, 32, color, w)
			item.draw_rect(Rect2(c + Vector2(-0.16 * s, -0.95 * s), Vector2(0.32 * s, 0.2 * s)), color)
			item.draw_line(c + Vector2(0, -0.75 * s), c + Vector2(0, -0.6 * s), color, w)
			item.draw_line(c + Vector2(0, 0.12 * s), c + Vector2(0.3 * s, -0.22 * s), color, w)
		"shield_lock":
			var shield := PackedVector2Array([c + Vector2(0, -s), c + Vector2(0.82 * s, -0.66 * s), c + Vector2(0.76 * s, 0.2 * s),
				c + Vector2(0, s), c + Vector2(-0.76 * s, 0.2 * s), c + Vector2(-0.82 * s, -0.66 * s)])
			item.draw_colored_polygon(shield, PANEL_LIGHT)
			item.draw_polyline(closed(shield), color, w * 1.4)
			icon(item, "lock", c + Vector2(0, -0.02 * s), 0.46 * s, color, w)
		"laurel_left", "laurel_right":
			# Branche courbe qui monte du bas vers le haut, des feuilles de part et d'autre.
			var side := -1.0 if kind == "laurel_left" else 1.0
			var pivot := c + Vector2(-side * 0.45 * s, 0.0)
			var branch := PackedVector2Array()
			for step in 13:
				var angle := deg_to_rad(100.0 + step * 12.5)
				branch.append(pivot + Vector2(side * -cos(angle), sin(angle)) * 0.9 * s)
			item.draw_polyline(branch, color, w)
			for leaf in range(1, 12, 2):
				var base := branch[leaf]
				var along := (branch[leaf + 1] - branch[leaf - 1]).normalized()
				var outward := Vector2(along.y, -along.x) * -side
				for direction in [along.rotated(-side * 0.6), along.rotated(side * 0.45) + outward * 0.2]:
					var length := 0.34 * s
					var center: Vector2 = base + direction.normalized() * length * 0.5
					var shape := PackedVector2Array()
					for k in 10:
						var theta := TAU * k / 10.0
						var axis: Vector2 = direction.normalized()
						shape.append(center + axis * cos(theta) * length * 0.5 + Vector2(axis.y, -axis.x) * sin(theta) * length * 0.18)
					item.draw_colored_polygon(shape, color)
		"volcano":
			var mountain := PackedVector2Array([c + Vector2(-s, 0.7 * s), c + Vector2(-0.22 * s, -0.42 * s), c + Vector2(0.22 * s, -0.42 * s), c + Vector2(s, 0.7 * s)])
			item.draw_colored_polygon(mountain, Color(0.32, 0.16, 0.12))
			item.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.22 * s, -0.42 * s), c + Vector2(0.22 * s, -0.42 * s),
				c + Vector2(0.05 * s, 0.1 * s), c + Vector2(0.12 * s, 0.7 * s), c + Vector2(-0.06 * s, 0.7 * s), c + Vector2(-0.1 * s, 0.05 * s)]), Color(1.0, 0.45, 0.12))
			for spark in 5:
				var angle := deg_to_rad(-150.0 + spark * 30.0)
				item.draw_circle(c + Vector2(0, -0.5 * s) + Vector2(cos(angle), sin(angle)) * 0.32 * s, 0.06 * s, Color(1.0, 0.62, 0.2))


static func _book(item: CanvasItem, center: Vector2, s: float, color: Color) -> void:
	for side in [-1.0, 1.0]:
		var page := PackedVector2Array([center, center + Vector2(side * 0.12 * s, -0.46 * s), center + Vector2(side * 0.95 * s, -0.4 * s),
			center + Vector2(side * s, 0.12 * s), center + Vector2(side * 0.45 * s, 0.2 * s)])
		item.draw_colored_polygon(page, color)
		item.draw_polyline(closed(page), GOLD_DARK, 2.0)
		for line in 3:
			var y := -0.3 + line * 0.13
			item.draw_line(center + Vector2(side * 0.2 * s, y * s), center + Vector2(side * 0.82 * s, (y + 0.03) * s), GOLD_DARK, 1.5)


## Panneau des commandes : touches dorées et leur action, en deux groupes séparés d'un trait.
static func commands(frame: Control, top: float, step: float, wide_step: float, columns := Vector2(92, 196)) -> float:
	var y := top
	for key in KEYS:
		var cap := KeyCap.new()
		cap.text = key[0]
		place(frame, cap, Vector2(columns.x, y), Vector2(52, 46))
		var name := label(key[1], 28)
		name.position = Vector2(columns.y, y + 2)
		frame.add_child(name)
		y += step
	var line_y := y + 4.0
	y += 30.0
	for key in WIDE_KEYS:
		var cap := KeyCap.new()
		cap.text = key[0]
		place(frame, cap, Vector2(columns.x - 12, y), Vector2(170, 52))
		var name := label(key[1], 28)
		name.position = Vector2(columns.x + 212, y + 5)
		frame.add_child(name)
		y += wide_step
	return line_y


class Backdrop:
	extends Control
	## Nuit violette : ciel à facettes, lune, collines, sapins et château sur la colline de droite.

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := 1920.0
		var h := 1080.0
		var top := Color(0.2, 0.1, 0.24)
		var bottom := Color(0.14, 0.07, 0.17)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([top, top, bottom, bottom]))
		# Facettes claires dans le ciel, à la manière d'un ciel low-poly.
		var rng := RandomNumberGenerator.new()
		rng.seed = 5814
		for i in 26:
			var c := Vector2(rng.randf_range(0, w), rng.randf_range(0, h * 0.8))
			var r := rng.randf_range(60, 170)
			var tri := PackedVector2Array([c + Vector2(-r, r * 0.4), c + Vector2(r * rng.randf_range(0.3, 1.0), -r * 0.5), c + Vector2(r, r * 0.6)])
			draw_colored_polygon(tri, Color(0.32, 0.18, 0.36, rng.randf_range(0.18, 0.4)))
		# Lune et son halo.
		var moon := Vector2(1720, 250)
		for ring in range(6, 0, -1):
			draw_circle(moon, 92 + ring * 22, Color(0.98, 0.75, 0.35, 0.025))
		draw_circle(moon, 94, Color(0.98, 0.76, 0.38))
		draw_circle(moon + Vector2(-26, -22), 66, Color(1.0, 0.82, 0.48, 0.5))
		# Château sur la colline de droite, fenêtres allumées.
		var castle := Color(0.1, 0.05, 0.1)
		draw_rect(Rect2(1700, 330, 130, 330), castle)
		draw_rect(Rect2(1780, 250, 70, 410), castle)
		for x in [1700, 1726, 1752, 1780, 1806, 1832]:
			draw_rect(Rect2(x, 316 if x < 1780 else 236, 16, 16), castle)
		draw_colored_polygon(PackedVector2Array([Vector2(1776, 250), Vector2(1815, 196), Vector2(1854, 250)]), castle)
		for spot in [Vector2(1738, 400), Vector2(1806, 300), Vector2(1806, 380), Vector2(1742, 470)]:
			draw_rect(Rect2(spot, Vector2(14, 22)), Color(1.0, 0.74, 0.32))
		# Collines en plusieurs plans, du plus clair au plus sombre.
		var layers := [
			[Color(0.26, 0.15, 0.28), [Vector2(0, 640), Vector2(260, 560), Vector2(560, 610), Vector2(900, 540), Vector2(1240, 600), Vector2(1560, 520), Vector2(1920, 600)]],
			[Color(0.2, 0.11, 0.22), [Vector2(0, 760), Vector2(300, 700), Vector2(650, 760), Vector2(1000, 690), Vector2(1400, 760), Vector2(1700, 650), Vector2(1920, 700)]],
			[Color(0.15, 0.08, 0.17), [Vector2(0, 900), Vector2(380, 840), Vector2(760, 900), Vector2(1150, 840), Vector2(1500, 900), Vector2(1920, 830)]],
		]
		for layer in layers:
			var points := PackedVector2Array(layer[1])
			points.append(Vector2(w, h))
			points.append(Vector2(0, h))
			draw_colored_polygon(points, layer[0])
		# Sapins en silhouette sur les bords.
		for tree in [Vector2(40, 780), Vector2(110, 820), Vector2(1580, 760), Vector2(1660, 720), Vector2(1880, 760), Vector2(1790, 820)]:
			_pine(tree, 210 if tree.x > 1500 else 180)

	func _pine(base: Vector2, height: float) -> void:
		var color := Color(0.09, 0.05, 0.1)
		for tier in 3:
			var y := base.y - height * (0.25 + tier * 0.25)
			var half := height * (0.32 - tier * 0.07)
			draw_colored_polygon(PackedVector2Array([Vector2(base.x - half, y + height * 0.32), Vector2(base.x, y - height * 0.18), Vector2(base.x + half, y + height * 0.32)]), color)
		draw_rect(Rect2(base.x - 8, base.y - height * 0.12, 16, height * 0.14), color)


class Frame:
	extends Control
	## Cadre sombre à double bordure dorée et coins coupés, avec, en option, une plaque de titre, des traits
	## de séparation et un livre ouvert en pied.

	var title := ""
	var title_size := 38
	## Séparations horizontales et verticales, en coordonnées du cadre.
	var dividers: Array[float] = []
	var vertical_dividers: Array[float] = []
	var book_bottom := false
	var bottom_diamond := true

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var outer := Ornate.chamfered(rect, 30)
		draw_colored_polygon(outer, Ornate.PANEL)
		draw_polyline(Ornate.closed(outer), Ornate.GOLD, 6.0)
		var inner := Ornate.chamfered(rect.grow(-14), 20)
		draw_polyline(Ornate.closed(inner), Ornate.GOLD_DARK, 2.0)
		for corner: Vector2 in [Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), size]:
			var inward := (size / 2.0 - corner).normalized()
			draw_line(corner + inward * 10, corner + inward * 34, Ornate.GOLD_LIGHT, 3.0)
		for y in dividers:
			Ornate.divider(self, Vector2(40, y), Vector2(size.x - 40, y))
		for x in vertical_dividers:
			draw_polygon(PackedVector2Array([Vector2(x, 60), Vector2(x + 1.5, size.y / 2), Vector2(x, size.y - 60), Vector2(x - 1.5, size.y / 2)]),
				PackedColorArray([Color(Ornate.GOLD, 0.0), Ornate.GOLD, Color(Ornate.GOLD, 0.0), Ornate.GOLD]))
			Ornate.diamond(self, Vector2(x, size.y / 2), 12)
		if bottom_diamond:
			Ornate.diamond(self, Vector2(size.x / 2, size.y), 13)
		if title != "":
			Ornate.plaque(self, Vector2(size.x / 2, 0), title, title_size)
		if book_bottom:
			Ornate.icon(self, "book", Vector2(size.x / 2, size.y - 52), 92, Ornate.GOLD)


class KeyCap:
	extends Control
	## Touche du clavier : un cadre doré arrondi et sa lettre.

	var text := ""

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.26, 0.14, 0.09)
		box.border_color = Ornate.GOLD
		box.set_border_width_all(3)
		box.set_corner_radius_all(9)
		box.shadow_color = Color(Ornate.GOLD, 0.25)
		box.shadow_size = 4
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		Ornate.centered_text(self, Ornate.SERIF, size / 2, text, 26, Ornate.CREAM)


class HexButton:
	extends Button
	## Bouton des menus : hexagone allongé à bordure dorée, losanges en haut et en bas, icône facultative ;
	## doré s'il est mis en avant ou survolé, gris s'il est désactivé.

	var caption := ""
	var icon_kind := ""
	var highlighted := false
	var font_size := 48

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)

	func _draw() -> void:
		var h := size.y
		var shape := Ornate.hexagon(Rect2(Vector2.ZERO, size), h * 0.42)
		var lit := (highlighted or is_hovered()) and not disabled
		var border := Ornate.GOLD_LIGHT if lit else Ornate.GOLD
		var text_color := Ornate.CREAM
		if disabled:
			draw_colored_polygon(shape, Color(0.24, 0.22, 0.24))
			border = Color(0.62, 0.62, 0.64)
			text_color = Color(0.6, 0.58, 0.58)
		elif lit:
			var top := Color(0.82, 0.54, 0.2)
			var low := Color(0.5, 0.29, 0.1)
			if button_pressed or is_pressed():
				top = top.darkened(0.2)
				low = low.darkened(0.2)
			draw_polygon(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
		else:
			draw_colored_polygon(shape, Color(0.17, 0.09, 0.07))
		draw_polyline(Ornate.closed(shape), border, 5.0)
		var inset := PackedVector2Array()
		var center := size / 2
		for point in shape:
			inset.append(center + (point - center) * Vector2(0.97, 0.8))
		draw_polyline(Ornate.closed(inset), Ornate.GOLD_DARK if not disabled else Color(0.45, 0.45, 0.47), 2.0)
		var diamond_fill := Ornate.GOLD if not disabled else Ornate.SILVER
		Ornate.diamond(self, Vector2(size.x / 2, 0), 12, diamond_fill)
		Ornate.diamond(self, Vector2(size.x / 2, h), 12, diamond_fill)
		var text_width := Ornate.SERIF.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_center := center
		if icon_kind != "":
			var icon_size := font_size * 0.42
			var total := text_width + icon_size * 2.0 + 24.0
			var icon_center := Vector2(center.x - total / 2.0 + icon_size, center.y)
			Ornate.icon(self, icon_kind, icon_center, icon_size, text_color, 3.5)
			text_center = Vector2(icon_center.x + icon_size + 24.0 + text_width / 2.0, center.y)
		Ornate.centered_text(self, Ornate.SERIF, text_center, caption, font_size, text_color)


class PillButton:
	extends Button
	## Bouton secondaire : cadre arrondi doré, icône à gauche et texte, comme « Se connecter » ou « Retour ».

	var caption := ""
	var icon_kind := ""
	var font_size := 26

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.36, 0.2, 0.09) if is_hovered() else Color(0.22, 0.12, 0.08)
		box.border_color = Ornate.GOLD_LIGHT if is_hovered() else Ornate.GOLD
		box.set_border_width_all(4)
		box.set_corner_radius_all(int(size.y * 0.32))
		box.shadow_color = Color(Ornate.GOLD, 0.22)
		box.shadow_size = 6
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		var text_width := Ornate.SERIF.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var icon_size := font_size * 0.62
		var total := text_width + (icon_size * 2.0 + 20.0 if icon_kind != "" else 0.0)
		var x := size.x / 2.0 - total / 2.0
		if icon_kind != "":
			Ornate.icon(self, icon_kind, Vector2(x + icon_size, size.y / 2), icon_size, Ornate.CREAM, 3.0)
			x += icon_size * 2.0 + 20.0
		Ornate.centered_text(self, Ornate.SERIF, Vector2(x + text_width / 2.0, size.y / 2), caption, font_size, Ornate.CREAM)


class TextLink:
	extends Button
	## Lien souligné, comme « Mot de passe oublié ? » ou « Renvoyer le code ».

	var caption := ""
	var font_size := 26

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		custom_minimum_size = Vector2(Ornate.TEXT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8, font_size * 1.6)

	func _draw() -> void:
		var color := Ornate.GOLD_LIGHT if is_hovered() else Ornate.CREAM
		Ornate.centered_text(self, Ornate.TEXT, size / 2, caption, font_size, color)
		var width := Ornate.TEXT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var y := size.y / 2 + font_size * 0.55
		draw_line(Vector2(size.x / 2 - width / 2, y), Vector2(size.x / 2 + width / 2, y), color, 2.0)


class Field:
	extends Control
	## Champ de saisie : cadre arrondi doré, icône à gauche et, pour un mot de passe, un œil pour l'afficher.

	var icon_kind := "user"
	var placeholder := ""
	var secret := false
	var line: LineEdit
	var _eye: Button

	func _ready() -> void:
		line = LineEdit.new()
		line.placeholder_text = placeholder
		line.secret = secret
		line.flat = true
		line.add_theme_font_override("font", Ornate.TEXT)
		line.add_theme_font_size_override("font_size", 30)
		line.add_theme_color_override("font_color", Ornate.CREAM)
		line.add_theme_color_override("font_placeholder_color", Ornate.MUTED)
		line.add_theme_color_override("caret_color", Ornate.GOLD_LIGHT)
		line.add_theme_color_override("selection_color", Color(Ornate.GOLD, 0.35))
		for state in ["normal", "focus", "read_only"]:
			line.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		line.position = Vector2(118, 6)
		line.size = Vector2(size.x - (210 if secret else 140), size.y - 12)
		line.focus_entered.connect(queue_redraw)
		line.focus_exited.connect(queue_redraw)
		add_child(line)
		if secret:
			_eye = Button.new()
			_eye.flat = true
			_eye.focus_mode = Control.FOCUS_NONE
			_eye.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			_eye.position = Vector2(size.x - 84, 6)
			_eye.size = Vector2(70, size.y - 12)
			_eye.pressed.connect(_toggle_secret)
			add_child(_eye)

	var text: String:
		get:
			return line.text if line else ""
		set(value):
			line.text = value

	func _toggle_secret() -> void:
		line.secret = not line.secret
		queue_redraw()

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.17, 0.1, 0.08)
		var focused := line != null and line.has_focus()
		box.border_color = Ornate.GOLD_LIGHT if focused else Ornate.GOLD
		box.set_border_width_all(3)
		box.set_corner_radius_all(14)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		Ornate.icon(self, icon_kind, Vector2(60, size.y / 2), size.y * 0.26, Ornate.CREAM, 3.0)
		if secret and line:
			Ornate.icon(self, "eye_off" if line.secret else "eye", Vector2(size.x - 50, size.y / 2), size.y * 0.24, Ornate.CREAM, 3.0)


class CodeBoxes:
	extends Control
	## Six cases d'un code de vérification : un chiffre par case, le curseur passe seul à la suivante,
	## Retour arrière revient à la précédente, et un code collé se répartit dans les cases.

	signal changed
	signal submitted

	const COUNT := 6
	var boxes: Array[LineEdit] = []

	func _ready() -> void:
		var box_size := 96.0
		var gap := (size.x - box_size * COUNT) / (COUNT - 1)
		for index in COUNT:
			var edit := LineEdit.new()
			edit.max_length = 1
			edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
			edit.position = Vector2(index * (box_size + gap), 0)
			edit.size = Vector2(box_size, box_size)
			edit.add_theme_font_override("font", Ornate.SERIF)
			edit.add_theme_font_size_override("font_size", 46)
			edit.add_theme_color_override("font_color", Ornate.CREAM)
			edit.add_theme_color_override("caret_color", Ornate.GOLD_LIGHT)
			# Par défaut, un champ réserve la place de quatre caractères : les cases déborderaient l'une sur l'autre.
			edit.add_theme_constant_override("minimum_character_width", 1)
			for state in ["normal", "focus"]:
				var style := StyleBoxFlat.new()
				style.bg_color = Color(0.2, 0.11, 0.08)
				style.border_color = Ornate.GOLD_LIGHT if state == "focus" else Ornate.GOLD
				style.set_border_width_all(4 if state == "focus" else 3)
				style.set_corner_radius_all(12)
				edit.add_theme_stylebox_override(state, style)
			edit.text_changed.connect(_on_text_changed.bind(index))
			edit.gui_input.connect(_on_box_input.bind(index))
			edit.text_submitted.connect(func(_text: String) -> void: submitted.emit())
			add_child(edit)
			boxes.append(edit)

	func code() -> String:
		var digits := ""
		for edit in boxes:
			digits += edit.text
		return digits

	func is_complete() -> bool:
		return code().length() == COUNT

	func clear() -> void:
		for edit in boxes:
			edit.text = ""
		boxes[0].grab_focus()
		changed.emit()

	## Remplit les cases avec un code, par exemple collé d'un coup dans la première case.
	func fill(digits: String) -> void:
		var only := ""
		for character in digits:
			if character >= "0" and character <= "9":
				only += character
		for index in COUNT:
			boxes[index].text = only[index] if index < only.length() else ""
		boxes[mini(only.length(), COUNT - 1)].grab_focus()
		changed.emit()

	func _on_text_changed(new_text: String, index: int) -> void:
		var edit := boxes[index]
		if new_text != "" and not (new_text >= "0" and new_text <= "9"):
			edit.text = ""
		elif new_text != "" and index < COUNT - 1:
			boxes[index + 1].grab_focus()
		changed.emit()

	func _on_box_input(event: InputEvent, index: int) -> void:
		var key := event as InputEventKey
		if not key or not key.pressed:
			return
		if key.keycode == KEY_BACKSPACE and boxes[index].text == "" and index > 0:
			boxes[index - 1].text = ""
			boxes[index - 1].grab_focus()
			changed.emit()
			accept_event()
		elif key.keycode == KEY_V and key.is_command_or_control_pressed():
			fill(DisplayServer.clipboard_get())
			accept_event()


class IconView:
	extends Control
	## Une icône seule, au centre du nœud.

	var kind := "user"
	var color := Ornate.CREAM
	var line_width := 3.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Ornate.icon(self, kind, size / 2, minf(size.x, size.y) / 2.0, color, line_width)


class Logo:
	extends Control
	## Emblème du titre : arche dorée et silhouettes de château, épée dressée, titre, livre ouvert et ruban.

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var title := Ornate.label("CodeQuest", 100, Ornate.CREAM, true, 24)
		title.add_theme_color_override("font_shadow_color", Ornate.GOLD_DARK)
		title.add_theme_constant_override("shadow_offset_x", 0)
		title.add_theme_constant_override("shadow_offset_y", 7)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(self, title, Vector2(-20, 136), Vector2(680, 140))
		var subtitle := Ornate.label("La Recherche des livres oubliés", 25, Ornate.INK, true)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(self, subtitle, Vector2(0, 340), Vector2(640, 40))

	func _draw() -> void:
		var cx := size.x / 2
		var gold := Ornate.GOLD
		var dark := Ornate.GOLD_DARK
		# Arche et château derrière le titre.
		draw_arc(Vector2(cx, 200), 150, PI, TAU, 48, dark, 22.0)
		draw_arc(Vector2(cx, 200), 150, PI, TAU, 48, gold, 12.0)
		var silhouette := Color(0.3, 0.18, 0.12)
		for side in [-1, 1]:
			var x: float = cx + side * 95
			draw_rect(Rect2(x - 30, 112, 60, 60), silhouette)
			draw_rect(Rect2(x - 12 + side * 8, 92, 26, 80), silhouette)
			for merlon in 3:
				draw_rect(Rect2(x - 30 + merlon * 24, 104, 12, 10), silhouette)
		# Épée dressée au milieu.
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 11, 92), Vector2(cx + 11, 92), Vector2(cx + 11, 230), Vector2(cx, 252), Vector2(cx - 11, 230)]), Color(0.98, 0.86, 0.55))
		draw_line(Vector2(cx, 96), Vector2(cx, 236), gold, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 52, 58), Vector2(cx + 52, 58), Vector2(cx + 60, 72), Vector2(cx + 52, 86), Vector2(cx - 52, 86), Vector2(cx - 60, 72)]), gold)
		draw_rect(Rect2(cx - 9, 6, 18, 54), dark)
		draw_rect(Rect2(cx - 6, 8, 12, 50), gold)
		Ornate.diamond(self, Vector2(cx, 4), 14, Ornate.GOLD_LIGHT)
		# Livre ouvert sous le titre.
		var center := Vector2(cx, 318)
		for side in [-1, 1]:
			var page := PackedVector2Array([center, center + Vector2(side * 20, -54), center + Vector2(side * 140, -46),
				center + Vector2(side * 156, 4), center + Vector2(side * 70, 12)])
			draw_colored_polygon(page, Color(0.96, 0.8, 0.46))
			draw_polyline(Ornate.closed(page), dark, 3.0)
			for line in 3:
				var y := -40.0 + line * 12
				draw_line(center + Vector2(side * 30, y), center + Vector2(side * 128, y + 4), Color(0.74, 0.54, 0.24), 2.0)
		# Ruban du sous-titre, ses deux pans repliés derrière.
		var ribbon := Rect2(60, 330, size.x - 120, 54)
		for side in [-1, 1]:
			var x: float = ribbon.position.x if side < 0 else ribbon.end.x
			var tail := PackedVector2Array([Vector2(x, ribbon.position.y + 12), Vector2(x + side * 46, ribbon.position.y + 12),
				Vector2(x + side * 26, ribbon.position.y + 40), Vector2(x + side * 46, ribbon.end.y + 12), Vector2(x, ribbon.end.y + 12)])
			draw_colored_polygon(tail, dark)
		draw_colored_polygon(PackedVector2Array([ribbon.position, Vector2(ribbon.end.x, ribbon.position.y), ribbon.end, Vector2(ribbon.position.x, ribbon.end.y)]), Color(0.96, 0.78, 0.4))
		draw_rect(ribbon, dark, false, 3.0)
		Ornate.diamond(self, Vector2(cx, ribbon.end.y + 4), 14)
