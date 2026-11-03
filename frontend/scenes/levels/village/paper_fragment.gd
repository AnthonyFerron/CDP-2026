class_name PaperFragment
extends Interactable
## Fragment de papier laissé dans la mairie : un indice pour l'un des cinq codes. Le joueur le ramasse avec E.

@export var fragment: int = 0
## Un fragment rangé dans un tiroir ou une armoire n'apparaît qu'une fois le meuble ouvert.
@export var hidden_at_start := false

var collected := false


func _ready() -> void:
	super._ready()
	prompt = "Ramasser le fragment de papier"
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.93, 0.88, 0.74)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.92, 0.7)
	material.emission_energy_multiplier = 0.35
	var sheet := BoxMesh.new()
	sheet.size = Vector3(0.32, 0.01, 0.42)
	sheet.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = sheet
	mesh.position.y = 0.01
	mesh.rotation.y = 0.35
	add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.6)
	light.light_energy = 0.35
	light.omni_range = 1.2
	light.position.y = 0.25
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
