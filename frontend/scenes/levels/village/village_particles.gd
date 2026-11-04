@tool
class_name VillageParticles
extends CPUParticles3D
## Particules d'ambiance du Village : braises qui montent des feux et des cratères en tourbillonnant, ou poussière qui
## flotte dans la lumière de la mairie. Tout est réglé ici : la scène ne garde que le genre et la taille de la zone.

enum Kind { EMBERS, DUST }

@export var kind := Kind.EMBERS
## Demi-dimensions de la zone d'émission.
@export var extents := Vector3(0.6, 0.2, 0.6)
@export var tint := Color(1.0, 0.5, 0.15)


func _ready() -> void:
	var dot := GradientTexture2D.new()
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1, 1, 1, 1))
	falloff.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = falloff
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.width = 32
	dot.height = 32
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = dot
	var quad := QuadMesh.new()
	quad.material = material
	mesh = quad
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = extents
	var fade := Gradient.new()
	if kind == Kind.EMBERS:
		quad.size = Vector2.ONE * 0.07
		amount = 14
		lifetime = 2.6
		preprocess = 3.0
		direction = Vector3.UP
		spread = 25.0
		gravity = Vector3(0.25, 0.6, 0.1)
		initial_velocity_min = 0.6
		initial_velocity_max = 1.6
		angular_velocity_min = -90.0
		angular_velocity_max = 90.0
		tangential_accel_min = -0.6
		tangential_accel_max = 0.6
		fade.set_color(0, Color(tint.lightened(0.3), 1.0))
		fade.set_color(1, Color(tint.darkened(0.4), 0.0))
		fade.add_point(0.6, Color(tint, 0.85))
	else:
		quad.size = Vector2.ONE * 0.045
		amount = 70
		lifetime = 14.0
		preprocess = 14.0
		direction = Vector3(1, 0.2, 0.3)
		spread = 180.0
		gravity = Vector3(0.0, -0.01, 0.0)
		initial_velocity_min = 0.02
		initial_velocity_max = 0.08
		fade.set_color(0, Color(tint, 0.0))
		fade.set_color(1, Color(tint, 0.0))
		fade.add_point(0.3, Color(tint, 0.45))
		fade.add_point(0.7, Color(tint, 0.4))
	color_ramp = fade
