class_name Interactable
extends Node3D
## Point d'interaction : le joueur qui s'en approche peut l'activer avec la touche d'interaction.

signal interacted

@export var prompt := "Interagir"
@export var radius := 2.0
@export var enabled := true


func _ready() -> void:
	add_to_group(&"interactable")


func interact() -> void:
	interacted.emit()
