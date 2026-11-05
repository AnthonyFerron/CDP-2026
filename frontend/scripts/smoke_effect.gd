@tool
class_name SmokeEffect
extends CPUParticles3D
## Colonne de fumée qui monte lentement et s'étale, pour un feu qui couve ou un toit qui brûle.

@export var radius := 1.0
@export var puff_size := 4.0
@export var rise_speed := 1.4
@export var smoke_color := Color(0.3, 0.27, 0.27)


func _ready() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(smoke_color, 0.0))
	gradient.set_color(1, Color(smoke_color.lightened(0.15), 0.0))
	gradient.add_point(0.2, Color(smoke_color, 0.42))
	var texture := GradientTexture2D.new()
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	falloff.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	texture.gradient = falloff
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * puff_size
	quad.material = material

	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.5))
	growth.add_point(Vector2(1.0, 1.6))

	mesh = quad
	amount = 14
	lifetime = 11.0
	preprocess = 11.0
	emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = radius
	direction = Vector3.UP
	spread = 10.0
	gravity = Vector3(0.35, 0.0, 0.1)
	initial_velocity_min = rise_speed * 0.7
	initial_velocity_max = rise_speed * 1.3
	scale_amount_curve = growth
	color_ramp = gradient
	# Ces réglages arrivent après le démarrage de l'émission : sans relance, le préchauffage (preprocess) ne
	# s'applique pas à une fumée chargée avec une scène (Village, volcan du hub), qui fait alors une boule sombre au
	# pied du feu pendant ses dix premières secondes. Relancée une fois dans l'arbre, elle monte tout de suite.
	restart.call_deferred()
