@tool
class_name RingMechanism
extends Node3D
## Mécanisme circulaire posé au sol : cinq cercles concentriques gravés des 26 lettres, qui pivotent
## chacun sur eux-mêmes. Un repère fixe, au nord, désigne la lettre choisie sur chaque cercle.
## Les cercles reposent sur un socle de pierre ; chaque cercle intérieur dépasse un peu de celui qui l'entoure,
## et les lettres sont gravées à leur surface.

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const RING_COUNT := 5
const INNER_RADIUS := 0.9
const RING_WIDTH := 0.5
## Socle : rayon et épaisseur. Le repère doré y est couché.
const PLINTH_RADIUS := 4.0
const PLINTH_HEIGHT := 0.1
## Hauteur du dessus du cercle extérieur au-dessus du socle, et marche entre deux cercles.
const RING_BASE := 0.07
const RING_STEP := 0.025
## Capitales romaines des gravures (la police du texte courant perd son N en maillage).
const ENGRAVING_FONT: Font = preload("res://ui/cinzel_bold.tres")
## Taille d'un pixel de lettre sur le cercle intérieur, et ce qu'elle gagne à chaque cercle vers l'extérieur.
const LETTER_PIXEL := 0.0035
const LETTER_PIXEL_STEP := 0.0004

@export var stone_color := Color(0.32, 0.3, 0.3)
@export var letter_color := Color(0.82, 0.68, 0.38)

## Lettre désignée par le repère sur chaque cercle, de l'intérieur vers l'extérieur.
var letters: Array[int] = []

var _rings: Array[Node3D] = []
var _tweens: Array[Tween] = []
var _letter_material: StandardMaterial3D
var _glow_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	letters.resize(RING_COUNT)
	letters.fill(0)
	_build()


func code() -> String:
	var result := ""
	for index in letters:
		result += LETTERS[index]
	return result


## Fait pivoter un cercle d'un cran : +1 avance d'une lettre, -1 recule d'une lettre.
func rotate_ring(ring: int, step: int) -> void:
	letters[ring] = wrapi(letters[ring] + step, 0, LETTERS.length())
	_turn(ring)


func set_letters(word: String) -> void:
	for ring in RING_COUNT:
		letters[ring] = LETTERS.find(word[ring])
		_turn(ring)


## Illumine les lettres et les cercles (rouge au refus, vert à la réussite) ; une énergie faible les rend à la pierre.
func set_glow(color: Color, energy: float) -> void:
	var glowing := energy > 1.0
	if _letter_material:
		_letter_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glowing else BaseMaterial3D.SHADING_MODE_PER_PIXEL
		_letter_material.albedo_color = Color(color.r * energy, color.g * energy, color.b * energy) if glowing else letter_color
	for material in _glow_materials:
		material.emission_enabled = glowing
		material.emission = color
		material.emission_energy_multiplier = 0.12 * energy


## Hauteur du dessus d'un cercle : l'intérieur est le plus haut.
static func ring_top(ring: int) -> float:
	return PLINTH_HEIGHT + RING_BASE + (RING_COUNT - 1 - ring) * RING_STEP


func _turn(ring: int) -> void:
	if _tweens[ring]:
		_tweens[ring].kill()
	var target := letters[ring] * TAU / LETTERS.length()
	var current := _rings[ring].rotation.y
	_tweens[ring] = create_tween()
	_tweens[ring].tween_property(_rings[ring], "rotation:y", current + wrapf(target - current, -PI, PI), 0.25)


