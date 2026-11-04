class_name Player
extends CharacterBody3D
## Personnage jouable : déplacement relatif à la caméra, sprint, saut et bruits de pas.
## La caméra est à la troisième personne, ou à la première avec first_person.

@export_group("Déplacement")
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var acceleration := 40.0
@export var jump_velocity := 5.5
@export var turn_speed := 12.0
## Sous cette hauteur, le personnage revient à son point de départ.
@export var respawn_height := -20.0

@export_group("Caméra")
@export var first_person := false
## Hauteur des yeux en vue à la première personne.
@export var eye_height := 1.65
@export var mouse_sensitivity := 0.003
## Vitesse de rotation aux flèches du clavier, en radians par seconde : le regard reste possible
## quand le navigateur refuse de capturer la souris.
@export var key_turn_speed := 2.2
@export_range(-89.0, 0.0) var pitch_min_degrees := -70.0
@export_range(0.0, 89.0) var pitch_max_degrees := 40.0

@export_group("Sons")
@export var footstep_sounds: Array[AudioStream]
## Distance parcourue entre deux pas, en marchant.
@export var stride_length := 1.9
@export var footstep_volume_db := -13.0

## Place du livre tenu en main, dans le repère de la caméra : en bas à droite de la vue.
const HELD_BOOK_POSITION := Vector3(0.36, -0.3, -0.78)
const HELD_BOOK_ROTATION := Vector3(deg_to_rad(28.0), deg_to_rad(-38.0), deg_to_rad(-12.0))
const HELD_BOOK_SCALE := 0.28
## Durée du vol d'un livre entre la main et le monde.
const BOOK_FLIGHT := 1.1

## Multiplie la vitesse, par exemple pour ralentir le joueur dans l'eau.
var speed_multiplier := 1.0
var _held_book: Node3D
var _bob := 0.0
var _spawn_position: Vector3
var _stride := 0.0
var _footsteps: AudioStreamPlayer

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _visual: Node3D = $Visual
@onready var _devlyn: Devlyn = $Visual/Devlyn


func _ready() -> void:
	_spawn_position = global_position
	_spring_arm.add_excluded_object(get_rid())
	if first_person:
		_use_first_person()
	if not footstep_sounds.is_empty():
		_footsteps = AudioStreamPlayer.new()
		_footsteps.volume_db = footstep_volume_db
		add_child(_footsteps)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if first_person:
		_held_book = Node3D.new()
		_held_book.position = HELD_BOOK_POSITION
		_held_book.rotation = HELD_BOOK_ROTATION
		_held_book.visible = false
		_spring_arm.get_node("Camera3D").add_child(_held_book)
		var carried := GameState.carried_books()
		if not carried.is_empty():
			_hold(carried.back())


func _use_first_person() -> void:
	_camera_pivot.position.y = eye_height
	_spring_arm.spring_length = 0.0
	_spring_arm.rotation = Vector3.ZERO
	pitch_min_degrees = -85.0
	pitch_max_degrees = 85.0
	var camera: Camera3D = _spring_arm.get_node("Camera3D")
	camera.near = 0.05
	# Le corps ne se voit plus, mais garde son ombre au sol.
	for mesh: GeometryInstance3D in _visual.find_children("*", "GeometryInstance3D"):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _unhandled_input(event: InputEvent) -> void:
	# Échap ouvre le menu pause (PauseMenu), qui libère la souris.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion:
		_rotate_camera(event.relative)


func _physics_process(delta: float) -> void:
	if global_position.y < respawn_height:
		global_position = _spawn_position
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var look := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if look != Vector2.ZERO:
		_rotate_camera(look * key_turn_speed * delta / mouse_sensitivity)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, _camera_pivot.rotation.y)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	speed *= speed_multiplier
	var target_velocity := direction * speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	move_and_slide()
	_update_footsteps(delta)
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	_devlyn.animate(ground_speed, is_on_floor(), delta)

	if first_person:
		# Le corps, invisible mais dont l'ombre marche au sol, se tourne vers où il avance, et vers le regard à l'arrêt.
		var body_yaw := _camera_pivot.rotation.y
		if ground_speed > 0.5:
			body_yaw = atan2(-velocity.x, -velocity.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, body_yaw, turn_speed * delta)
	elif direction != Vector3.ZERO:
		var target_yaw := atan2(-direction.x, -direction.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, turn_speed * delta)


func _process(delta: float) -> void:
	if not _held_book or not _held_book.visible:
		return
	# Le livre se balance un peu au rythme des pas.
	var speed := Vector2(velocity.x, velocity.z).length()
	_bob += delta * (2.0 + speed * 1.6)
	var swing := minf(speed / walk_speed, 1.0)
	_held_book.position = HELD_BOOK_POSITION + Vector3(cos(_bob * 0.5) * 0.008 * swing, sin(_bob) * (0.004 + 0.012 * swing), 0.0)


## Le livre ramassé vole jusqu'à la main du joueur, en tournant, puis reste visible en bas de la vue.
func receive_book(book_id: StringName, from: Vector3) -> void:
	if not _held_book:
		return
	_held_book.visible = false
	var flying := _book_model(book_id, true)
	flying.top_level = true
	add_child(flying)
	flying.global_position = from
	var tween := create_tween()
	tween.tween_method(_fly.bind(flying, from, true), 0.0, 1.0, BOOK_FLIGHT)
	tween.tween_callback(flying.queue_free)
	tween.tween_callback(_hold.bind(book_id))
	await tween.finished


