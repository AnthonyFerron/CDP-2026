class_name SandPile
extends Interactable
## Tas de sable à dégager en maintenant la touche d'interaction. Il fond peu à peu ; relâcher la touche
## interrompt le balayage sans perdre la progression. Certains tas cachent une rune.

signal cleared(had_rune: bool)

## Rune cachée sous ce tas, ou vide si le tas ne cache rien.
@export var rune: NodePath
## Secondes de balayage pour dégager entièrement le tas.
@export var duration := 2.0
@export var pile_radius := 0.9
@export var pile_height := 0.7

var progress := 0.0
var is_cleared := false

var _pile: MeshInstance3D
var _dust: CPUParticles3D


func _ready() -> void:
	super._ready()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.62, 0.38)
	material.roughness = 1.0
	var cone := CylinderMesh.new()
	cone.top_radius = pile_radius * 0.2
	cone.bottom_radius = pile_radius
	cone.height = pile_height
	cone.radial_segments = 10
	cone.material = material
	_pile = MeshInstance3D.new()
	_pile.mesh = cone
	add_child(_pile)
	_dust = _create_dust()
	add_child(_dust)
	_refresh()


func _physics_process(delta: float) -> void:
	if is_cleared or not enabled:
		return
	var sweeping := focused and Input.is_action_pressed("interact")
	_dust.emitting = sweeping
	if not sweeping:
		return
	progress = minf(progress + delta / duration, 1.0)
	_refresh()
	if progress >= 1.0:
		_finish()


func _refresh() -> void:
	var remaining := 1.0 - progress * 0.95
	_pile.scale = Vector3(1.0 + progress * 0.3, remaining, 1.0 + progress * 0.3)
	_pile.position.y = pile_height * remaining * 0.5
	prompt = "Maintenir pour dégager le sable" if progress <= 0.0 else "Maintenir pour dégager le sable (%d %%)" % int(progress * 100.0)


func _finish() -> void:
	is_cleared = true
	enabled = false
	_dust.emitting = false
	_pile.hide()
	var hidden := get_node_or_null(rune) as Rune
	if hidden:
		hidden.reveal()
	cleared.emit(hidden != null)


func _create_dust() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.25, 0.25)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.9, 0.75, 0.5, 0.7))
	gradient.set_color(1, Color(0.9, 0.75, 0.5, 0.0))
	var dust := CPUParticles3D.new()
	dust.mesh = quad
	dust.emitting = false
	dust.amount = 24
	dust.lifetime = 0.8
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = pile_radius * 0.6
	dust.position.y = pile_height * 0.5
	dust.direction = Vector3.UP
	dust.spread = 70.0
	dust.gravity = Vector3(0.0, -2.0, 0.0)
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 2.5
	dust.color_ramp = gradient
	return dust
