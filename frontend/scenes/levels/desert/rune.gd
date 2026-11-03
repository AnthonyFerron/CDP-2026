class_name Rune
extends Interactable
## Rune d'instruction, posée dans les ruines ou cachée sous le sable. Le joueur la ramasse avec E.

@export var rune_id: StringName
## Une rune cachée sous un tas de sable n'apparaît qu'une fois le tas dégagé.
@export var hidden_at_start := false

var collected := false


func _ready() -> void:
	super._ready()
	prompt = "Ramasser la rune"
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.32, 0.3)
	material.emission_enabled = true
	material.emission = Color(0.35, 0.65, 1.0)
	material.emission_energy_multiplier = 1.2
	var slab := BoxMesh.new()
	slab.size = Vector3(0.45, 0.08, 0.35)
	slab.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = slab
	mesh.position.y = 0.05
	add_child(mesh)
	var glyph := Label3D.new()
	glyph.text = "◆"
	glyph.pixel_size = 0.004
	glyph.font_size = 64
	glyph.modulate = Color(0.6, 0.85, 1.0)
	glyph.rotation.x = -PI * 0.5
	glyph.position.y = 0.1
	add_child(glyph)
	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 0.7, 1.0)
	light.light_energy = 0.6
	light.omni_range = 1.6
	light.position.y = 0.3
	add_child(light)
	if hidden_at_start:
		visible = false
		enabled = false


func reveal() -> void:
	visible = true
	enabled = true


func collect() -> void:
	collected = true
	visible = false
	enabled = false
