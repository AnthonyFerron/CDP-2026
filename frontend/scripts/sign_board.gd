@tool
class_name SignBoard
extends Node3D
## Panneau à texte intégré : une planche (bois, pierre, parchemin ou fer) et son texte écrit sur la face, éclairé
## comme elle, sans halo ni contour. Le texte se replie et rapetisse seul pour tenir dans la planche.
## Le panneau se pose sur deux poteaux, contre un mur, ou suspendu à une potence. Sa face regarde vers +Z.
## Il ne fait que l'affichage et la collision : pour un texte à lire avec E, le placer sous un Readable.
##
## Tout est construit à l'exécution (et dans l'éditeur) : la scène ne garde que les réglages.

enum Style { WOOD, STONE, PARCHMENT, IRON }
enum Mount { POSTS, WALL, HANGING }

const INK := {
	Style.WOOD: Color(0.14, 0.08, 0.04),
	Style.STONE: Color(0.16, 0.15, 0.14),
	Style.PARCHMENT: Color(0.22, 0.12, 0.06),
	Style.IRON: Color(0.95, 0.85, 0.62),
}
const FACE := {
	Style.WOOD: Color(0.58, 0.39, 0.22),
	Style.STONE: Color(0.6, 0.58, 0.54),
	Style.PARCHMENT: Color(0.93, 0.85, 0.68),
	Style.IRON: Color(0.24, 0.24, 0.27),
}
const FRAME := {
	Style.WOOD: Color(0.36, 0.22, 0.12),
	Style.STONE: Color(0.45, 0.43, 0.4),
	Style.PARCHMENT: Color(0.4, 0.25, 0.13),
	Style.IRON: Color(0.12, 0.12, 0.14),
}
const POST_COLOR := Color(0.33, 0.21, 0.12)
## Section des poteaux, et leur écart derrière la planche.
const POST_SIZE := 0.1
const POST_BACK := 0.05
## Petit toit : deux planches inclinées, leur centre à ROOF_RISE au-dessus de la planche et à ROOF_OFFSET devant ou
## derrière elle ; elles dépassent de ROOF_OVERHANG de chaque côté.
const ROOF_RISE := 0.24
const ROOF_OFFSET := 0.16
const ROOF_ANGLE := 28.0
const ROOF_THICKNESS := 0.05
const ROOF_DEPTH := 0.4
const ROOF_OVERHANG := 0.2
const FONT_SIZE := 64
const SERIF: Font = preload("res://ui/cinzel_bold.tres")
const TEXT: Font = preload("res://assets/fonts/Lora.ttf")

@export_multiline var text := "":
	set(value):
		text = value
		_rebuild()
@export var style := Style.WOOD:
	set(value):
		style = value
		_rebuild()
@export var mount := Mount.POSTS:
	set(value):
		mount = value
		_rebuild()
## Largeur et hauteur de la planche, en mètres.
@export var board_size := Vector2(1.4, 0.8):
	set(value):
		board_size = value
		_rebuild()
## Hauteur du centre de la planche au-dessus du pied du panneau.
@export var board_height := 1.5:
	set(value):
		board_height = value
		_rebuild()
## Hauteur d'une ligne de texte, en mètres : elle diminue si le texte ne tient pas.
@export var line_height := 0.15:
	set(value):
		line_height = value
		_rebuild()
## Titres et enseignes en Cinzel, textes longs en Lora.
@export var serif := true:
	set(value):
		serif = value
		_rebuild()
## Le texte est aussi écrit au dos, pour un panneau qu'on voit des deux côtés.
@export var double_sided := false:
	set(value):
		double_sided = value
		_rebuild()
## Petit toit de planches au-dessus d'un panneau d'affichage.
@export var roof := false:
	set(value):
		roof = value
		_rebuild()
@export var collision := true:
	set(value):
		collision = value
		_rebuild()

