extends Node3D
## Niveau autonome : aucun changement apporté aux autres scènes ou au joueur partagé.

var _progress := 0
var _opened := false
var _collected := false
var _target := ""
var _tablet_index := -1

@onready var _player: CharacterBody3D = $Player
@onready var _prompt: Label = $Interface/Prompt
@onready var _objective: Label = $Interface/Objective


func _process(_delta: float) -> void:
	_target = ""
	_tablet_index = -1
	var p := _player.global_position
	if p.y > -5.0:
		if p.distance_to(Vector3(0, 1.2, -7)) < 3.2:
			_target = "enter"
			_prompt.text = "[E] Soulever la trappe en bois et descendre"
	else:
		if p.distance_to(Vector3(0, -15, 0)) < 2.8:
			_target = "exit"
			_prompt.text = "[E] Remonter à la surface"
		for i in range(3):
			if p.distance_to(Vector3(-5 + i * 5, -15, -6)) < 2.8:
				_target = "tablet"
				_tablet_index = i
				_prompt.text = "[E] Lire et activer la tablette %s" % [i + 1]
		if p.distance_to(Vector3(0, -15, -13)) < 3.0:
			_target = "chest"
			_prompt.text = "Le coffre attend les trois fonctions anciennes."
			if _opened:
				_prompt.text = "[E] Récupérer le livre ancien" if not _collected else "Le livre est en votre possession."
	if _target.is_empty():
		_prompt.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E):
		return
	match _target:
		"enter":
			_teleport(Vector3(0, -14.8, -0.5))
			_objective.text = "Activez les tablettes dans l'ordre de l'inscription.\nE : lire / activer • Échap : libérer la souris"
		"exit":
			_teleport(Vector3(0, 1.4, -4.5))
		"tablet":
			if _opened:
				return
			if _tablet_index == _progress:
				_progress += 1
				_objective.text = "Fonctions réunies : %s / 3" % _progress
			else:
				_progress = 0
				_objective.text = "L'algorithme se dissipe. Relisez l'inscription et recommencez."
			if _progress == 3:
				_opened = true
				var tween := create_tween()
				tween.tween_property($ChestLid, "rotation:x", deg_to_rad(-105), 1.2)
				_objective.text = "Le coffre s'ouvre. Récupérez le livre ancien."
		"chest":
			if _opened and not _collected:
				_collected = true
				$Book.hide()
				$BookPages.hide()
				_objective.text = "Livre ancien retrouvé !\nVous pouvez remonter à la surface."


func _teleport(destination: Vector3) -> void:
	_player.global_position = destination
	_player.velocity = Vector3.ZERO
