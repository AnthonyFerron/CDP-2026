extends Node3D
## Décor fixe du hub (hub_props.tscn) : au chargement, les modèles de chaque groupe (le décor fixe, et pour chaque
## élément réparable sa ruine et sa reconstruction) sont regroupés en MultiMesh, un par maillage. Le moteur dessine
## alors un modèle répété en un seul appel au lieu d'un par objet, ce qui compte pour la version web.
## Les groupes restent séparés : les réparations continuent de montrer ou cacher chacun d'un bloc.

const GROUPS: Array[StringName] = [&"Fixed", &"Ruins", &"Rebuilt"]


func _ready() -> void:
	for group in find_children("*", "Node3D", true, false):
		if StringName(group.name) in GROUPS:
			_batch(group)


func _batch(group: Node3D) -> void:
	var buckets := {}
	var shadows := {}
	var batched: Array[Node] = []
	var inverse := group.global_transform.affine_inverse()
	for child in group.get_children():
		# Seuls les modèles posés tels quels : les nœuds à script (la roue du moulin) gardent leurs enfants.
		if not child is Node3D or child.scene_file_path.is_empty():
			continue
		for mesh_instance: MeshInstance3D in child.find_children("*", "MeshInstance3D", true, false):
			if not mesh_instance.mesh:
				continue
			if not buckets.has(mesh_instance.mesh):
				buckets[mesh_instance.mesh] = []
				shadows[mesh_instance.mesh] = mesh_instance.cast_shadow
			buckets[mesh_instance.mesh].append(inverse * mesh_instance.global_transform)
		batched.append(child)
	for mesh: Mesh in buckets:
		var transforms: Array = buckets[mesh]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()
		for index in transforms.size():
			multimesh.set_instance_transform(index, transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Batch"
		instance.multimesh = multimesh
		instance.cast_shadow = shadows[mesh]
		group.add_child(instance)
	for child in batched:
		group.remove_child(child)
		child.queue_free()
