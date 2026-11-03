class_name Brazier
extends Node3D
## Brasero que le joueur allume ou éteint. Sa valeur compte dans l'énigme de la crypte quand il brûle.

signal toggled(lit: bool)

## Valeur du brasero dans le nombre affiché par les feux.
@export var value := 1
@export var lit := false
@export var ignite_sound: AudioStream

@onready var _fire: FireEffect = $Fire
@onready var _interactable: Interactable = $Interactable
@onready var _sound: AudioStreamPlayer3D = $Sound


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	_sound.stream = ignite_sound
	_refresh()


func set_locked(locked: bool) -> void:
	_interactable.enabled = not locked


func _on_interacted() -> void:
	lit = not lit
	if lit and ignite_sound:
		_sound.play()
	_refresh()
	toggled.emit(lit)


func _refresh() -> void:
	_fire.lit = lit
	_interactable.prompt = "Éteindre le feu" if lit else "Allumer le feu"
