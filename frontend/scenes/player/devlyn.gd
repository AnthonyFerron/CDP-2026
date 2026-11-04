class_name Devlyn
extends Node3D
## Marche de Devlyn : les jambes et les bras balancent en opposition, au rythme de ses pas, et le haut du corps
## rebondit légèrement. En vue à la première personne, on ne voit que son ombre au sol : elle marche avec lui.
## Le modèle est généré par tools/build_devlyn.py.

## Distance parcourue à chaque pas, comme les bruits de pas du joueur.
@export var stride_length := 1.9
## Vitesse à laquelle le balancement atteint son amplitude complète.
@export var full_swing_speed := 5.0
@export var leg_swing_degrees := 34.0
@export var arm_swing_degrees := 28.0
@export var bob_height := 0.04

var _phase := 0.0
var _amount := 0.0
var _upper_rest := 0.0

@onready var _hip_left: Node3D = $HipLeft
@onready var _hip_right: Node3D = $HipRight
@onready var _upper: Node3D = $Upper
@onready var _arm_left: Node3D = $Upper/ShoulderJointLeft
@onready var _arm_right: Node3D = $Upper/ShoulderJointRight


func _ready() -> void:
	_upper_rest = _upper.position.y


## À appeler à chaque image physique avec la vitesse au sol du personnage.
func animate(speed: float, on_floor: bool, delta: float) -> void:
	var target := clampf(speed / full_swing_speed, 0.0, 1.0) if on_floor else 0.0
	_amount = move_toward(_amount, target, delta * 5.0)
	# Un demi-tour de cycle par pas : chaque jambe se pose une fois tous les deux pas.
	_phase = fmod(_phase + speed * delta / stride_length * PI, TAU)
	if _amount <= 0.0:
		_phase = 0.0
	var swing := sin(_phase) * _amount
	_hip_left.rotation.x = deg_to_rad(leg_swing_degrees) * swing
	_hip_right.rotation.x = -deg_to_rad(leg_swing_degrees) * swing
	_arm_left.rotation.x = -deg_to_rad(arm_swing_degrees) * swing
	_arm_right.rotation.x = deg_to_rad(arm_swing_degrees) * swing
	# Le corps est au plus haut quand les jambes se croisent, au plus bas quand un pied se pose.
	_upper.position.y = _upper_rest + absf(cos(_phase)) * bob_height * _amount
