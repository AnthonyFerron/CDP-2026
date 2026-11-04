@tool
class_name ModelMultiMesh
extends Node3D
## Répète un modèle Kenney, ou un simple maillage, en un MultiMesh par maillage : un seul appel de dessin pour
## les livres des rayonnages ou les feuillets épars. Écrit par tools/build_plaine.py.

## Modèle à répéter (chacun de ses maillages devient un MultiMesh), ou à défaut un maillage seul.
@export var model: PackedScene
@export var mesh: Mesh
@export var transforms: Array[Transform3D] = []
@export var cast_shadows := true

var _built: Array[Node] = []


func _ready() -> void:
	_build()


func _build() -> void:
	for node in _built:
		node.queue_free()
	_built.clear()
	if mesh:
		_add(mesh, Transform3D.IDENTITY)
	if not model:
		return
	var instance := model.instantiate() as Node3D
	for part: MeshInstance3D in instance.find_children("*", "MeshInstance3D", true, false):
		# Place du maillage dans le modèle : produit des transformations jusqu'à sa racine.
		var local := part.transform
		var parent := part.get_parent()
		while parent and parent != instance:
			if parent is Node3D:
				local = (parent as Node3D).transform * local
			parent = parent.get_parent()
		_add(part.mesh, local)
	instance.free()


func _add(source: Mesh, offset: Transform3D) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = source
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index] * offset)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	if not cast_shadows:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Enfant interne : il n'est pas enregistré dans la scène.
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	_built.append(instance)
