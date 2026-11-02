class_name Player
extends CharacterBody3D
## Personnage à la troisième personne : déplacement relatif à la caméra, sprint et saut.

@export_group("Déplacement")
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var acceleration := 40.0
@export var jump_velocity := 5.5
@export var turn_speed := 12.0
## Sous cette hauteur, le personnage revient à son point de départ.
@export var respawn_height := -20.0

@export_group("Caméra")
@export var mouse_sensitivity := 0.003
@export_range(-89.0, 0.0) var pitch_min_degrees := -70.0
@export_range(0.0, 89.0) var pitch_max_degrees := 40.0

var _spawn_position: Vector3

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _visual: Node3D = $Visual


func _ready() -> void:
	_spawn_position = global_position
	_spring_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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

	if direction != Vector3.ZERO:
		var target_yaw := atan2(-direction.x, -direction.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, turn_speed * delta)


func _rotate_camera(mouse_delta: Vector2) -> void:
	_camera_pivot.rotation.y -= mouse_delta.x * mouse_sensitivity
	_camera_pivot.rotation.x = clampf(
		_camera_pivot.rotation.x - mouse_delta.y * mouse_sensitivity,
		deg_to_rad(pitch_min_degrees),
		deg_to_rad(pitch_max_degrees)
	)
