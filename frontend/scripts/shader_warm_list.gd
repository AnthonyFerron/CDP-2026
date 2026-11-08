class_name ShaderWarmList
extends Resource
## Inventaire des matériaux du jeu, calculé d'avance par tools/bake_shaders.gd (assets/shader_warm_list.tres) et
## dessiné hors de l'écran au menu d'accueil par ShaderWarmup, pour que leurs shaders soient compilés avant la partie.
##
## Chaque lieu donne deux groupes : l'extérieur (brouillard, soleils) et l'intérieur (sous la carte, sans brouillard
## ni soleil). Un matériau n'est gardé qu'une fois par contexte de rendu identique : le même matériau, dans un lieu
## éclairé de la même façon, compile les mêmes programmes. Les textures sont retirées des copies gardées ici : elles
## ne changent pas le code des shaders, et le menu n'a pas à les charger.

## Usage d'un matériau, en bits : dessiné en instances (MultiMesh, particules), projette une ombre.
const INSTANCED := 1
const SHADOW := 2

## Empreinte de l'inventaire, une ligne par entrée : tools/bake_shaders.gd -- --check la compare au calcul.
@export var fingerprint := PackedStringArray()
## Un dictionnaire par groupe, dans l'ordre où le menu les prépare :
##   place (String), inside (bool), environment (Environment), suns (Array de dictionnaires shadow, mode, blend),
##   omni (bool : des lumières ponctuelles sans ombre), materials (Array[Material]), usages (PackedByteArray),
##   process (Array[Material] : matériaux de particules), labels (Array de dictionnaires de réglages de Label3D).
@export var groups: Array[Dictionary] = []
