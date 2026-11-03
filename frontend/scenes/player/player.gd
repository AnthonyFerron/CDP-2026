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
@export_range(-89.0, 0.0) var pitch_min_degrees := -70.0
@export_range(0.0, 89.0) var pitch_max_degrees := 40.0

@export_group("Sons")
@export var footstep_sounds: Array[AudioStream]
## Distance parcourue entre deux pas, en marchant.
@export var stride_length := 1.9
@export var footstep_volume_db := -6.0

var _spawn_position: Vector3
var _stride := 0.0
var _footsteps: AudioStreamPlayer

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _visual: Node3D = $Visual


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
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, _camera_pivot.rotation.y)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := direction * speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	move_and_slide()
	_update_footsteps(delta)

	if first_person:
		_visual.rotation.y = _camera_pivot.rotation.y
	elif direction != Vector3.ZERO:
		var target_yaw := atan2(-direction.x, -direction.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, turn_speed * delta)


func _update_footsteps(delta: float) -> void:
	if not _footsteps or not is_on_floor():
		return
	_stride += Vector2(velocity.x, velocity.z).length() * delta
	if _stride >= stride_length:
		_stride = 0.0
		_footsteps.stream = footstep_sounds.pick_random()
		_footsteps.pitch_scale = randf_range(0.9, 1.1)
		_footsteps.play()


func _rotate_camera(mouse_delta: Vector2) -> void:
	_camera_pivot.rotation.y -= mouse_delta.x * mouse_sensitivity
	_camera_pivot.rotation.x = clampf(
		_camera_pivot.rotation.x - mouse_delta.y * mouse_sensitivity,
		deg_to_rad(pitch_min_degrees),
		deg_to_rad(pitch_max_degrees)
	)
