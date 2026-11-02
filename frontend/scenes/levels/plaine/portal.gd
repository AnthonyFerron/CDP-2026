class_name Portal
extends Node3D
## Portail de zone : fermé, il refuse le passage ; ouvert, il signale la demande de voyage.

signal travel_requested
signal refused

@export var closed_prompt := "Portail fermé"
@export var open_prompt := "Traverser le portail"
@export var is_open := false:
	set = set_open

@onready var _surface: MeshInstance3D = $Surface
@onready var _light: OmniLight3D = $Light
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	_refresh()


func set_open(value: bool) -> void:
	is_open = value
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	_surface.visible = is_open
	_light.visible = is_open
	_interactable.prompt = open_prompt if is_open else closed_prompt


func _on_interacted() -> void:
	if is_open:
		travel_requested.emit()
	else:
		refused.emit()
