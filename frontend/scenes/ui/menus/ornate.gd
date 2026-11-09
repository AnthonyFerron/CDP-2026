class_name Ornate
## Habillage des menus de CodeQuest, d'après les maquettes : nuit violette, cadres sombres à bordure dorée et coins
## coupés, boutons hexagonaux, touches du clavier, champs de saisie et icônes. Tout est dessiné, à la résolution de
## référence 1920 × 1080 : aucun symbole ne dépend d'une police, la version web n'en ayant pas d'autre que les nôtres.
## Titres et boutons en Cinzel Bold, textes en Lora, comme dans tout le jeu.
##
## Chaque élément (cadre, bouton, pastille, touche, séparateur, icône) réunit ses formes en un seul maillage (Sketch) :
## un appel de dessin pour toutes ses formes, puis un pour son texte, au lieu d'un par polygone, ligne brisée, disque ou
## cadre arrondi. Les sommets sont ceux que le moteur calculerait pour chaque forme : l'image est la même. Voir
## docs/ornate-maillages.md.

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
const KEYS := [["Z", "Avancer"], ["Q", "Aller à gauche"], ["S", "Reculer"], ["D", "Aller à droite"], ["E", "Interagir / Action"], ["H", "Voir les indices"]]
const WIDE_KEYS := [["Espace", "Sauter"], ["Shift", "Courir"]]
## Raccourcis du jeu, rappelés en pied d'écran.
const SHORTCUTS := "Échap : pause     F : plein écran"
## Les mêmes à la manette (Gamepad), dans les menus.
const PAD_SHORTCUTS := "A : valider     B : retour     Menu : pause en jeu"
## Commandes à la manette, rappelées à la place des touches quand elle est en main : un bouton (nom de Gamepad.button_name,
## ou l'action dont il faut lire le bouton) et ce qu'il fait. Même découpage que KEYS et WIDE_KEYS.
const PAD_KEYS := [["Stick gauche", "Avancer, se tourner"], ["Stick droit", "Regarder"], [&"interact", "Interagir / Action"],
	[&"hint", "Voir les indices"], [&"pause", "Pause"], [&"inventory", "Relire les fragments"]]
const PAD_WIDE_KEYS := [[&"jump", "Sauter"], [&"sprint", "Courir (maintenir)"]]
## Couleur de la lettre des quatre boutons de la manette, celle des manettes Xbox, éclaircie pour rester lisible sur le
## fond sombre des touches.
const PAD_COLORS := {"A": Color(0.6, 0.9, 0.45), "B": Color(1.0, 0.52, 0.42), "X": Color(0.55, 0.74, 1.0), "Y": Color(1.0, 0.86, 0.4)}
## Fond des touches du clavier et des boutons de la manette.
const KEY_FILL := Color(0.26, 0.14, 0.09)


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


# --- Dessin -------------------------------------------------------------------------------------------------------
# Les fonctions de dessin ci-dessous prennent `item` : le nœud qui dessine (dans son _draw), ou un Sketch en cours.
# Sur un nœud, elles envoient leurs formes d'un bloc (un appel de dessin) ; sur un Sketch, elles s'y ajoutent, et le
# nœud qui le dessine envoie tout ensemble (Sketch.of, Sketch.done).

## Écrit un texte centré sur un point, en tenant compte de la hauteur de la police.
static func centered_text(item: Object, font: Font, center: Vector2, text: String, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := center.y + (font.get_ascent(size) - font.get_descent(size)) / 2.0
	var at := Vector2(center.x - width / 2.0, baseline)
	if item is Sketch:
		(item as Sketch).text(font, at, text, size, color)
	else:
		(item as CanvasItem).draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Losange doré, ornement des cadres et des boutons.
static func diamond(item: Object, center: Vector2, radius: float, fill := GOLD) -> void:
	var pen := Sketch.of(item)
	pen.shape([&"diamond", radius, fill], center, func(sketch: Sketch) -> void:
		var points := PackedVector2Array([Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)])
		sketch.polygon(points, GOLD_DARK)
		var inner := PackedVector2Array()
		for point in points:
			inner.append(point * 0.62)
		sketch.polygon(inner, fill)
		sketch.polyline(closed(points), GOLD_LIGHT, 2.0))
	pen.done(item)


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
static func divider(item: Object, from: Vector2, to: Vector2, with_diamond := true) -> void:
	var pen := Sketch.of(item)
	var middle := (from + to) / 2.0
	pen.polygon_colors(PackedVector2Array([from, middle + Vector2(0, -2), to, middle + Vector2(0, 2)]),
		PackedColorArray([Color(GOLD, 0.0), GOLD, Color(GOLD, 0.0), GOLD]))
	if with_diamond:
		diamond(pen, middle, 11)
	pen.done(item)


