class_name InteractionController
extends Node
## Trouve l'interactable le plus proche du joueur et l'active avec la touche d'interaction.

signal prompt_changed(text: String)

## Écart de hauteur maximal, pour ignorer ce qui se trouve à un autre étage.
@export var max_height_difference := 3.0

var _current: Interactable
var _prompt := ""

@onready var _player: Node3D = get_parent()


func _process(_delta: float) -> void:
	_current = _find_nearest()
	_set_prompt(_current.prompt if _current else "")


func _unhandled_input(event: InputEvent) -> void:
	if _current and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_current.interact()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		_current = null
		_set_prompt("")


func _find_nearest() -> Interactable:
	var nearest: Interactable
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var interactable := node as Interactable
		if not interactable.enabled or not interactable.is_visible_in_tree():
			continue
		var offset := interactable.global_position - _player.global_position
		var distance := Vector2(offset.x, offset.z).length()
		if (
			distance < interactable.radius
			and distance < nearest_distance
			and absf(offset.y) < max_height_difference
		):
			nearest = interactable
			nearest_distance = distance
	return nearest


func _set_prompt(text: String) -> void:
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)
