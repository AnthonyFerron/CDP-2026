class_name Village
extends Node3D
## Zone du Village détruit : l'enceinte forcée, la place du marché, l'hôtel de ville et les deux moulins.
## Le décor est en place ; l'histoire, l'énigme et le livre de cette zone restent à écrire.

const ZONE := &"village"
## Tours par seconde des ailes du moulin et de la roue du moulin à eau.
const WINDMILL_SPEED := 0.05
const WHEEL_SPEED := 0.12

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _portal: Portal = $Portal
@onready var _windmill: Node3D = $WindmillRotor
@onready var _wheel: Node3D = $WaterWheel


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	# Pas encore de livre ici : le portail du retour reste ouvert.
	_portal.is_open = true
	_portal.travel_requested.connect(GameState.return_to_hub.bind(ZONE))
	_hud.show_message("Le Village détruit")


func _process(delta: float) -> void:
	_windmill.rotate_object_local(Vector3.RIGHT, TAU * WINDMILL_SPEED * delta)
	_wheel.rotate_object_local(Vector3.RIGHT, -TAU * WHEEL_SPEED * delta)