## Plaque de titre hexagonale, centrée sur un point.
static func plaque(item: Object, center: Vector2, text: String, size: int) -> Rect2:
	var pen := Sketch.of(item)
	var width := SERIF.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 2.6
	var height := size * 1.9
	var rect := Rect2(center - Vector2(width, height) / 2.0, Vector2(width, height))
	var shape := hexagon(rect, height * 0.42)
	var top := Color(0.38, 0.22, 0.1)
	var low := Color(0.22, 0.12, 0.07)
	pen.polygon_colors(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
	pen.polyline(closed(shape), GOLD, 5.0)
	var inset := PackedVector2Array()
	for point in shape:
		inset.append(center + (point - center) * Vector2(0.97, 0.8))
	pen.polyline(closed(inset), GOLD_DARK, 2.0)
	# Le losange du bas, sous le bord, ne touche pas le texte : il passe avant lui, dans le même maillage.
	diamond(pen, Vector2(center.x, rect.end.y), 11)
	centered_text(pen, SERIF, center, text, size, CREAM)
	pen.done(item)
	return rect


## Icônes au trait, dessinées dans un carré de demi-côté s autour du centre. Chacune n'est calculée qu'une fois par
## taille, couleur et trait (Sketch.shape), sauf le livre à point d'interrogation, qui a un texte.
static func icon(item: Object, kind: String, c: Vector2, s: float, color := CREAM, w := 3.0) -> void:
	var pen := Sketch.of(item)
	if kind == "question_book":
		_icon_shapes(pen, kind, c, s, color, w)
	else:
		pen.shape([&"icon", kind, s, color, w], c, func(sketch: Sketch) -> void: _icon_shapes(sketch, kind, Vector2.ZERO, s, color, w))
	pen.done(item)


static func _icon_shapes(pen: Sketch, kind: String, c: Vector2, s: float, color: Color, w: float) -> void:
	match kind:
		"user":
			pen.arc(c + Vector2(0, -0.4 * s), 0.34 * s, 0.0, TAU, 28, color, w)
			pen.arc(c + Vector2(0, 0.95 * s), 0.78 * s, PI, TAU, 28, color, w)
			pen.line(c + Vector2(-0.78 * s, 0.95 * s), c + Vector2(0.78 * s, 0.95 * s), color, w)
		"user_add":
			icon(pen, "user", c + Vector2(-0.22 * s, 0.0), 0.85 * s, color, w)
			pen.line(c + Vector2(0.72 * s, 0.05 * s), c + Vector2(0.72 * s, 0.65 * s), color, w)
			pen.line(c + Vector2(0.42 * s, 0.35 * s), c + Vector2(1.02 * s, 0.35 * s), color, w)
		"mail":
			pen.rect_outline(Rect2(c - Vector2(s, 0.7 * s), Vector2(2.0 * s, 1.4 * s)), color, w)
			pen.polyline(PackedVector2Array([c + Vector2(-s, -0.7 * s), c + Vector2(0, 0.12 * s), c + Vector2(s, -0.7 * s)]), color, w)
		"lock":
			pen.arc(c + Vector2(0, -0.12 * s), 0.42 * s, PI, TAU, 18, color, w * 1.2)
			pen.line(c + Vector2(-0.42 * s, -0.12 * s), c + Vector2(-0.42 * s, 0.0), color, w * 1.2)
			pen.line(c + Vector2(0.42 * s, -0.12 * s), c + Vector2(0.42 * s, 0.0), color, w * 1.2)
			pen.rect(Rect2(c + Vector2(-0.64 * s, -0.04 * s), Vector2(1.28 * s, 1.0 * s)), color)
			pen.circle(c + Vector2(0, 0.36 * s), 0.13 * s, INK)
			pen.rect(Rect2(c + Vector2(-0.05 * s, 0.36 * s), Vector2(0.1 * s, 0.32 * s)), INK)
		"eye", "eye_off":
			var top := PackedVector2Array()
			var bottom := PackedVector2Array()
			for step in 17:
				var t := step / 16.0
				var x := -s + 2.0 * s * t
				top.append(c + Vector2(x, -0.58 * s * sin(PI * t)))
				bottom.append(c + Vector2(x, 0.58 * s * sin(PI * t)))
			pen.polyline(top, color, w)
			pen.polyline(bottom, color, w)
			pen.circle(c, 0.27 * s, color)
			if kind == "eye_off":
				pen.line(c + Vector2(-0.85 * s, 0.85 * s), c + Vector2(0.85 * s, -0.85 * s), color, w * 1.2)
		"login":
			pen.polyline(PackedVector2Array([c + Vector2(0.15 * s, -0.9 * s), c + Vector2(0.9 * s, -0.9 * s),
				c + Vector2(0.9 * s, 0.9 * s), c + Vector2(0.15 * s, 0.9 * s)]), color, w)
			pen.line(c + Vector2(-0.95 * s, 0.0), c + Vector2(0.45 * s, 0.0), color, w)
			pen.polyline(PackedVector2Array([c + Vector2(0.05 * s, -0.4 * s), c + Vector2(0.45 * s, 0.0), c + Vector2(0.05 * s, 0.4 * s)]), color, w)
		"logout":
			pen.polyline(PackedVector2Array([c + Vector2(-0.15 * s, -0.9 * s), c + Vector2(-0.9 * s, -0.9 * s),
				c + Vector2(-0.9 * s, 0.9 * s), c + Vector2(-0.15 * s, 0.9 * s)]), color, w)
			pen.line(c + Vector2(-0.45 * s, 0.0), c + Vector2(0.95 * s, 0.0), color, w)
			pen.polyline(PackedVector2Array([c + Vector2(0.55 * s, -0.4 * s), c + Vector2(0.95 * s, 0.0), c + Vector2(0.55 * s, 0.4 * s)]), color, w)
		"check":
			pen.polyline(PackedVector2Array([c + Vector2(-0.78 * s, 0.0), c + Vector2(-0.22 * s, 0.56 * s), c + Vector2(0.82 * s, -0.62 * s)]), color, w * 1.5)
		"arrow_left":
			pen.line(c + Vector2(0.9 * s, 0.0), c + Vector2(-0.82 * s, 0.0), color, w * 1.2)
			pen.polyline(PackedVector2Array([c + Vector2(-0.3 * s, -0.5 * s), c + Vector2(-0.88 * s, 0.0), c + Vector2(-0.3 * s, 0.5 * s)]), color, w * 1.2)
		"arrow_right":
			pen.line(c + Vector2(-0.9 * s, 0.0), c + Vector2(0.82 * s, 0.0), color, w * 1.2)
			pen.polyline(PackedVector2Array([c + Vector2(0.3 * s, -0.5 * s), c + Vector2(0.88 * s, 0.0), c + Vector2(0.3 * s, 0.5 * s)]), color, w * 1.2)
		"close":
			pen.line(c + Vector2(-0.6 * s, -0.6 * s), c + Vector2(0.6 * s, 0.6 * s), color, w * 1.5)
			pen.line(c + Vector2(0.6 * s, -0.6 * s), c + Vector2(-0.6 * s, 0.6 * s), color, w * 1.5)
		"bulb":
			pen.arc(c + Vector2(0, -0.1 * s), 0.46 * s, deg_to_rad(125.0), deg_to_rad(415.0), 28, color, w * 1.3)
			pen.line(c + Vector2(-0.26 * s, 0.28 * s), c + Vector2(-0.22 * s, 0.56 * s), color, w * 1.3)
			pen.line(c + Vector2(0.26 * s, 0.28 * s), c + Vector2(0.22 * s, 0.56 * s), color, w * 1.3)
			pen.line(c + Vector2(-0.24 * s, 0.56 * s), c + Vector2(0.24 * s, 0.56 * s), color, w * 1.3)
			pen.line(c + Vector2(-0.16 * s, 0.72 * s), c + Vector2(0.16 * s, 0.72 * s), color, w * 1.3)
			for ray in 5:
				var angle := deg_to_rad(-160.0 + ray * 35.0)
				var direction := Vector2(cos(angle), sin(angle))
				pen.line(c + Vector2(0, -0.1 * s) + direction * 0.66 * s, c + Vector2(0, -0.1 * s) + direction * 0.92 * s, color, w * 1.3)
		"book":
			_book(pen, c + Vector2(0, 0.35 * s), s, color)
		"question_book":
			_book(pen, c + Vector2(0, 0.45 * s), s, color)
			centered_text(pen, SERIF, c + Vector2(0, -0.32 * s), "?", int(s * 1.1), color)
			for ray in 4:
				var angle := deg_to_rad([-150.0, -120.0, -60.0, -30.0][ray])
				var direction := Vector2(cos(angle), sin(angle))
				pen.line(c + Vector2(0, -0.32 * s) + direction * 0.55 * s, c + Vector2(0, -0.32 * s) + direction * 0.78 * s, color, w)
		"stopwatch":
			pen.arc(c + Vector2(0, 0.12 * s), 0.72 * s, 0.0, TAU, 32, color, w)
			pen.rect(Rect2(c + Vector2(-0.16 * s, -0.95 * s), Vector2(0.32 * s, 0.2 * s)), color)
			pen.line(c + Vector2(0, -0.75 * s), c + Vector2(0, -0.6 * s), color, w)
			pen.line(c + Vector2(0, 0.12 * s), c + Vector2(0.3 * s, -0.22 * s), color, w)
		"shield_lock":
			var shield := PackedVector2Array([c + Vector2(0, -s), c + Vector2(0.82 * s, -0.66 * s), c + Vector2(0.76 * s, 0.2 * s),
				c + Vector2(0, s), c + Vector2(-0.76 * s, 0.2 * s), c + Vector2(-0.82 * s, -0.66 * s)])
			pen.polygon(shield, PANEL_LIGHT)
			pen.polyline(closed(shield), color, w * 1.4)
			icon(pen, "lock", c + Vector2(0, -0.02 * s), 0.46 * s, color, w)
		"laurel_left", "laurel_right":
			# Branche courbe qui monte du bas vers le haut, des feuilles de part et d'autre.
			var side := -1.0 if kind == "laurel_left" else 1.0
			var pivot := c + Vector2(-side * 0.45 * s, 0.0)
			var branch := PackedVector2Array()
			for step in 13:
				var angle := deg_to_rad(100.0 + step * 12.5)
				branch.append(pivot + Vector2(side * -cos(angle), sin(angle)) * 0.9 * s)
			pen.polyline(branch, color, w)
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
					pen.polygon(shape, color)
		"volcano":
			var mountain := PackedVector2Array([c + Vector2(-s, 0.7 * s), c + Vector2(-0.22 * s, -0.42 * s), c + Vector2(0.22 * s, -0.42 * s), c + Vector2(s, 0.7 * s)])
			pen.polygon(mountain, Color(0.32, 0.16, 0.12))
			pen.polygon(PackedVector2Array([c + Vector2(-0.22 * s, -0.42 * s), c + Vector2(0.22 * s, -0.42 * s),
				c + Vector2(0.05 * s, 0.1 * s), c + Vector2(0.12 * s, 0.7 * s), c + Vector2(-0.06 * s, 0.7 * s), c + Vector2(-0.1 * s, 0.05 * s)]), Color(1.0, 0.45, 0.12))
			for spark in 5:
				var angle := deg_to_rad(-150.0 + spark * 30.0)
				pen.circle(c + Vector2(0, -0.5 * s) + Vector2(cos(angle), sin(angle)) * 0.32 * s, 0.06 * s, Color(1.0, 0.62, 0.2))


static func _book(pen: Sketch, center: Vector2, s: float, color: Color) -> void:
	for side in [-1.0, 1.0]:
		var page := PackedVector2Array([center, center + Vector2(side * 0.12 * s, -0.46 * s), center + Vector2(side * 0.95 * s, -0.4 * s),
			center + Vector2(side * s, 0.12 * s), center + Vector2(side * 0.45 * s, 0.2 * s)])
		pen.polygon(page, color)
		pen.polyline(closed(page), GOLD_DARK, 2.0)
		for line in 3:
			var y := -0.3 + line * 0.13
			pen.line(center + Vector2(side * 0.2 * s, y * s), center + Vector2(side * 0.82 * s, (y + 0.03) * s), GOLD_DARK, 1.5)


## Panneau des commandes : touches dorées et leur action, en deux groupes séparés d'un trait. La manette en main, ses
## boutons remplacent les touches (Gamepad), aux mêmes places.
static func commands(frame: Control, top: float, step: float, wide_step: float, columns := Vector2(92, 196)) -> float:
	var keyboard := _command_sheet(frame, "Clavier")
	var pad := _command_sheet(frame, "Manette")
	Gamepad.swap(keyboard, false)
	Gamepad.swap(pad, true)
	var y := top
	for index in KEYS.size():
		var cap := KeyCap.new()
		cap.text = KEYS[index][0]
		place(keyboard, cap, Vector2(columns.x, y), Vector2(52, 46))
		var name := label(KEYS[index][1], 28)
		name.position = Vector2(columns.y, y + 2)
		keyboard.add_child(name)
		_pad_command(pad, PAD_KEYS[index], Vector2(columns.x, y), columns.y)
		y += step
	var line_y := y + 4.0
	y += 30.0
	for index in WIDE_KEYS.size():
		var cap := KeyCap.new()
		cap.text = WIDE_KEYS[index][0]
		place(keyboard, cap, Vector2(columns.x - 12, y), Vector2(170, 52))
		var name := label(WIDE_KEYS[index][1], 28)
		name.position = Vector2(columns.x + 212, y + 5)
		keyboard.add_child(name)
		_pad_command(pad, PAD_WIDE_KEYS[index], Vector2(columns.x, y + 3), columns.y)
		y += wide_step
	return line_y


## Calque d'un jeu de commandes (clavier ou manette), à la taille du cadre : il dessine ses touches d'un bloc (KeySheet).
static func _command_sheet(frame: Control, sheet_name: String) -> Control:
	var sheet := KeySheet.new()
	sheet.name = sheet_name
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(frame, sheet, Vector2.ZERO, frame.size)
	return sheet


static func _pad_command(sheet: Control, item: Array, at: Vector2, text_x: float) -> void:
	var cap := KeyCap.new()
	cap.pad = Gamepad.button_name(item[0]) if item[0] is StringName else item[0]
	place(sheet, cap, at, Vector2(52, 46))
	var name := label(item[1], 28)
	name.position = Vector2(text_x, at.y + 2)
	sheet.add_child(name)


## Cadre doré du bouton sélectionné à la manette (Gamepad) : un liseré clair et son halo, à la forme du bouton, et deux
## losanges qui le désignent, à gauche et à droite, pour les boutons larges. `kind` : &"hex" (boutons hexagonaux),
## &"round" (boutons et champs arrondis, `cut` étant leur rayon), &"chamfer" (cases à coins coupés, `cut` étant le coin).
static func focus_ring(item: Object, rect: Rect2, kind := &"chamfer", cut := 14.0) -> void:
	var pen := Sketch.of(item)
	if kind == &"round":
		for layer: Array in [[Color(GOLD_LIGHT, 0.3), 9, 11.0], [GOLD_LIGHT, 3, 7.0]]:
			var box := StyleBoxFlat.new()
			box.draw_center = false
			box.border_color = layer[0]
			box.set_border_width_all(layer[1])
			box.set_corner_radius_all(int(cut + layer[2]))
			box.set_expand_margin_all(layer[2])
			pen.style_box(box, rect)
	else:
		var outer := hexagon(rect.grow(9.0), (rect.size.y + 18.0) * 0.42) if kind == &"hex" else chamfered(rect.grow(7.0), cut + 4.0)
		pen.polyline(closed(outer), Color(GOLD_LIGHT, 0.3), 9.0)
		pen.polyline(closed(outer), GOLD_LIGHT, 3.0)
	if rect.size.x >= 160.0:
		var middle := rect.position.y + rect.size.y / 2.0
		var gap := 26.0 if kind == &"hex" else 22.0
		diamond(pen, Vector2(rect.position.x - gap, middle), 9.0, GOLD_LIGHT)
		diamond(pen, Vector2(rect.end.x + gap, middle), 9.0, GOLD_LIGHT)
	pen.done(item)


## Bouton de la manette, dessiné dans le style des touches du clavier (KeyCap) : A, B, X et Y ronds, à la lettre de leur
## couleur ; Menu et Affichage ronds, à leur dessin ; LB, RB, LT et RT en gâchette ; les sticks, une tête de stick ; la
## croix directionnelle. Sans `with_label`, seule la forme est dessinée : un texte posé dessus écrit la lettre.
static func pad_glyph(item: Object, rect: Rect2, glyph: String, with_label := true) -> void:
	var pen := Sketch.of(item)
	var center := rect.get_center()
	var fill := KEY_FILL
	var radius := minf(rect.size.x, rect.size.y) / 2.0 - 1.5
	match glyph:
		"LB", "RB", "LT", "RT":
			var box := StyleBoxFlat.new()
			box.bg_color = fill
			box.border_color = GOLD
			box.set_border_width_all(3)
			var round := int(minf(rect.size.y * 0.5, 18.0))
			box.corner_radius_top_left = round if glyph.begins_with("L") else 6
			box.corner_radius_top_right = round if glyph.begins_with("R") else 6
			box.corner_radius_bottom_left = 6
			box.corner_radius_bottom_right = 6
			box.shadow_color = Color(GOLD, 0.25)
			box.shadow_size = 4
			pen.style_box(box, rect)
			if with_label:
				centered_text(pen, SERIF, center, glyph, int(clampf(rect.size.y * 0.46, 14.0, 24.0)), CREAM)
			pen.done(item)
			return
		"Croix":
			var arm := radius * 0.42
			var cross := PackedVector2Array([center + Vector2(-arm, -radius), center + Vector2(arm, -radius), center + Vector2(arm, -arm),
				center + Vector2(radius, -arm), center + Vector2(radius, arm), center + Vector2(arm, arm), center + Vector2(arm, radius),
				center + Vector2(-arm, radius), center + Vector2(-arm, arm), center + Vector2(-radius, arm), center + Vector2(-radius, -arm),
				center + Vector2(-arm, -arm)])
			pen.polygon(cross, fill)
			pen.polyline(closed(cross), GOLD, 3.0)
			pen.done(item)
			return
	if not glyph in ["A", "B", "X", "Y", "Menu", "Affichage", "L3", "R3", "Stick gauche", "Stick droit"]:
		# Bouton inconnu : une touche ordinaire et son nom.
		var key := StyleBoxFlat.new()
		key.bg_color = fill
		key.border_color = GOLD
		key.set_border_width_all(3)
		key.set_corner_radius_all(9)
		pen.style_box(key, rect)
		if with_label:
			centered_text(pen, SERIF, center, glyph, 22, CREAM)
		pen.done(item)
		return
	pen.circle(center, radius + 3.0, Color(GOLD, 0.22))
	pen.circle(center, radius, fill)
	pen.arc(center, radius, 0.0, TAU, 40, GOLD, 3.0)
	var s := radius
	match glyph:
		"Menu":
			for row in 3:
				var y := (row - 1) * 0.3 * s
				pen.line(center + Vector2(-0.42 * s, y), center + Vector2(0.42 * s, y), CREAM, 3.0)
		"Affichage":
			pen.rect_outline(Rect2(center + Vector2(-0.48 * s, -0.4 * s), Vector2(0.6 * s, 0.48 * s)), CREAM, 2.5)
			pen.rect(Rect2(center + Vector2(-0.12 * s, -0.08 * s), Vector2(0.6 * s, 0.48 * s)), fill)
			pen.rect_outline(Rect2(center + Vector2(-0.12 * s, -0.08 * s), Vector2(0.6 * s, 0.48 * s)), CREAM, 2.5)
		"L3", "R3", "Stick gauche", "Stick droit":
			# Tête de stick : un disque bombé et sa lettre.
			pen.circle(center, s * 0.62, Color(0.4, 0.24, 0.13))
			pen.arc(center, s * 0.62, 0.0, TAU, 32, GOLD_LIGHT, 2.0)
			var letter := "L" if glyph in ["L3", "Stick gauche"] else "R"
			centered_text(pen, SERIF, center, letter, int(clampf(s * 0.8, 12.0, 24.0)), CREAM)
		_:
			if with_label:
				centered_text(pen, SERIF, center + Vector2(0, 1), glyph, int(clampf(s * 1.15, 14.0, 30.0)), PAD_COLORS.get(glyph, CREAM))
	pen.done(item)


## Le bouton se dessine sans lettre (une lettre posée dessus l'écrit) : vrai pour les boutons à lettre.
static func pad_glyph_has_letter(glyph: String) -> bool:
	return glyph in ["A", "B", "X", "Y", "LB", "RB", "LT", "RT"]


class Sketch:
	extends RefCounted
	## Formes d'un nœud réunies en un seul maillage (sommets et couleur par sommet, trois sommets par triangle), envoyé
	## d'un bloc au rendu (RenderingServer.canvas_item_add_triangle_array) : un appel de dessin pour toutes, au lieu d'un
	## par forme. Le rendu Compatibility ne regroupe jamais deux polygones (draw_polygon, draw_polyline, draw_circle,
	## draw_arc, draw_style_box en sont tous) : chacun lui coûtait un appel.
	##
	## Chaque forme reprend les sommets et les triangles que le moteur (Godot 4.7) calcule pour la fonction de dessin du
	## même nom, sans anticrénelage comme elles : polygon (draw_colored_polygon, même triangulation), polyline
	## (draw_polyline : bande de triangles, onglets aux coins), line (draw_line épais), rect et rect_outline (draw_rect),
	## circle (draw_circle, 64 secteurs), arc (draw_arc), style_box (StyleBoxFlat.draw : ombre, bordure, fond et
	## anticrénelage des coins arrondis). Les formes gardent leur ordre ; un texte (text) ferme le maillage en cours, et
	## le suivant reprend après lui : l'ordre des formes et des textes est celui des appels.
	##
	## Les formes qui ne dépendent que de leur taille (cadre arrondi d'un StyleBoxFlat, arc, disque, icône, losange) sont
	## calculées une fois, autour de l'origine, et gardées (_shapes) : les suivantes, identiques à une translation près,
	## sont recopiées et déplacées d'un bloc (Transform2D * PackedVector2Array), sans repasser par le GDScript. Les
	## triangles sont rangés sommet par sommet, sans indices : recopier une forme ne demande pas de renuméroter ses
	## sommets.

	const FLT_EPSILON := 1.1920929e-07
	## Formes gardées au plus : au-delà, la réserve est vidée (les menus en utilisent quelques dizaines).
	const SHAPES_MAX := 512

	## Formes déjà calculées, autour de l'origine : clé (paramètres de la forme) -> [sommets, couleurs].
	static var _shapes := {}
	## Couleurs des draw_line, arrondies en demi-flottants (half).
	static var _halves := {}

	## Suréchantillonnage du nœud dessiné : StyleBoxFlat règle la largeur de son anticrénelage dessus.
	var oversampling := 1.0
	## Textes gardés pour la fin, après toutes les formes, rangés par police et par taille (chacune a sa texture, et
	## passer de l'une à l'autre coupe un lot de glyphes) : seulement quand aucune forme ne recouvre un texte.
	var texts_last := false
	var _points := PackedVector2Array()
	var _colors := PackedColorArray()
	## Morceaux déjà fermés, dans l'ordre : un maillage [sommets, couleurs] ou un texte (7 valeurs).
	var _pieces: Array = []
	var _late: Array = []
	## Maillage indexé de travail d'un StyleBoxFlat (_rounded), déplié dans _points à la fin.
	var _mesh_points := PackedVector2Array()
	var _mesh_colors := PackedColorArray()
	var _mesh_indices := PackedInt32Array()

	## Le maillage où tracer pour `item` : `item` lui-même s'il en est déjà un (les formes s'y ajoutent), sinon un neuf
	## pour ce nœud, que done(item) envoie alors au rendu. Les fonctions de dessin d'Ornate s'en servent : appelées sur un
	## nœud, elles coûtent un appel de dessin ; sur un Sketch, aucun de plus.
	static func of(item: Object) -> Sketch:
		return item as Sketch if item is Sketch else Sketch.new(item as CanvasItem)

	## Fin d'un tracé commencé par of(item) : rien si `item` est ce Sketch, sinon il est envoyé au rendu de `item`.
	func done(item: Object) -> void:
		if item != self:
			draw(item as CanvasItem)

	func _init(item: CanvasItem = null) -> void:
		if item and item.is_inside_tree():
			var value := item.get_viewport().get_oversampling()
			oversampling = value if value > 0.0 else 1.0

	## Envoie le tout au rendu, dans l'ordre : à appeler dans le _draw du nœud.
	func draw(item: CanvasItem) -> void:
		_close()
		if not _late.is_empty():
			_late.sort_custom(func(a: Array, b: Array) -> bool:
				return a[0].get_instance_id() < b[0].get_instance_id() or (a[0] == b[0] and a[5] < b[5]))
			_pieces.append_array(_late)
			_late.clear()
		var rid := item.get_canvas_item()
		for piece: Array in _pieces:
			if piece.size() == 2:
				RenderingServer.canvas_item_add_triangle_array(rid, PackedInt32Array(), piece[0], piece[1])
			else:
				item.draw_string(piece[0], piece[1], piece[2], piece[3], piece[4], piece[5], piece[6])
		_pieces.clear()

	func is_empty() -> bool:
		return _points.is_empty() and _pieces.is_empty() and _late.is_empty()

	## Texte (draw_string), dessiné après les formes déjà tracées et avant les suivantes (ou à la fin, `texts_last`).
	func text(font: Font, position: Vector2, value: String, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
		if texts_last:
			_late.append([font, position, value, alignment, width, size, color])
			return
		_close()
		_pieces.append([font, position, value, alignment, width, size, color])

	func _close() -> void:
		if not _points.is_empty():
			_pieces.append([_points, _colors])
			_points = PackedVector2Array()
			_colors = PackedColorArray()

	func _fill(color: Color, count: int) -> void:
		var colors := PackedColorArray()
		colors.resize(count)
		colors.fill(color)
		_colors.append_array(colors)

	## Ajoute les triangles d'un maillage indexé, dépliés : trois sommets par triangle.
	func _triangles(points: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array) -> void:
		var count := indices.size()
		var base := _points.size()
		_points.resize(base + count)
		for k in count:
			_points[base + k] = points[indices[k]]
		if colors.size() == points.size():
			_colors.resize(base + count)
			for k in count:
				_colors[base + k] = colors[indices[k]]
		else:
			_fill(colors[0], count)

	## Bande de triangles (k, k + 1, k + 2), dépliée, d'une couleur.
	func _strip(strip: PackedVector2Array, color: Color) -> void:
		var triangles := strip.size() - 2
		if triangles <= 0:
			return
		var base := _points.size()
		_points.resize(base + triangles * 3)
		var j := base
		for k in triangles:
			_points[j] = strip[k]
			_points[j + 1] = strip[k + 1]
			_points[j + 2] = strip[k + 2]
			j += 3
		_fill(color, triangles * 3)

	## Forme gardée (_shapes), identique à une translation près d'une fois sur l'autre : calculée une fois autour de
	## l'origine par `build` (qui trace dans le Sketch qu'on lui donne, sans texte), puis recopiée ici, déplacée de
	## `offset`. `key` décrit tout ce dont la forme dépend, sauf sa place.
	func shape(key: Array, offset: Vector2, build: Callable) -> void:
		var found: Variant = _shapes.get(key)
		if found == null:
			var sketch := Sketch.new()
			sketch.oversampling = oversampling
			build.call(sketch)
			sketch._close()
			var points := PackedVector2Array()
			var colors := PackedColorArray()
			for piece: Array in sketch._pieces:
				points.append_array(piece[0])
				colors.append_array(piece[1])
			if _shapes.size() >= SHAPES_MAX:
				_shapes.clear()
			found = [points, colors]
			_shapes[key] = found
		var shape_points: PackedVector2Array = found[0]
		_points.append_array(Transform2D(0.0, offset) * shape_points if offset != Vector2.ZERO else shape_points)
		_colors.append_array(found[1])

	## draw_colored_polygon : la triangulation du moteur (Geometry2D.triangulate_polygon).
	func polygon(points: PackedVector2Array, color: Color) -> void:
		polygon_colors(points, PackedColorArray([color]))

	## draw_polygon à une couleur par sommet (ou une seule).
	func polygon_colors(points: PackedVector2Array, colors: PackedColorArray) -> void:
		var triangles := Geometry2D.triangulate_polygon(points)
		if not triangles.is_empty():
			_triangles(points, colors, triangles)

	## draw_rect plein.
	func rect(area: Rect2, color: Color) -> void:
		area = area.abs()
		var a := area.position
		var b := Vector2(area.end.x, area.position.y)
		var c := area.end
		var d := Vector2(area.position.x, area.end.y)
		_points.append_array([a, b, c, a, c, d])
		_fill(color, 6)

	## draw_rect vide : son contour fermé, ou le rectangle agrandi si le trait est plus large que lui.
	func rect_outline(area: Rect2, color: Color, width: float) -> void:
		area = area.abs()
		if width >= area.size.x or width >= area.size.y:
			rect(area.grow(0.5 * width), color)
			return
		polyline(PackedVector2Array([area.position, area.position + Vector2(area.size.x, 0), area.position + area.size,
			area.position + Vector2(0, area.size.y), area.position]), color, width)

	## draw_line épais : un quadrilatère. Le moteur en passe la couleur en demi-flottants (16 bits) : elle l'est ici aussi.
	func line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
		var direction := (from - to).orthogonal().normalized()
		var offset := direction * width * 0.5
		var a := from + offset
		var c := to - offset
		_points.append_array([a, from - offset, c, a, c, to + offset])
		_fill(Sketch.half(color), 6)

	## draw_circle plein : 64 secteurs autour du centre.
	func circle(center: Vector2, radius: float, color: Color) -> void:
		shape([&"circle", radius, color], center, func(sketch: Sketch) -> void: sketch._circle(radius, color))

	func _circle(radius: float, color: Color) -> void:
		var step := TAU / 64.0
		var rim := PackedVector2Array()
		rim.resize(65)
		for i in 65:
			var angle := i * step
			rim[i] = Vector2(cos(angle) * radius, sin(angle) * radius)
		var base := _points.size()
		_points.resize(base + 192)
		var j := base
		for i in 64:
			_points[j] = Vector2.ZERO
			_points[j + 1] = rim[i]
			_points[j + 2] = rim[i + 1]
			j += 3
		_fill(color, 192)

	## draw_arc : `count` points sur l'arc, reliés par une ligne brisée.
	func arc(center: Vector2, radius: float, start: float, end: float, count: int, color: Color, width: float) -> void:
		shape([&"arc", radius, start, end, count, color, width], center, func(sketch: Sketch) -> void:
			var points := PackedVector2Array()
			points.resize(count)
			var delta := clampf(end - start, -TAU, TAU)
			for i in count:
				var theta := (i / (count - 1.0)) * delta + start
				points[i] = Vector2(radius * cos(theta), radius * sin(theta))
			sketch.polyline(points, color, width))

	## draw_polyline épais, sans anticrénelage : une bande de triangles, deux sommets par point, en onglet aux coins
	## (au plus trois fois la demi-largeur). Une ligne qui revient à son premier point est fermée sans rupture.
	func polyline(points: PackedVector2Array, color: Color, width: float) -> void:
		var count := points.size()
		if count < 2:
			return
		var loop := points[0].is_equal_approx(points[count - 1])
		var first_direction := Vector2.ZERO
		for i in range(1, count):
			first_direction = (points[i] - points[i - 1]).normalized()
			if not first_direction.is_zero_approx():
				break
		var last_direction := Vector2.ZERO
		for i in range(count - 1, 0, -1):
			last_direction = (points[i] - points[i - 1]).normalized()
			if not last_direction.is_zero_approx():
				break
		var strip := PackedVector2Array()
		strip.resize(count * 2)
		var half_width := width * 0.5
		var previous := Vector2.ZERO
		for i in count:
			var is_last := i == count - 1
			var direction := previous
			if not is_last:
				direction = (points[i + 1] - points[i]).normalized()
				if direction.is_zero_approx():
					direction = previous
			if i == 0 and loop:
				previous = last_direction
			elif is_last and loop:
				previous = first_direction
			var offset: Vector2
			if i == 0 and not loop:
				offset = first_direction.orthogonal()
			elif is_last and not loop:
				offset = last_direction.orthogonal()
			else:
				# Bissectrice des deux segments, allongée pour garder la largeur du trait (au plus trois fois).
				var length := 1.0
				var bisector := (previous * direction.length() - direction * previous.length()).normalized()
				var sine := sin(atan2(bisector.cross(previous), bisector.dot(previous)))
				if not is_zero_approx(sine) and not direction.is_equal_approx(previous):
					length = clampf(1.0 / sine, -3.0, 3.0)
				else:
					bisector = direction.orthogonal()
				if bisector.is_zero_approx():
					bisector = direction.orthogonal()
				offset = bisector * length
			var edge := offset * half_width
			strip[i * 2] = points[i] + edge
			strip[i * 2 + 1] = points[i] - edge
			previous = direction
		_strip(strip, color)

	## Couleur arrondie comme le moteur l'envoie pour un draw_line : chaque composante en demi-flottant (mantisse
	## tronquée à 10 bits, zéro sous 2^-14).
	static func half(color: Color) -> Color:
		var known: Variant = _halves.get(color)
		if known != null:
			return known
		var bytes := PackedByteArray()
		bytes.resize(4)
		var result := color
		for k in 4:
			bytes.encode_float(0, color[k])
			var bits := bytes.decode_u32(0)
			if bits & 0x7F800000 <= 0x38000000:
				result[k] = 0.0
			else:
				bytes.encode_u32(0, bits & 0xFFFFE000)
				result[k] = bytes.decode_float(0)
		if _halves.size() < SHAPES_MAX:
			_halves[color] = result
		return result

	## draw_style_box d'un StyleBoxFlat, comme StyleBoxFlat.draw : mêmes anneaux et mêmes triangles (ombre, bordure,
	## fond, anticrénelage des coins arrondis), dans le même ordre. Calculé une fois par jeu de réglages et par taille.
	func style_box(box: StyleBoxFlat, area: Rect2) -> void:
		var key := [&"box", area.size, oversampling, box.bg_color, box.border_color, box.border_width_left, box.border_width_top,
			box.border_width_right, box.border_width_bottom, box.corner_radius_top_left, box.corner_radius_top_right,
			box.corner_radius_bottom_right, box.corner_radius_bottom_left, box.corner_detail, box.expand_margin_left,
			box.expand_margin_top, box.expand_margin_right, box.expand_margin_bottom, box.draw_center, box.shadow_color,
			box.shadow_size, box.shadow_offset, box.anti_aliasing, box.anti_aliasing_size, box.skew, box.border_blend]
		shape(key, area.position, func(sketch: Sketch) -> void:
			sketch._box(box, Rect2(Vector2.ZERO, area.size))
			sketch._triangles(sketch._mesh_points, sketch._mesh_colors, sketch._mesh_indices))

	func _box(box: StyleBoxFlat, area: Rect2) -> void:
		var widths: Array[float] = [box.border_width_left, box.border_width_top, box.border_width_right, box.border_width_bottom]
		var radii: Array[float] = [box.corner_radius_top_left, box.corner_radius_top_right, box.corner_radius_bottom_right, box.corner_radius_bottom_left]
		var draw_border := widths[0] > 0 or widths[1] > 0 or widths[2] > 0 or widths[3] > 0
		var draw_shadow := box.shadow_size > 0
		var draw_center := box.draw_center
		if not draw_border and not draw_center and not draw_shadow:
			return
		var style_rect := area.grow_individual(box.expand_margin_left, box.expand_margin_top, box.expand_margin_right, box.expand_margin_bottom)
		if is_zero_approx(style_rect.size.x) or is_zero_approx(style_rect.size.y):
			return
		var rounded := radii[0] > 0 or radii[1] > 0 or radii[2] > 0 or radii[3] > 0
		var skew := box.skew
		var aa_on := (rounded or not skew.is_zero_approx()) and box.anti_aliasing
		var blend_on := box.border_blend and draw_border
		var bg := box.bg_color
		var border := box.border_color
		var border_alpha := Color(border.r, border.g, border.b, 0)
		var border_blend := bg if draw_center else border_alpha
		var border_inner := border_blend if blend_on else border
		var width := maxf(style_rect.size.x, 0)
		var height := maxf(style_rect.size.y, 0)
		var adapted_border: Array[float] = [1000000.0, 1000000.0, 1000000.0, 1000000.0]
		Sketch._adapt(SIDE_TOP, SIDE_BOTTOM, adapted_border, widths, height, height, height)
		Sketch._adapt(SIDE_LEFT, SIDE_RIGHT, adapted_border, widths, width, width, width)
		var corner: Array[float] = [1000000.0, 1000000.0, 1000000.0, 1000000.0]
		Sketch._adapt(CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, corner, radii, height, height - adapted_border[SIDE_BOTTOM], height - adapted_border[SIDE_TOP])
		Sketch._adapt(CORNER_TOP_LEFT, CORNER_BOTTOM_LEFT, corner, radii, height, height - adapted_border[SIDE_BOTTOM], height - adapted_border[SIDE_TOP])
		Sketch._adapt(CORNER_TOP_LEFT, CORNER_TOP_RIGHT, corner, radii, width, width - adapted_border[SIDE_RIGHT], width - adapted_border[SIDE_LEFT])
		Sketch._adapt(CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT, corner, radii, width, width - adapted_border[SIDE_RIGHT], width - adapted_border[SIDE_LEFT])
		var infill := style_rect.grow_individual(-adapted_border[SIDE_LEFT], -adapted_border[SIDE_TOP], -adapted_border[SIDE_RIGHT], -adapted_border[SIDE_BOTTOM])
		var border_rect := style_rect
		var aa := 1.0
		if aa_on:
			aa = box.anti_aliasing_size / oversampling
			for side in 4:
				if widths[side] > 0:
					border_rect = border_rect.grow_side(side, -aa)
		var detail := box.corner_detail
		if draw_shadow:
			var shadow_inner := style_rect
			shadow_inner.position += box.shadow_offset
			var shadow_rect := style_rect.grow(box.shadow_size)
			shadow_rect.position += box.shadow_offset
			var shadow := box.shadow_color
			var shadow_clear := Color(shadow.r, shadow.g, shadow.b, 0)
			_rounded(shadow_inner, corner, shadow_rect, shadow_inner, shadow, shadow_clear, detail, skew)
			if draw_center:
				_rounded(shadow_inner, corner, shadow_inner, shadow_inner, shadow, shadow, detail, skew, true)
		if draw_border and not aa_on:
			_rounded(border_rect, corner, border_rect, infill, border_inner, border, detail, skew)
		if draw_center and (not aa_on or blend_on):
			_rounded(border_rect, corner, infill, infill, bg, bg, detail, skew, true)
		if not aa_on:
			return
		var aa_border: Array[float] = [0.0, 0.0, 0.0, 0.0]
		var aa_border_half: Array[float] = [0.0, 0.0, 0.0, 0.0]
		var aa_fill: Array[float] = [0.0, 0.0, 0.0, 0.0]
		var aa_fill_half: Array[float] = [0.0, 0.0, 0.0, 0.0]
		for side in 4:
			if draw_border and widths[side] > 0:
				aa_border[side] = aa
				aa_border_half[side] = aa * 0.5
			else:
				aa_fill[side] = aa
				aa_fill_half[side] = aa * 0.5
		if draw_center:
			var fill_clear_rect := infill.grow_individual(aa_fill_half[SIDE_LEFT], aa_fill_half[SIDE_TOP], aa_fill_half[SIDE_RIGHT], aa_fill_half[SIDE_BOTTOM])
			var fill_rect := fill_clear_rect.grow_individual(-aa_fill[SIDE_LEFT], -aa_fill[SIDE_TOP], -aa_fill[SIDE_RIGHT], -aa_fill[SIDE_BOTTOM])
			if not blend_on:
				_rounded(border_rect, corner, fill_rect, fill_rect, bg, bg, detail, skew, true)
			if not blend_on or not draw_border:
				_rounded(border_rect, corner, fill_clear_rect, fill_rect, bg, Color(bg.r, bg.g, bg.b, 0), detail, skew)
		if draw_border:
			var inner_colored := infill.grow_individual(aa_border_half[SIDE_LEFT], aa_border_half[SIDE_TOP], aa_border_half[SIDE_RIGHT], aa_border_half[SIDE_BOTTOM])
			var inner_clear := inner_colored.grow_individual(-aa_border[SIDE_LEFT], -aa_border[SIDE_TOP], -aa_border[SIDE_RIGHT], -aa_border[SIDE_BOTTOM])
			var outer_clear := style_rect.grow_individual(aa_border_half[SIDE_LEFT], aa_border_half[SIDE_TOP], aa_border_half[SIDE_RIGHT], aa_border_half[SIDE_BOTTOM])
			var outer_colored := border_rect.grow_individual(aa_border_half[SIDE_LEFT], aa_border_half[SIDE_TOP], aa_border_half[SIDE_RIGHT], aa_border_half[SIDE_BOTTOM])
			_rounded(border_rect, corner, outer_colored, infill if blend_on else inner_colored, border_inner, border, detail, skew)
			if not blend_on:
				_rounded(border_rect, corner, inner_colored, inner_clear, border_blend, border, detail, skew)
			_rounded(border_rect, corner, outer_clear, outer_colored, border, border_alpha, detail, skew)

	static func _adapt(a: int, b: int, adapted: Array[float], values: Array[float], width: float, max_a: float, max_b: float) -> void:
		var value_a := values[a]
		var value_b := values[b]
		var factor := minf(1.0, width / (value_a + value_b)) if value_a + value_b > 0.0 else 1.0
		adapted[a] = minf(minf(value_a * factor, max_a), adapted[a])
		adapted[b] = minf(minf(value_b * factor, max_b), adapted[b])

	## Rayons des coins d'un rectangle intérieur (draw_rounded_rectangle de StyleBoxFlat).
	static func _inner_radius(style_rect: Rect2, inner: Rect2, radius: Array[float]) -> Array[float]:
		var left := inner.position.x - style_rect.position.x
		var top := inner.position.y - style_rect.position.y
		var right := style_rect.size.x - inner.size.x - left
		var bottom := style_rect.size.y - inner.size.y - top
		return [maxf(radius[0] - minf(top, left), 0), maxf(radius[1] - minf(top, right), 0),
			maxf(radius[2] - minf(bottom, right), 0), maxf(radius[3] - minf(bottom, left), 0)]

	## Réduction des coins qui déborderaient d'un bord trop court (set_corner_scale de StyleBoxFlat).
	static func _corner_scale(style_rect: Rect2, inner: Rect2, radius: Array[float]) -> Array[Vector2]:
		var left := inner.position.x - style_rect.position.x
		var top := inner.position.y - style_rect.position.y
		var right := style_rect.size.x - inner.size.x - left
		var bottom := style_rect.size.y - inner.size.y - top
		var overflow: Array[float] = [-minf(0, inner.size.y - radius[0] - radius[3]), -minf(0, inner.size.x - radius[0] - radius[1]),
			-minf(0, inner.size.y - radius[1] - radius[2]), -minf(0, inner.size.x - radius[3] - radius[2])]
		var horizontal := left + right
		var vertical := top + bottom
		var ratios: Array[float] = [left / horizontal if horizontal > 0 else 0.0, top / vertical if vertical > 0 else 0.0,
			right / horizontal if horizontal > 0 else 0.0, bottom / vertical if vertical > 0 else 0.0]
		var reduction: Array[Vector2] = [Vector2(overflow[1] * ratios[0], overflow[0] * ratios[1]), Vector2(overflow[1] * ratios[2], overflow[2] * ratios[1]),
			Vector2(overflow[3] * ratios[2], overflow[2] * ratios[3]), Vector2(overflow[3] * ratios[0], overflow[0] * ratios[3])]
		var corners: Array[Vector2] = []
		var leftovers: Array[Vector2] = []
		for i in 4:
			corners.append(Vector2(radius[i], radius[i]))
			leftovers.append(-((corners[i] - reduction[i]).minf(0)))
		var distributed: Array[Vector2] = [(corners[0] - reduction[0] - leftovers[3] - leftovers[1]).maxf(0),
			(corners[1] - reduction[1] - leftovers[0] - leftovers[2]).maxf(0), (corners[2] - reduction[2] - leftovers[1] - leftovers[3]).maxf(0),
			(corners[3] - reduction[3] - leftovers[2] - leftovers[0]).maxf(0)]
		var scale: Array[Vector2] = []
		for i in 4:
			var unshrinkable := (leftovers[(i + 1) % 4] + leftovers[(i + 3) % 4] - distributed[i]).maxf(0)
			scale.append(distributed[i] / (corners[i] - unshrinkable).maxf(FLT_EPSILON))
		return scale

	## Un anneau à coins arrondis entre deux rectangles (`ring` dehors, `inner` dedans), ou un rectangle arrondi plein
	## (`filled`), comme draw_rounded_rectangle de StyleBoxFlat : dans le maillage indexé de travail (_mesh_*).
	func _rounded(style_rect: Rect2, radius: Array[float], ring: Rect2, inner: Rect2, inner_color: Color, outer_color: Color,
			detail: int, skew: Vector2, filled := false) -> void:
		var offset := _mesh_points.size()
		var steps := detail if radius[0] > 0 or radius[1] > 0 or radius[2] > 0 or radius[3] > 0 else 1
		var border := not filled
		var ring_radius := Sketch._inner_radius(style_rect, ring, radius)
		var ring_scale := Sketch._corner_scale(style_rect, ring, ring_radius)
		var outer_points: Array[Vector2] = [ring.position + Vector2(ring_radius[0], ring_radius[0]) * ring_scale[0],
			Vector2(ring.position.x + ring.size.x - ring_radius[1] * ring_scale[1].x, ring.position.y + ring_radius[1] * ring_scale[1].y),
			ring.position + ring.size - Vector2(ring_radius[2], ring_radius[2]) * ring_scale[2],
			Vector2(ring.position.x + ring_radius[3] * ring_scale[3].x, ring.position.y + ring.size.y - ring_radius[3] * ring_scale[3].y)]
		var inner_radius := Sketch._inner_radius(style_rect, inner, radius)
		var inner_scale := Sketch._corner_scale(style_rect, inner, inner_radius)
		var inner_points: Array[Vector2] = [inner.position + Vector2(inner_radius[0], inner_radius[0]) * inner_scale[0],
			Vector2(inner.position.x + inner.size.x - inner_radius[1] * inner_scale[1].x, inner.position.y + inner_radius[1] * inner_scale[1].y),
			inner.position + inner.size - Vector2(inner_radius[2], inner_radius[2]) * inner_scale[2],
			Vector2(inner.position.x + inner_radius[3] * inner_scale[3].x, inner.position.y + inner.size.y - inner_radius[3] * inner_scale[3].y)]
		var center := style_rect.get_center()
		var count := (steps + 1) * (8 if border else 4)
		_mesh_points.resize(offset + count)
		_mesh_colors.resize(offset + count)
		for corner in 4:
			for step in steps + 1:
				var index := (steps + 1) * corner + step
				if border:
					index *= 2
				var angle := (corner + step / float(steps)) * (PI / 2.0) + PI
				var cosine := cos(angle)
				var sine := sin(angle)
				var x := inner_radius[corner] * cosine * inner_scale[corner].x + inner_points[corner].x
				var y := inner_radius[corner] * sine * inner_scale[corner].y + inner_points[corner].y
				_mesh_points[offset + index] = Vector2(x - skew.x * (y - center.y), y - skew.y * (x - center.x))
				_mesh_colors[offset + index] = inner_color
				if border:
					x = ring_radius[corner] * cosine * ring_scale[corner].x + outer_points[corner].x
					y = ring_radius[corner] * sine * ring_scale[corner].y + outer_points[corner].y
					_mesh_points[offset + index + 1] = Vector2(x - skew.x * (y - center.y), y - skew.y * (x - center.x))
					_mesh_colors[offset + index + 1] = outer_color
		if border:
			for i in count:
				_mesh_indices.append_array([offset + i % count, offset + (i + 2) % count, offset + (i + 1) % count])
		else:
			var last := count - 1
			for i in count / 2 - 1:
				_mesh_indices.append_array([offset + i, offset + last - i - 1, offset + i + 1, offset + i, offset + last - i, offset + last - i - 1])


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
		var pen := Sketch.new(self)
		var rect := Rect2(Vector2.ZERO, size)
		var outer := Ornate.chamfered(rect, 30)
		pen.polygon(outer, Ornate.PANEL)
		pen.polyline(Ornate.closed(outer), Ornate.GOLD, 6.0)
		var inner := Ornate.chamfered(rect.grow(-14), 20)
		pen.polyline(Ornate.closed(inner), Ornate.GOLD_DARK, 2.0)
		for corner: Vector2 in [Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), size]:
			var inward := (size / 2.0 - corner).normalized()
			pen.line(corner + inward * 10, corner + inward * 34, Ornate.GOLD_LIGHT, 3.0)
		for y in dividers:
			Ornate.divider(pen, Vector2(40, y), Vector2(size.x - 40, y))
		for x in vertical_dividers:
			pen.polygon_colors(PackedVector2Array([Vector2(x, 60), Vector2(x + 1.5, size.y / 2), Vector2(x, size.y - 60), Vector2(x - 1.5, size.y / 2)]),
				PackedColorArray([Color(Ornate.GOLD, 0.0), Ornate.GOLD, Color(Ornate.GOLD, 0.0), Ornate.GOLD]))
			Ornate.diamond(pen, Vector2(x, size.y / 2), 12)
		if bottom_diamond:
			Ornate.diamond(pen, Vector2(size.x / 2, size.y), 13)
		# Le livre du pied passe avant la plaque du haut (loin de son texte) : un seul maillage, puis le titre.
		if book_bottom:
			Ornate.icon(pen, "book", Vector2(size.x / 2, size.y - 52), 92, Ornate.GOLD)
		if title != "":
			Ornate.plaque(pen, Vector2(size.x / 2, 0), title, title_size)
		pen.draw(self)


class KeyCap:
	extends Control
	## Touche du clavier : un cadre doré arrondi et sa lettre. Avec `action`, quand la manette est en main, le bouton de
	## la manette lié à cette action remplace la touche (Gamepad) ; avec `pad`, ce bouton est toujours montré.

	## Cadre de la touche, le même pour toutes.
	static var _box: StyleBoxFlat

	var text := ""
	var action := &""
	var pad := ""
	## Seulement la forme du bouton de la manette : un texte posé dessus en écrit la lettre (messages du HUD).
	var bare := false

	func _ready() -> void:
		add_to_group(Gamepad.GLYPH_GROUP)

	## Bouton de la manette montré, ou "" pour la touche du clavier.
	func glyph() -> String:
		if pad != "":
			return pad
		if action != &"" and Gamepad.active:
			return Gamepad.button_name(action)
		return ""

	func _draw() -> void:
		var sheet := KeySheet.of(self)
		if sheet:
			# Dessinée par son calque, avec les autres touches (bascule de la manette comprise).
			sheet.queue_redraw()
			return
		var shown := glyph()
		if shown != "":
			Ornate.pad_glyph(self, Rect2(Vector2.ZERO, size), shown, not bare)
			return
		draw_style_box(KeyCap.key_box(), Rect2(Vector2.ZERO, size))
		Ornate.centered_text(self, Ornate.SERIF, size / 2, text, 26, Ornate.CREAM)

	## La touche dans un maillage (KeySheet), à sa place `rect`.
	func paint(pen: Sketch, rect: Rect2) -> void:
		var shown := glyph()
		if shown != "":
			Ornate.pad_glyph(pen, rect, shown, not bare)
			return
		pen.style_box(KeyCap.key_box(), rect)
		Ornate.centered_text(pen, Ornate.SERIF, rect.position + size / 2, text, 26, Ornate.CREAM)

	static func key_box() -> StyleBoxFlat:
		if not _box:
			_box = StyleBoxFlat.new()
			_box.bg_color = Ornate.KEY_FILL
			_box.border_color = Ornate.GOLD
			_box.set_border_width_all(3)
			_box.set_corner_radius_all(9)
			_box.shadow_color = Color(Ornate.GOLD, 0.25)
			_box.shadow_size = 4
		return _box


class KeySheet:
	extends Control
	## Calque qui dessine d'un bloc des touches : ses enfants KeyCap (panneaux de commandes), et les contrôles qu'il
	## adopte (adopt), posés à côté de lui dans le même parent (touches du clavier virtuel). Un maillage pour toutes leurs
	## formes, puis leurs lettres, rangées par police et par taille : trois ou quatre appels de dessin en tout, au lieu
	## d'une forme et d'une lettre par touche, chacune entre deux légendes. Les légendes (Label), de la même police, se
	## suivent alors et ne coûtent qu'un appel ensemble.
	##
	## Une touche ainsi dessinée (KeyCap, ou tout contrôle qui a paint(pen, rect)) ne dessine rien elle-même : son _draw
	## demande celui du calque (KeySheet.of), qui la redessine avec les autres, dans l'ordre (enfants, puis adoptés).
	## Le calque ne prend ni la souris ni le focus : les touches restent des boutons ordinaires.

	var _members: Array[Control] = []

	## Le calque qui dessine ce contrôle, ou null s'il se dessine lui-même.
	static func of(control: Control) -> KeySheet:
		var sheet: Variant = control.get_meta(&"key_sheet", null)
		if sheet is KeySheet and is_instance_valid(sheet):
			return sheet
		return control.get_parent() as KeySheet

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		child_entered_tree.connect(_on_child_entered)
		for child in get_children():
			_on_child_entered(child)

	## Dessine désormais `control`, un voisin du calque (même parent) qui a une méthode paint(pen, rect).
	func adopt(control: Control) -> void:
		_members.append(control)
		control.set_meta(&"key_sheet", self)
		_watch(control)

	func _on_child_entered(child: Node) -> void:
		if child is KeyCap:
			_watch(child as Control)

	func _watch(control: Control) -> void:
		if not control.item_rect_changed.is_connected(queue_redraw):
			control.item_rect_changed.connect(queue_redraw)
			control.visibility_changed.connect(queue_redraw)
		queue_redraw()

	func _draw() -> void:
		var pen := Sketch.new(self)
		pen.texts_last = true
		for child in get_children():
			var cap := child as KeyCap
			if cap and cap.visible:
				cap.paint(pen, Rect2(cap.position, cap.size))
		for member in _members:
			if is_instance_valid(member) and member.visible and member.get_parent() == get_parent():
				member.call(&"paint", pen, Rect2(member.position - position, member.size))
		pen.draw(self)


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
		Gamepad.setup(self)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)

	func _draw() -> void:
		var pen := Sketch.new(self)
		var h := size.y
		var shape := Ornate.hexagon(Rect2(Vector2.ZERO, size), h * 0.42)
		var lit := (highlighted or Gamepad.lit(self)) and not disabled
		var border := Ornate.GOLD_LIGHT if lit else Ornate.GOLD
		var text_color := Ornate.CREAM
		if disabled:
			pen.polygon(shape, Color(0.24, 0.22, 0.24))
			border = Color(0.62, 0.62, 0.64)
			text_color = Color(0.6, 0.58, 0.58)
		elif lit:
			var top := Color(0.82, 0.54, 0.2)
			var low := Color(0.5, 0.29, 0.1)
			if button_pressed or is_pressed():
				top = top.darkened(0.2)
				low = low.darkened(0.2)
			pen.polygon_colors(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
		else:
			pen.polygon(shape, Color(0.17, 0.09, 0.07))
		pen.polyline(Ornate.closed(shape), border, 5.0)
		var inset := PackedVector2Array()
		var center := size / 2
		for point in shape:
			inset.append(center + (point - center) * Vector2(0.97, 0.8))
		pen.polyline(Ornate.closed(inset), Ornate.GOLD_DARK if not disabled else Color(0.45, 0.45, 0.47), 2.0)
		var diamond_fill := Ornate.GOLD if not disabled else Ornate.SILVER
		Ornate.diamond(pen, Vector2(size.x / 2, 0), 12, diamond_fill)
		Ornate.diamond(pen, Vector2(size.x / 2, h), 12, diamond_fill)
		var text_width := Ornate.SERIF.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_center := center
		if icon_kind != "":
			var icon_size := font_size * 0.42
			var total := text_width + icon_size * 2.0 + 24.0
			var icon_center := Vector2(center.x - total / 2.0 + icon_size, center.y)
			Ornate.icon(pen, icon_kind, icon_center, icon_size, text_color, 3.5)
			text_center = Vector2(icon_center.x + icon_size + 24.0 + text_width / 2.0, center.y)
		# Le cadre de la manette entoure le bouton, hors du texte : il passe avant lui, dans le même maillage.
		if Gamepad.focused(self):
			Ornate.focus_ring(pen, Rect2(Vector2.ZERO, size), &"hex")
		Ornate.centered_text(pen, Ornate.SERIF, text_center, caption, font_size, text_color)
		pen.draw(self)


class PillButton:
	extends Button
	## Bouton secondaire : cadre arrondi doré, icône à gauche et texte, comme « Se connecter » ou « Retour ».

	var caption := ""
	var icon_kind := ""
	var font_size := 26

	func _ready() -> void:
		flat = true
		Gamepad.setup(self)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var pen := Sketch.new(self)
		var box := StyleBoxFlat.new()
		var lit := Gamepad.lit(self)
		box.bg_color = Color(0.36, 0.2, 0.09) if lit else Color(0.22, 0.12, 0.08)
		box.border_color = Ornate.GOLD_LIGHT if lit else Ornate.GOLD
		box.set_border_width_all(4)
		box.set_corner_radius_all(int(size.y * 0.32))
		box.shadow_color = Color(Ornate.GOLD, 0.22)
		box.shadow_size = 6
		pen.style_box(box, Rect2(Vector2.ZERO, size))
		var text_width := Ornate.SERIF.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var icon_size := font_size * 0.62
		var total := text_width + (icon_size * 2.0 + 20.0 if icon_kind != "" else 0.0)
		var x := size.x / 2.0 - total / 2.0
		if icon_kind != "":
			Ornate.icon(pen, icon_kind, Vector2(x + icon_size, size.y / 2), icon_size, Ornate.CREAM, 3.0)
			x += icon_size * 2.0 + 20.0
		# Le cadre de la manette entoure le bouton, hors du texte : il passe avant lui, dans le même maillage.
		if Gamepad.focused(self):
			Ornate.focus_ring(pen, Rect2(Vector2.ZERO, size), &"round", size.y * 0.32)
		Ornate.centered_text(pen, Ornate.SERIF, Vector2(x + text_width / 2.0, size.y / 2), caption, font_size, Ornate.CREAM)
		pen.draw(self)


class TextLink:
	extends Button
	## Lien souligné, comme « Mot de passe oublié ? » ou « Renvoyer le code ».

	var caption := ""
	var font_size := 26

	func _ready() -> void:
		flat = true
		Gamepad.setup(self)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		custom_minimum_size = Vector2(Ornate.TEXT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8, font_size * 1.6)

	func _draw() -> void:
		# Le texte d'abord : le trait de soulignement passe sur ses jambages, comme avant.
		var pen := Sketch.new(self)
		var color := Ornate.GOLD_LIGHT if Gamepad.lit(self) else Ornate.CREAM
		Ornate.centered_text(pen, Ornate.TEXT, size / 2, caption, font_size, color)
		var width := Ornate.TEXT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var y := size.y / 2 + font_size * 0.55
		pen.line(Vector2(size.x / 2 - width / 2, y), Vector2(size.x / 2 + width / 2, y), color, 2.0)
		if Gamepad.focused(self):
			var text_rect := Rect2(Vector2(size.x / 2 - width / 2 - 10, size.y / 2 - font_size * 0.8), Vector2(width + 20, font_size * 1.7))
			Ornate.focus_ring(pen, text_rect, &"round", 8.0)
		pen.draw(self)


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
		# La manette atteint le champ, et A y ouvre le clavier virtuel (Gamepad, PadKeyboard).
		Gamepad.track_text(line)
		add_to_group(Gamepad.GLYPH_GROUP)
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
		var pen := Sketch.new(self)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.17, 0.1, 0.08)
		var focused := line != null and line.has_focus()
		box.border_color = Ornate.GOLD_LIGHT if focused else Ornate.GOLD
		box.set_border_width_all(3)
		box.set_corner_radius_all(14)
		pen.style_box(box, Rect2(Vector2.ZERO, size))
		Ornate.icon(pen, icon_kind, Vector2(60, size.y / 2), size.y * 0.26, Ornate.CREAM, 3.0)
		if secret and line:
			Ornate.icon(pen, "eye_off" if line.secret else "eye", Vector2(size.x - 50, size.y / 2), size.y * 0.24, Ornate.CREAM, 3.0)
		if line and Gamepad.focused(line):
			Ornate.focus_ring(pen, Rect2(Vector2.ZERO, size), &"round", 14.0)
		pen.draw(self)


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
			Gamepad.track_text(edit)
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
		var pen := Sketch.new(self)
		var cx := size.x / 2
		var gold := Ornate.GOLD
		var dark := Ornate.GOLD_DARK
		# Arche et château derrière le titre.
		pen.arc(Vector2(cx, 200), 150, PI, TAU, 48, dark, 22.0)
		pen.arc(Vector2(cx, 200), 150, PI, TAU, 48, gold, 12.0)
		var silhouette := Color(0.3, 0.18, 0.12)
		for side in [-1, 1]:
			var x: float = cx + side * 95
			pen.rect(Rect2(x - 30, 112, 60, 60), silhouette)
			pen.rect(Rect2(x - 12 + side * 8, 92, 26, 80), silhouette)
			for merlon in 3:
				pen.rect(Rect2(x - 30 + merlon * 24, 104, 12, 10), silhouette)
		# Épée dressée au milieu.
		pen.polygon(PackedVector2Array([Vector2(cx - 11, 92), Vector2(cx + 11, 92), Vector2(cx + 11, 230), Vector2(cx, 252), Vector2(cx - 11, 230)]), Color(0.98, 0.86, 0.55))
		pen.line(Vector2(cx, 96), Vector2(cx, 236), gold, 3.0)
		pen.polygon(PackedVector2Array([Vector2(cx - 52, 58), Vector2(cx + 52, 58), Vector2(cx + 60, 72), Vector2(cx + 52, 86), Vector2(cx - 52, 86), Vector2(cx - 60, 72)]), gold)
		pen.rect(Rect2(cx - 9, 6, 18, 54), dark)
		pen.rect(Rect2(cx - 6, 8, 12, 50), gold)
		Ornate.diamond(pen, Vector2(cx, 4), 14, Ornate.GOLD_LIGHT)
		# Livre ouvert sous le titre.
		var center := Vector2(cx, 318)
		for side in [-1, 1]:
			var page := PackedVector2Array([center, center + Vector2(side * 20, -54), center + Vector2(side * 140, -46),
				center + Vector2(side * 156, 4), center + Vector2(side * 70, 12)])
			pen.polygon(page, Color(0.96, 0.8, 0.46))
			pen.polyline(Ornate.closed(page), dark, 3.0)
			for line in 3:
				var y := -40.0 + line * 12
				pen.line(center + Vector2(side * 30, y), center + Vector2(side * 128, y + 4), Color(0.74, 0.54, 0.24), 2.0)
		# Ruban du sous-titre, ses deux pans repliés derrière.
		var ribbon := Rect2(60, 330, size.x - 120, 54)
		for side in [-1, 1]:
			var x: float = ribbon.position.x if side < 0 else ribbon.end.x
			var tail := PackedVector2Array([Vector2(x, ribbon.position.y + 12), Vector2(x + side * 46, ribbon.position.y + 12),
				Vector2(x + side * 26, ribbon.position.y + 40), Vector2(x + side * 46, ribbon.end.y + 12), Vector2(x, ribbon.end.y + 12)])
			pen.polygon(tail, dark)
		pen.polygon(PackedVector2Array([ribbon.position, Vector2(ribbon.end.x, ribbon.position.y), ribbon.end, Vector2(ribbon.position.x, ribbon.end.y)]), Color(0.96, 0.78, 0.4))
		pen.rect_outline(ribbon, dark, 3.0)
		Ornate.diamond(pen, Vector2(cx, ribbon.end.y + 4), 14)
		pen.draw(self)