var _built: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for node in _built:
		if is_instance_valid(node):
			node.queue_free()
	_built.clear()
	var thickness := 0.06 if style == Style.PARCHMENT else 0.1
	var center := Vector3(0.0, board_height, 0.0)
	if mount == Mount.WALL:
		center.z = thickness / 2.0
	# Planche et cadre.
	_box(center, Vector3(board_size.x, board_size.y, thickness), FACE[style])
	var frame := 0.06 if style != Style.IRON else 0.04
	var front := center.z + thickness / 2.0
	for side in [-1.0, 1.0]:
		_box(Vector3(side * (board_size.x - frame) / 2.0, center.y, front), Vector3(frame, board_size.y, 0.03), FRAME[style])
		_box(Vector3(0.0, center.y + side * (board_size.y - frame) / 2.0, front), Vector3(board_size.x, frame, 0.03), FRAME[style])
		if double_sided:
			var back := center.z - thickness / 2.0
			_box(Vector3(side * (board_size.x - frame) / 2.0, center.y, back), Vector3(frame, board_size.y, 0.03), FRAME[style])
			_box(Vector3(0.0, center.y + side * (board_size.y - frame) / 2.0, back), Vector3(board_size.x, frame, 0.03), FRAME[style])
	if style == Style.PARCHMENT:
		# Clous aux coins de l'affiche.
		for x in [-1.0, 1.0]:
			for y in [-1.0, 1.0]:
				_box(Vector3(x * (board_size.x / 2.0 - 0.11), center.y + y * (board_size.y / 2.0 - 0.11), front + 0.02), Vector3(0.04, 0.04, 0.03), Color(0.2, 0.2, 0.22))
	var post_z := center.z - thickness / 2.0 - POST_BACK
	var post_top := _post_top(center, post_z)
	match mount:
		Mount.POSTS:
			for side in [-1.0, 1.0]:
				_box(Vector3(side * (board_size.x / 2.0 + 0.03), post_top / 2.0, post_z), Vector3(POST_SIZE, post_top, POST_SIZE), POST_COLOR)
		Mount.HANGING:
			# Potence : un montant, un bras, deux chaînes.
			var arm_y := center.y + board_size.y / 2.0 + 0.35
			var x := -board_size.x / 2.0 - 0.25
			_box(Vector3(x, arm_y / 2.0, 0.0), Vector3(0.12, arm_y + 0.1, 0.12), POST_COLOR)
			_box(Vector3(0.05, arm_y, 0.0), Vector3(board_size.x + 0.6, 0.1, 0.1), POST_COLOR)
			for side in [-1.0, 1.0]:
				_box(Vector3(side * board_size.x * 0.38, (arm_y + center.y + board_size.y / 2.0) / 2.0, 0.0), Vector3(0.025, arm_y - center.y - board_size.y / 2.0, 0.025), Color(0.18, 0.18, 0.2))
	if roof:
		for side in [-1.0, 1.0]:
			var plank := _box(Vector3(0.0, center.y + board_size.y / 2.0 + ROOF_RISE, center.z + side * ROOF_OFFSET),
				Vector3(board_size.x + 2.0 * ROOF_OVERHANG, ROOF_THICKNESS, ROOF_DEPTH), FRAME[style])
			plank.rotation.x = side * deg_to_rad(ROOF_ANGLE)
	# Texte.
	if not text.strip_edges().is_empty():
		_label(Vector3(0.0, center.y, front + 0.018), 0.0)
		if double_sided:
			_label(Vector3(0.0, center.y, center.z - thickness / 2.0 - 0.018), PI)
	if collision and not Engine.is_editor_hint():
		var body := StaticBody3D.new()
		var depth := maxf(thickness + 0.1, 0.25)
		match mount:
			Mount.HANGING:
				# Suspendue, la planche laisse passer dessous : seul le montant de la potence arrête le joueur.
				var arm_y := center.y + board_size.y / 2.0 + 0.35
				_collide(body, Vector3(0.3, arm_y + 0.1, 0.3), Vector3(-board_size.x / 2.0 - 0.25, (arm_y + 0.1) / 2.0, 0.0))
			Mount.POSTS:
				# Les deux poteaux et la planche : le dessous de la planche reste libre, sans mur invisible.
				for side in [-1.0, 1.0]:
					_collide(body, Vector3(0.25, post_top, 0.25), Vector3(side * (board_size.x / 2.0 + 0.03), post_top / 2.0, post_z))
				_collide(body, Vector3(board_size.x + 0.2, board_size.y, depth), center)
			Mount.WALL:
				_collide(body, Vector3(board_size.x + 0.2, board_size.y, depth), center)
		_add(body)



## Haut des poteaux : un peu au-dessus de la planche ou, sous un petit toit, jusqu'à lui. Le dessous du toit monte
## vers le faîte : le poteau s'arrête juste au-dessus de son point le plus haut, au bord du poteau côté faîte,
## donc touche le toit sur toute sa section, sans ressortir au-dessus (la planche est plus épaisse que la pente
## sur la section du poteau).
func _post_top(center: Vector3, post_z: float) -> float:
	if not roof:
		return center.y + board_size.y / 2.0 + 0.08
	var edge := post_z + signf(center.z - post_z) * POST_SIZE / 2.0
	return _roof_underside(center, edge) + 0.002


## Hauteur du dessous du petit toit à la profondeur z : la planche de devant pour z > center.z, sinon celle de
## derrière. Chacune monte vers le faîte, au-dessus de la planche du panneau.
func _roof_underside(center: Vector3, z: float) -> float:
	var side := 1.0 if z > center.z else -1.0
	var angle := deg_to_rad(ROOF_ANGLE)
	var middle := center.y + board_size.y / 2.0 + ROOF_RISE + (z - center.z - side * ROOF_OFFSET) * -side * tan(angle)
	return middle - ROOF_THICKNESS / 2.0 / cos(angle)


func _collide(body: StaticBody3D, size: Vector3, position: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = position
	body.add_child(shape)

func _label(position: Vector3, yaw: float) -> void:
	var font: Font = SERIF if serif else TEXT
	var margin := 0.1 + (0.04 if style == Style.PARCHMENT else 0.0)
	var inner := Vector2(board_size.x - 2.0 * margin, board_size.y - 2.0 * margin)
	# Taille du texte : la hauteur de ligne voulue, réduite jusqu'à ce que tout tienne dans la planche.
	var pixel := line_height / (FONT_SIZE * 1.25)
	for attempt in 12:
		var width_px := inner.x / pixel
		var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width_px, FONT_SIZE)
		if measured.y * pixel <= inner.y and measured.x * pixel <= inner.x + 0.001:
			break
		pixel *= 0.88
	var label := Label3D.new()
	label.text = text
	label.font = font
	label.font_size = FONT_SIZE
	label.pixel_size = pixel
	label.width = inner.x / pixel
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = INK[style]
	label.outline_size = 0
	label.shaded = true
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	label.position = position
	label.rotation.y = yaw
	_add(label)


func _box(position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9 if style != Style.IRON else 0.45
	material.metallic = 0.0 if style != Style.IRON else 0.6
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	_add(instance)
	return instance


func _add(node: Node) -> void:
	# Enfants internes : ils ne sont pas enregistrés dans la scène.
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_built.append(node)
