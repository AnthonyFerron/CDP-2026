extends Node3D
## Fait tourner son nœud autour de son axe X local : la roue du moulin, qui ne tourne que reconstruite
## (cachée, sa version en ruine ne traite plus rien).

## Vitesse de rotation, en radians par seconde.
@export var speed := 0.7


func _process(delta: float) -> void:
	rotate_object_local(Vector3.RIGHT, speed * delta)
