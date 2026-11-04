@tool
class_name VillageInstances
extends Node3D
## Copies d'un même modèle Kenney posées en une seule fois (MultiMesh) : récoltes, vivres, armes, gravats.
## Un seul appel de dessin par maillage du modèle, quel que soit le nombre de copies, pour la version web.
## Les copies sont écrites par tools/build_village.py ; leur collision éventuelle est dans le corps Collision.

@export var model: PackedScene
@export var transforms: Array[Transform3D] = []
## Distance au-delà de laquelle les copies s'effacent ; 0 les garde toujours visibles.
@export var visibility_end := 0.0


func _ready() -> void:
	if model == null or transforms.is_empty():
		return
	var scene := model.instantiate() as Node3D
	for mesh_instance: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		# Position du maillage dans le modèle, sans passer par l'arbre de scène.
		var local := mesh_instance.transform
		var parent := mesh_instance.get_parent()
		while parent != scene and parent is Node3D:
			local = (parent as Node3D).transform * local
			parent = parent.get_parent()
		local = scene.transform * local
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh_instance.mesh
		multimesh.instance_count = transforms.size()
		for index in transforms.size():
			multimesh.set_instance_transform(index, transforms[index] * local)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = mesh_instance.material_override
		if visibility_end > 0.0:
			instance.visibility_range_end = visibility_end
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	scene.free()