## Le livre quitte la main et vole jusqu'au point donné, par exemple son piédestal.
func give_book(book_id: StringName, to: Vector3) -> void:
	if not _held_book:
		return
	var start := _held_book.global_position
	_held_book.visible = false
	var flying := _book_model(book_id, true)
	flying.top_level = true
	add_child(flying)
	flying.global_position = start
	var tween := create_tween()
	tween.tween_method(_fly_to.bind(flying, start, to), 0.0, 1.0, BOOK_FLIGHT * 0.8)
	tween.tween_callback(flying.queue_free)
	await tween.finished


func _fly(t: float, flying: Node3D, from: Vector3, _to_hand: bool) -> void:
	var eased := ease(t, -1.8)
	var target := _held_book.global_position
	flying.global_position = from.lerp(target, eased) + Vector3.UP * sin(t * PI) * 0.9
	flying.rotation = Vector3(t * TAU * 0.5, t * TAU * 1.5, 0.0)
	flying.scale = Vector3.ONE * lerpf(1.0, HELD_BOOK_SCALE, eased)


func _fly_to(t: float, flying: Node3D, from: Vector3, to: Vector3) -> void:
	var eased := ease(t, -1.8)
	flying.global_position = from.lerp(to, eased) + Vector3.UP * sin(t * PI) * 0.6
	flying.rotation = Vector3(0.0, t * TAU, 0.0)
	flying.scale = Vector3.ONE * lerpf(HELD_BOOK_SCALE, 1.0, eased)


## Montre le livre en main, avec un petit rebond à son arrivée.
func _hold(book_id: StringName) -> void:
	for child in _held_book.get_children():
		child.queue_free()
	_held_book.add_child(_book_model(book_id, false))
	_held_book.visible = true
	_held_book.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_held_book, "scale", Vector3.ONE * HELD_BOOK_SCALE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Cache le livre en main : il vient d'être posé.
func drop_held_book() -> void:
	if _held_book:
		_held_book.visible = false


## Un livre ancien : couverture à la couleur du livre, tranche de pages claire, et une lueur s'il vole.
func _book_model(book_id: StringName, glowing: bool) -> Node3D:
	var color: Color = GameState.BOOK_COLORS.get(book_id, Color(0.4, 0.2, 0.1))
	var book := Node3D.new()
	var cover_material := StandardMaterial3D.new()
	cover_material.albedo_color = color
	cover_material.emission_enabled = true
	cover_material.emission = color
	cover_material.emission_energy_multiplier = 1.5 if glowing else 0.12
	var cover := MeshInstance3D.new()
	var cover_mesh := BoxMesh.new()
	cover_mesh.size = Vector3(0.55, 0.14, 0.75)
	cover_mesh.material = cover_material
	cover.mesh = cover_mesh
	book.add_child(cover)
	var pages_material := StandardMaterial3D.new()
	pages_material.albedo_color = Color(0.93, 0.88, 0.74)
	var pages := MeshInstance3D.new()
	var pages_mesh := BoxMesh.new()
	pages_mesh.size = Vector3(0.52, 0.1, 0.7)
	pages_mesh.material = pages_material
	pages.mesh = pages_mesh
	pages.position.x = 0.025
	book.add_child(pages)
	var clasp_material := StandardMaterial3D.new()
	clasp_material.albedo_color = Color(0.9, 0.72, 0.3)
	clasp_material.metallic = 0.7
	var clasp := MeshInstance3D.new()
	var clasp_mesh := BoxMesh.new()
	clasp_mesh.size = Vector3(0.08, 0.16, 0.2)
	clasp_mesh.material = clasp_material
	clasp.mesh = clasp_mesh
	clasp.position.x = 0.28
	book.add_child(clasp)
	if glowing:
		var light := OmniLight3D.new()
		light.light_color = color.lightened(0.5)
		light.light_energy = 2.0
		light.omni_range = 3.0
		book.add_child(light)
	return book


func _update_footsteps(delta: float) -> void:
	if not _footsteps or not is_on_floor():
		return
	_stride += Vector2(velocity.x, velocity.z).length() * delta
	if _stride >= stride_length:
		_stride = 0.0
		_footsteps.stream = footstep_sounds.pick_random()
		# Légères variations d'un pas à l'autre : la marche sonne naturelle, sans répétition mécanique.
		_footsteps.pitch_scale = randf_range(0.94, 1.06)
		_footsteps.volume_db = footstep_volume_db + randf_range(-1.5, 0.5)
		_footsteps.play()


func _rotate_camera(mouse_delta: Vector2) -> void:
	_camera_pivot.rotation.y -= mouse_delta.x * mouse_sensitivity
	_camera_pivot.rotation.x = clampf(
		_camera_pivot.rotation.x - mouse_delta.y * mouse_sensitivity,
		deg_to_rad(pitch_min_degrees),
		deg_to_rad(pitch_max_degrees)
	)