func _build() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = stone_color
	stone.roughness = 1.0
	var groove := StandardMaterial3D.new()
	groove.albedo_color = stone_color.darkened(0.45)
	groove.roughness = 1.0
	var plinth_material := StandardMaterial3D.new()
	plinth_material.albedo_color = stone_color.darkened(0.2)
	plinth_material.roughness = 1.0
	_glow_materials = [stone, groove]
	_letter_material = StandardMaterial3D.new()
	_letter_material.albedo_color = letter_color
	_letter_material.roughness = 1.0

	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = PLINTH_RADIUS
	plinth_mesh.bottom_radius = PLINTH_RADIUS + 0.05
	plinth_mesh.height = PLINTH_HEIGHT
	plinth_mesh.radial_segments = 48
	plinth_mesh.material = plinth_material
	var plinth := MeshInstance3D.new()
	plinth.mesh = plinth_mesh
	plinth.position.y = PLINTH_HEIGHT * 0.5
	add_child(plinth)

	# Les 26 lettres sont taillées une fois : chaque cercle les reprend, à sa taille.
	var glyphs: Array[TextMesh] = []
	for index in LETTERS.length():
		var glyph := TextMesh.new()
		glyph.font = ENGRAVING_FONT
		glyph.text = LETTERS[index]
		glyph.font_size = 64
		glyph.pixel_size = LETTER_PIXEL
		glyph.depth = 0.0
		glyphs.append(glyph)
	for ring in RING_COUNT:
		var pivot := Node3D.new()
		add_child(pivot)
		_rings.append(pivot)
		_tweens.append(null)
		var inner := INNER_RADIUS + ring * RING_WIDTH
		var top := ring_top(ring)
		# Chaque cercle est un disque plein posé sur le socle : le suivant, plus large et plus bas, le borde.
		var band := CylinderMesh.new()
		band.top_radius = inner + RING_WIDTH - 0.04
		band.bottom_radius = band.top_radius
		band.height = top - PLINTH_HEIGHT
		band.radial_segments = 48
		band.material = stone if ring % 2 == 0 else groove
		var disc := MeshInstance3D.new()
		disc.mesh = band
		disc.position.y = PLINTH_HEIGHT + band.height * 0.5
		pivot.add_child(disc)
		# Les 26 lettres d'un cercle forment un seul maillage gravé (et non 26 textes) : un appel de dessin par cercle
		# au lieu de vingt-six.
		var tool := SurfaceTool.new()
		var size := (LETTER_PIXEL + ring * LETTER_PIXEL_STEP) / LETTER_PIXEL
		for index in LETTERS.length():
			var angle := -index * TAU / LETTERS.length()
			var radius := inner + RING_WIDTH * 0.5
			# Gravée à 1 cm au-dessus de la pierre, couchée sur le cercle.
			var place := Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0.0, -angle)).scaled(Vector3.ONE * size),
				Vector3(sin(angle) * -radius, top + 0.01, cos(angle) * -radius))
			tool.append_from(glyphs[index], 0, place)
		var engraved := MeshInstance3D.new()
		engraved.name = "Letters"
		engraved.mesh = tool.commit()
		engraved.mesh.surface_set_material(0, _letter_material)
		engraved.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(engraved)
	# Repère fixe gravé dans le socle, au nord du mécanisme : un triangle doré couché, pointé vers le centre.
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.5, 0.45, 0.04)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.9, 0.75, 0.3)
	gold.emission_enabled = true
	gold.emission = Color(0.9, 0.7, 0.25)
	gold.emission_energy_multiplier = 0.6
	arrow.material = gold
	var marker := MeshInstance3D.new()
	marker.mesh = arrow
	marker.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	marker.position = Vector3(0.0, PLINTH_HEIGHT + 0.02, -(INNER_RADIUS + RING_COUNT * RING_WIDTH + 0.25))
	add_child(marker)
	var center := CylinderMesh.new()
	center.top_radius = INNER_RADIUS - 0.05
	center.bottom_radius = INNER_RADIUS
	center.height = ring_top(0) + 0.05 - PLINTH_HEIGHT
	center.material = stone
	var hub := MeshInstance3D.new()
	hub.mesh = center
	hub.position.y = PLINTH_HEIGHT + center.height * 0.5
	add_child(hub)
	# On marche sur le mécanisme comme sur une estrade : sa collision est un cône tronqué très bas, dont le dessus
	# couvre les cercles et dont la pente douce monte du sol au bord du socle, sans marche qui arrête le pas.
	if not Engine.is_editor_hint():
		var points := PackedVector3Array()
		var top_radius := INNER_RADIUS + RING_COUNT * RING_WIDTH - 0.06
		for step in 24:
			var angle := TAU * step / 24.0
			points.append(Vector3(cos(angle) * (PLINTH_RADIUS + 0.05), 0.0, sin(angle) * (PLINTH_RADIUS + 0.05)))
			points.append(Vector3(cos(angle) * top_radius, ring_top(0) + 0.015, sin(angle) * top_radius))
		var cone := ConvexPolygonShape3D.new()
		cone.points = points
		var shape := CollisionShape3D.new()
		shape.shape = cone
		var body := StaticBody3D.new()
		body.add_child(shape)
		add_child(body)
