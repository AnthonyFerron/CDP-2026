class_name LevelBake
extends Resource
## Ce qu'un lieu calculait à chaque chargement, calculé d'avance par tools/bake_lieux.gd et rangé dans
## scenes/levels/<lieu>/<lieu>_bake.res : hauteurs et couleurs du sol, positions et collisions du décor dispersé.
## Ce sont les mêmes calculs, faits une fois : rien ne change à l'écran ni sous les pieds, le chargement fond.
##
## Chaque partie porte deux empreintes :
## - celle des réglages dont elle découle (constantes et propriétés du nœud, modèles, sol) : vérifiée partout ;
## - celle du code des scripts qui la calculent : vérifiée quand le code est lisible (éditeur, tests). Le jeu exporté
##   n'a plus le texte des scripts : le contrôle de tests/scenes/run_all.sh (bake_lieux_check) s'en charge.
## Une partie périmée (ou absente) est recalculée au chargement comme avant, avec un avertissement : il faut alors
## relancer tools/bake_lieux.gd.

## Parties : nom -> [empreinte des réglages, empreinte du code (vide si illisible), données].
@export var parts := {}

## Vrai pendant tools/bake_lieux.gd : les lieux calculent tout, et chaque partie calculée est relevée dans recorded.
static var recording := false
static var recorded := {}


## Données de la partie name si elles correspondent aux réglages (signature) et au code (scripts) ; sinon null.
func data(name: String, signature: String, scripts: Array[Script]) -> Variant:
	if recording:
		return null
	if not parts.has(name):
		push_warning("Calcul d'avance « %s » absent, relancer tools/bake_lieux.gd" % name)
		return null
	var part: Array = parts[name]
	var source := source_hash(scripts)
	if part[0] != signature or (not source.is_empty() and not String(part[1]).is_empty() and part[1] != source):
		push_warning("Calcul d'avance « %s » périmé, relancer tools/bake_lieux.gd" % name)
		return null
	return part[2]


## Relève une partie calculée au chargement (seulement pendant tools/bake_lieux.gd).
static func record(name: String, signature: String, scripts: Array[Script], value: Variant) -> void:
	if recording:
		recorded[name] = [signature, source_hash(scripts), value]


## Empreinte du code des scripts, vide si l'un d'eux n'a plus son texte (jeu exporté).
static func source_hash(scripts: Array[Script]) -> String:
	var text := ""
	for script in scripts:
		if script == null or script.source_code.is_empty():
			return ""
		text += script.source_code
	return text.md5_text()


## Empreinte des réglages d'un nœud : les constantes simples de son script, ses propriétés exportées (une ressource
## par son fichier ; un nœud et le calcul d'avance lui-même ignorés) et ce qu'on y ajoute (extra).
static func signature_of(node: Object, extra: Array = []) -> String:
	var values := []
	var script := node.get_script() as Script
	if script:
		var constants := script.get_script_constant_map()
		# Triés comme des textes : l'ordre des StringName change d'un lancement à l'autre.
		var names: Array[String] = []
		for constant: StringName in constants:
			names.append(String(constant))
		names.sort()
		for constant in names:
			if _plain(constants[StringName(constant)]):
				values.append([constant, constants[StringName(constant)]])
	for property in node.get_property_list():
		# Seules les propriétés exportées : l'état du nœud (ce qu'il a calculé) n'est pas un réglage.
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or not property.usage & PROPERTY_USAGE_EDITOR:
			continue
		var value: Variant = node.get(property.name)
		if value is Node or value is LevelBake:
			continue
		values.append([property.name, _describe(value)])
	values.append_array(extra)
	return var_to_str(values).md5_text()


static func _plain(value: Variant) -> bool:
	if value is Object:
		return false
	if value is Array:
		for item: Variant in value:
			if not _plain(item):
				return false
	if value is Dictionary:
		for key: Variant in value:
			if not _plain(key) or not _plain(value[key]):
				return false
	return true


static func _describe(value: Variant) -> Variant:
	if value is Resource:
		var resource := value as Resource
		return resource.resource_path if not resource.resource_path.is_empty() else resource.get_class()
	if value is Array:
		var items := []
		for item: Variant in value:
			items.append(_describe(item))
		return items
	if value is Object:
		return null
	return value
