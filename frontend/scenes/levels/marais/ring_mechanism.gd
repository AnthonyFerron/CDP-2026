@tool
class_name RingMechanism
extends Node3D
## Mécanisme circulaire posé au sol : cinq cercles concentriques gravés des 26 lettres, qui pivotent
## chacun sur eux-mêmes. Un repère fixe, au nord, désigne la lettre choisie sur chaque cercle.

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const RING_COUNT := 5
const INNER_RADIUS := 0.9
const RING_WIDTH := 0.5

@export var stone_color := Color(0.32, 0.3, 0.3)
@export var letter_color := Color(0.85, 0.8, 0.7)

## Lettre désignée par le repère sur chaque cercle, de l'intérieur vers l'extérieur.
var letters: Array[int] = []

var _rings: Array[Node3D] = []
var _tweens: Array[Tween] = []
var _letter_material: StandardMaterial3D


func _ready() -> void:
	letters.resize(RING_COUNT)
	letters.fill(0)
	_letter_material = StandardMaterial3D.new()
	_letter_material.albedo_color = letter_color
	_letter_material.emission_enabled = true
	_letter_material.emission = letter_color
	_letter_material.emission_energy_multiplier = 0.2
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


func set_glow(color: Color, energy: float) -> void:
	_letter_material.emission = color
	_letter_material.emission_energy_multiplier = energy


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
	for ring in RING_COUNT:
		var pivot := Node3D.new()
		add_child(pivot)
		_rings.append(pivot)
		_tweens.append(null)
		var inner := INNER_RADIUS + ring * RING_WIDTH
		var band := CylinderMesh.new()
		band.top_radius = inner + RING_WIDTH - 0.04
		band.bottom_radius = band.top_radius
		band.height = 0.12 + ring * 0.02
		band.radial_segments = 48
		band.material = stone if ring % 2 == 0 else groove
		var disc := MeshInstance3D.new()
		disc.mesh = band
		disc.position.y = band.height * 0.5
		# Le disque d'un cercle intérieur dépasse un peu au-dessus de celui qui l'entoure.
		disc.position.y += (RING_COUNT - ring) * 0.02
		pivot.add_child(disc)
		for index in LETTERS.length():
			var angle := -index * TAU / LETTERS.length()
			var label := Label3D.new()
			label.text = LETTERS[index]
			label.font_size = 64
			label.pixel_size = 0.0035 + ring * 0.0004
			label.modulate = letter_color
			label.outline_size = 6
			var radius := inner + RING_WIDTH * 0.5
			label.position = Vector3(sin(angle) * -radius, 0.2 + (RING_COUNT - ring) * 0.02, cos(angle) * -radius)
			label.rotation = Vector3(-PI * 0.5, 0.0, -angle)
			pivot.add_child(label)
	# Repère fixe gravé dans la pierre, au nord du mécanisme.
	var marker := Label3D.new()
	marker.text = "▼"
	marker.font_size = 96
	marker.pixel_size = 0.006
	marker.modulate = Color(0.9, 0.75, 0.3)
	marker.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	marker.position = Vector3(0.0, 0.32, -(INNER_RADIUS + RING_COUNT * RING_WIDTH + 0.3))
	add_child(marker)
	var center := CylinderMesh.new()
	center.top_radius = INNER_RADIUS - 0.05
	center.bottom_radius = INNER_RADIUS
	center.height = 0.3
	center.material = stone
	var hub := MeshInstance3D.new()
	hub.mesh = center
	hub.position.y = 0.15
	add_child(hub)
