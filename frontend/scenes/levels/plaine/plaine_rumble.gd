class_name PlaineRumble
extends Node3D
## Le Mont Sam Altan gronde. Peu après l'arrivée dans la Plaine, puis de loin en loin, de plus en plus souvent à mesure
## que l'heure s'écoule, le volcan crache un panache de cendre et des projections incandescentes, la lueur de son
## cratère s'embrase et le brouillard de la plaine rougit un instant. Le grondement arrive un peu après l'éclat, comme
## de loin, et les corbeaux s'envolent. Le nœud est posé au bord du cratère du volcan de l'horizon (Exterior/Volcano).
## Dehors seulement, sans lumière dynamique ni secousse de la caméra : la secousse reste le signal d'une erreur à la
## tablette. Les particules et la lueur restent cachées entre deux grondements : elles ne coûtent rien au repos.

## Corbeaux à effaroucher, et environnement du lieu dont le brouillard rougit.
@export var life: PlaineLife
@export var world: WorldEnvironment
@export var sound: AudioStream
@export var volume_db := -14.0
## Le son de l'éruption, plus grave et plus lent : un grondement lointain plutôt qu'une explosion.
@export var pitch := 0.6
## Premier grondement, en secondes après le dévoilement du lieu, puis intervalles tirés entre ces bornes : au début de
## la partie, et quand il ne reste presque plus de temps.
@export var first_delay := 4.0
@export var calm_interval := Vector2(80.0, 110.0)
@export var urgent_interval := Vector2(35.0, 50.0)

## Durée de l'embrasement, et retard du son sur l'éclat (le volcan est à près de 300 m).
const FLARE_TIME := 6.5
const SOUND_DELAY := 0.9
## Couleur du brouillard au plus fort de l'embrasement, et part de ce mélange.
const FOG_FLARE := Color(0.62, 0.3, 0.24)
const FOG_MIX := 0.45
const ASH_LIFETIME := 11.0
const EJECTA_LIFETIME := 4.0

var _rng := RandomNumberGenerator.new()
var _wait := 0.0
## Temps écoulé depuis le début du grondement en cours ; négatif au repos.
var _elapsed := -1.0
var _sounded := false
var _fog_base := Color()
var _ash: CPUParticles3D
var _ejecta: CPUParticles3D
var _flare: MeshInstance3D
var _flare_material: StandardMaterial3D
var _player: AudioStreamPlayer


func _ready() -> void:
	_rng.randomize()
	_wait = first_delay
	if world:
		_fog_base = world.environment.fog_light_color
	var soft := _soft_texture()
	_ash = _create_ash(soft)
	add_child(_ash)
	_ejecta = _create_ejecta(soft)
	add_child(_ejecta)
	_flare = _create_flare(soft)
	add_child(_flare)
	_player = AudioStreamPlayer.new()
	_player.stream = sound
	_player.volume_db = volume_db
	_player.pitch_scale = pitch
	add_child(_player)


func _exit_tree() -> void:
	# L'environnement vient de la scène et sert à la visite suivante : il repart avec son brouillard d'origine.
	if world:
		world.environment.fog_light_color = _fog_base


func _process(delta: float) -> void:
	if _elapsed >= 0.0:
		_update(delta)
	if GameState.has_erupted or not is_visible_in_tree() or Transition.is_busy():
		return
	_wait -= delta
	if _wait <= 0.0:
		rumble()


## Lance un grondement tout de suite (le prochain est tiré à nouveau).
func rumble() -> void:
	_elapsed = 0.0
	_sounded = false
	for particles: CPUParticles3D in [_ash, _ejecta]:
		particles.visible = true
		particles.restart()
	_flare.visible = true
	# Plus l'heure tourne, plus le volcan s'impatiente.
	var urgency := 1.0 - clampf(GameState.time_left / GameState.TOTAL_TIME, 0.0, 1.0)
	var low := lerpf(calm_interval.x, urgent_interval.x, urgency)
	var high := lerpf(calm_interval.y, urgent_interval.y, urgency)
	_wait = _rng.randf_range(low, high)


