class_name Storage
extends Interactable
## Tiroir ou armoire de la mairie : E l'ouvre et montre ce qu'il contient, parfois un fragment de papier.

signal opened(had_fragment: bool)

## Fragment rangé à l'intérieur ; vide si le meuble ne contient rien.
@export var fragment: NodePath
## « le tiroir », « l'armoire » : sert aux invites.
@export var furniture_name := "le tiroir"

var is_open := false


func _ready() -> void:
	super._ready()
	prompt = "Ouvrir " + furniture_name


func interact() -> void:
	if is_open:
		return
	is_open = true
	enabled = false
	var paper := get_node_or_null(fragment) as PaperFragment
	if paper:
		paper.reveal()
	# Un fragment déjà ramassé lors d'une session précédente ne compte plus : le meuble paraît vide.
	opened.emit(paper != null and not paper.collected)
	super.interact()
