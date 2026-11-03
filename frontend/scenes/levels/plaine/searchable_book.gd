class_name SearchableBook
extends Interactable
## Livre d'un rayonnage, que le joueur peut ouvrir. Certains cachent un fragment de la conversation.

@export var title := "Un vieux livre"
@export_multiline var body := ""
## Numéro du fragment caché entre ses pages, ou -1 s'il n'en cache aucun.
@export var fragment := -1
@export var cover_color := Color(0.45, 0.18, 0.12)

var searched := false


func _ready() -> void:
	super._ready()
	if prompt == "Interagir":
		prompt = "Examiner le livre"
	# Un livre qui dépasse du rayonnage, pour qu'on le remarque.
	var material := StandardMaterial3D.new()
	material.albedo_color = cover_color
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.16, 0.6, 0.42)
	mesh.material = material
	var cover := MeshInstance3D.new()
	cover.mesh = mesh
	add_child(cover)


func mark_searched() -> void:
	searched = true
	prompt = "Relire le livre"
