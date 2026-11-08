@tool
class_name HubFoliage
extends RefCounted
## Feuillage du décor dispersé qui reprend vie avec les livres posés (hub_foliage.gdshader) : arbres, forêt, buissons,
## roseaux et nénuphars du hub. Chaque modèle reçoit une copie de son maillage dont le feuillage passe par le shader, avec
## la couleur, la texture et le métal de son matériau Kenney ; chaque copie posée porte, dans les données de son
## MultiMesh, le palier de vie où elle reverdit (revive_at). Le reste du maillage (le bois des troncs) ne change pas.

## Matériaux Kenney qui sont du feuillage : les feuilles du kit Nature, ses herbes, et la texture des arbres de mini_forest.
const LEAVES := ["leafsGreen", "leafsDark", "grass", "colormap"]
## Part des copies qui restent vertes dès le début : quelques arbres ont survécu aux cendres.
const SURVIVORS := 0.12

var _shader: Shader
## Maillage d'origine -> sa copie au feuillage vivant ou sec.
var _meshes := {}
## Matériau Kenney -> son double, passé par le shader.
var _materials := {}


func _init(shader: Shader) -> void:
	_shader = shader


## Copie du maillage dont le feuillage suit la vie du hub. whole : toutes ses surfaces (les nénuphars et leur fleur).
func mesh(source: Mesh, whole := false) -> Mesh:
	if not _shader or not source is ArrayMesh:
		return source
	var key := "%d:%s" % [source.get_instance_id(), whole]
	if _meshes.has(key):
		return _meshes[key]
	var copy := source.duplicate() as ArrayMesh
	for surface in copy.get_surface_count():
		var material := source.surface_get_material(surface) as BaseMaterial3D
		if material and (whole or material.resource_name in LEAVES):
			copy.surface_set_material(surface, _material(material))
	_meshes[key] = copy
	return copy


func _material(source: BaseMaterial3D) -> ShaderMaterial:
	if _materials.has(source):
		return _materials[source]
	var material := ShaderMaterial.new()
	material.shader = _shader
	material.set_shader_parameter("albedo", source.albedo_color)
	if source.albedo_texture:
		material.set_shader_parameter("albedo_texture", source.albedo_texture)
	material.set_shader_parameter("metallic", source.metallic)
	material.set_shader_parameter("roughness", source.roughness)
	_materials[source] = material
	return material


## Vie du hub, de 0 à 1 : chaque copie dont le palier est atteint reverdit.
func set_life(life: float) -> void:
	for material: ShaderMaterial in _materials.values():
		material.set_shader_parameter("life", life)


## Palier de vie où reverdit la copie posée en ce point (0, 0,25, 0,5, 0,75 ou 1) : un livre de plus, un quart de plus.
## Tiré de sa position (le même à chaque chargement), un peu plus tôt au bord de l'eau, d'où la vie repart.
static func revive_at(point: Vector3, shore: float) -> float:
	var key := Vector2i(roundi(point.x * 8.0), roundi(point.z * 8.0))
	var chance := float(absi(hash(key)) % 10007) / 10007.0
	if chance < SURVIVORS:
		return 0.0
	var score := 0.7 * (chance - SURVIVORS) / (1.0 - SURVIVORS) + 0.3 * clampf(shore / 40.0, 0.0, 1.0)
	return clampf(ceilf(score * 4.0), 1.0, 4.0) * 0.25


## Pose les paliers de vie dans les données d'un MultiMesh : il doit avoir use_custom_data avant ses copies.
static func mark(multimesh: MultiMesh, terrain: HubTerrain) -> void:
	for index in multimesh.instance_count:
		var origin := multimesh.get_instance_transform(index).origin
		var shore := terrain.shore_distance(origin.x, origin.z) if terrain else 40.0
		multimesh.set_instance_custom_data(index, Color(revive_at(origin, shore), 0.0, 0.0, 0.0))
