class_name VillageLife
extends Node
## Ce qui bouge dans le Village sans script à soi : le linge étendu et les bannières ondulent au vent, par le shader
## village_cloth.gdshader. Les draps (formes simples du décor, dont le matériau s'appelle « linen… ») ondulent sous
## leur corde ; les bannières des modèles Kenney, sous leur barre.

const CLOTH := preload("res://scenes/levels/village/village_cloth.gdshader")

## Racines où chercher draps et bannières : le décor du bourg et l'intérieur de la mairie.
@export var roots: Array[NodePath] = []


func _ready() -> void:
	for path in roots:
		var root := get_node_or_null(path)
		if root:
			_dress(root)


func _dress(node: Node) -> void:
	for child in node.get_children(true):
		if child is GeometryInstance3D:
			_wave(child as GeometryInstance3D, String(node.name).begins_with("banner") or String(child.name).begins_with("banner"))
		_dress(child)


func _wave(item: GeometryInstance3D, in_banner: bool) -> void:
	var source := item.material_override as StandardMaterial3D
	if source and source.resource_name.begins_with("linen"):
		var linen := ShaderMaterial.new()
		linen.shader = CLOTH
		linen.set_shader_parameter("albedo", source.albedo_color)
		linen.set_shader_parameter("amplitude", 0.09)
		item.material_override = linen
		return
	if not in_banner or not item is MeshInstance3D:
		return
	# Bannière Kenney : drap vertical, mince en x, accroché à sa barre en haut du modèle.
	var mesh := (item as MeshInstance3D).mesh
	var base := mesh.surface_get_material(0) as StandardMaterial3D if mesh else null
	if base == null:
		return
	var banner := ShaderMaterial.new()
	banner.shader = CLOTH
	banner.set_shader_parameter("albedo", base.albedo_color)
	banner.set_shader_parameter("albedo_texture", base.albedo_texture)
	banner.set_shader_parameter("use_texture", base.albedo_texture != null)
	banner.set_shader_parameter("world_anchor", false)
	banner.set_shader_parameter("anchor", 1.0)
	banner.set_shader_parameter("span", 0.84)
	banner.set_shader_parameter("ground", -1000.0)
	banner.set_shader_parameter("amplitude", 0.035)
	banner.set_shader_parameter("speed", 1.6)
	banner.set_shader_parameter("sway_axis", Vector3(1, 0, 0))
	item.material_override = banner
