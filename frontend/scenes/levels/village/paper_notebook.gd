class_name PaperNotebook
extends CanvasLayer
## Inventaire des fragments de papier retrouvés, consultable à tout moment avec la touche I.

signal closed

@onready var _root: Control = %Root
@onready var _title: Label = %Title
@onready var _list: Label = %List


func _ready() -> void:
	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	for action in ["inventory", "interact", "ui_cancel"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_root.hide()
			closed.emit()
			return


func is_open() -> bool:
	return _root.visible


func open(fragments: Array[String], total: int) -> void:
	_title.text = "Fragments de papier : %d / %d" % [fragments.size(), total]
	_list.text = "\n\n".join(fragments) if not fragments.is_empty() else "Aucun fragment pour l'instant. Fouillez les bureaux, les tiroirs, les armoires et les étagères de la mairie."
	_root.show()