func _update(delta: float) -> void:
	_elapsed += delta
	# L'éclat monte en une demi-seconde, puis retombe lentement.
	var glow := smoothstep(0.0, 0.5, _elapsed) * (1.0 - smoothstep(0.9, FLARE_TIME, _elapsed))
	_flare_material.albedo_color.a = glow
	if world:
		world.environment.fog_light_color = _fog_base.lerp(FOG_FLARE, glow * FOG_MIX)
	if not _sounded and _elapsed >= SOUND_DELAY:
		_sounded = true
		if sound and is_visible_in_tree():
			_player.play()
		if life:
			life.startle()
	if _elapsed > ASH_LIFETIME:
		_elapsed = -1.0
		_ash.visible = false
		_ejecta.visible = false
		_flare.visible = false
		if world:
			world.environment.fog_light_color = _fog_base


## Tache ronde et douce, pour les bouffées de cendre, les projections et la lueur.
func _soft_texture() -> GradientTexture2D:
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	falloff.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = falloff
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


## Panache de cendre : de grosses bouffées sombres, rougies par la lave au départ, qui montent vite, ralentissent,
## s'étalent et dérivent avec le vent. Le brouillard du lieu les effacerait à cette distance : elles l'ignorent, comme
## le volcan.
func _create_ash(texture: Texture2D) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	material.disable_fog = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 30.0
	quad.material = material
	var colors := Gradient.new()
	colors.set_color(0, Color(0.55, 0.22, 0.12, 0.0))
	colors.set_color(1, Color(0.2, 0.18, 0.18, 0.0))
	colors.add_point(0.08, Color(0.5, 0.22, 0.13, 0.9))
	colors.add_point(0.3, Color(0.24, 0.2, 0.2, 0.8))
	colors.add_point(0.7, Color(0.22, 0.19, 0.19, 0.45))
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.35))
	growth.add_point(Vector2(1.0, 1.9))
	var ash := CPUParticles3D.new()
	ash.name = "Ash"
	ash.mesh = quad
	ash.amount = 22
	ash.lifetime = ASH_LIFETIME
	ash.one_shot = true
	ash.explosiveness = 0.55
	ash.emitting = false
	ash.visible = false
	# Ombre laissée comme celle de la fumée du volcan, au même endroit : à près de 300 m, bien au-delà de la portée des
	# ombres du soleil (50 m), elle n'est jamais dessinée, et le matériau reste celui de cette fumée dans l'inventaire
	# des shaders préparés au menu (un programme de moins à compiler).
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ash.emission_sphere_radius = 6.0
	ash.direction = Vector3.UP
	ash.spread = 18.0
	ash.initial_velocity_min = 16.0
	ash.initial_velocity_max = 26.0
	ash.damping_min = 2.0
	ash.damping_max = 3.0
	ash.gravity = Vector3(2.2, 0.4, 0.6)
	ash.scale_amount_curve = growth
	ash.color_ramp = colors
	return ash


## Projections incandescentes : des éclats lancés haut au-dessus du cratère, qui retombent en rougissant.
func _create_ejecta(texture: Texture2D) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	material.disable_fog = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 4.0
	quad.material = material
	var colors := Gradient.new()
	colors.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
	colors.set_color(1, Color(0.7, 0.12, 0.03, 0.0))
	colors.add_point(0.45, Color(1.0, 0.5, 0.12, 0.95))
	var ejecta := CPUParticles3D.new()
	ejecta.name = "Ejecta"
	ejecta.mesh = quad
	ejecta.amount = 40
	ejecta.lifetime = EJECTA_LIFETIME
	ejecta.one_shot = true
	ejecta.explosiveness = 0.8
	ejecta.emitting = false
	ejecta.visible = false
	ejecta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ejecta.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ejecta.emission_sphere_radius = 5.0
	ejecta.direction = Vector3.UP
	ejecta.spread = 30.0
	ejecta.initial_velocity_min = 26.0
	ejecta.initial_velocity_max = 44.0
	ejecta.gravity = Vector3(0.0, -22.0, 0.0)
	ejecta.scale_amount_min = 0.6
	ejecta.scale_amount_max = 1.4
	ejecta.color_ramp = colors
	return ejecta


## Embrasement du cratère : un grand halo orangé, additif et tourné vers la caméra, par-dessus la lueur du volcan.
func _create_flare(texture: Texture2D) -> MeshInstance3D:
	_flare_material = StandardMaterial3D.new()
	_flare_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flare_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flare_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flare_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_flare_material.disable_fog = true
	_flare_material.albedo_texture = texture
	_flare_material.albedo_color = Color(1.0, 0.42, 0.12, 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(80.0, 52.0)
	quad.material = _flare_material
	var flare := MeshInstance3D.new()
	flare.name = "Flare"
	flare.mesh = quad
	flare.position.y = 3.0
	flare.visible = false
	flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return flare
