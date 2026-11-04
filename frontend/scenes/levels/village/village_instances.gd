@tool
class_name VillageInstances
extends Node3D
## Copies d'un même modèle Kenney posées en une seule fois (MultiMesh) : récoltes, vivres, armes, gravats.
## Un seul appel de dessin par maillage du modèle et par case, quel que soit le nombre de copies, pour la version web.
## Les copies sont écrites par tools/build_village.py ; leur collision éventuelle est dans le corps Collision.

## Côté des cases des copies qui s'effacent au loin, et largeur du fondu, en mètres : Godot mesure la distance
## d'effacement jusqu'au centre de chaque MultiMesh, et un seul MultiMesh pour tout le village s'effacerait d'un coup.
const CHUNK_SIZE := 32.0
const FADE_MARGIN := 6.0

@export var model: PackedScene
@export var transforms: Array[Transform3D] = []
## Distance au-delà de laquelle les copies s'effacent ; 0 les garde toujours visibles.
@export var visibility_end := 0.0


func _ready() -> void:
	if model == null or transforms.is_empty():
		return
	var chunks := {}
	for transform in transforms:
		var key := Vector2i.ZERO
		if visibility_end > 0.0:
			key = Vector2i(floori(transform.origin.x / CHUNK_SIZE), floori(transform.origin.z / CHUNK_SIZE))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(transform)
	var scene := model.instantiate() as Node3D
	for mesh_instance: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		# Position du maillage dans le modèle, sans passer par l'arbre de scène.
		var local := mesh_instance.transform
		var parent := mesh_instance.get_parent()
		while parent != scene and parent is Node3D:
			local = (parent as Node3D).transform * local
			parent = parent.get_parent()
		local = scene.transform * local
		for key: Vector2i in chunks:
			_add_chunk(mesh_instance, local, chunks[key])
	scene.free()


func _add_chunk(mesh_instance: MeshInstance3D, local: Transform3D, chunk: Array) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh_instance.mesh
	multimesh.instance_count = chunk.size()
	for index in chunk.size():
		multimesh.set_instance_transform(index, (chunk[index] as Transform3D) * local)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = mesh_instance.material_override
	if visibility_end > 0.0:
		instance.visibility_range_end = visibility_end
		instance.visibility_range_end_margin = FADE_MARGIN
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
