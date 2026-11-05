class_name PlaineBake
extends Resource
## Ce que la Plaine calculait à chaque chargement, calculé d'avance par tools/bake_plaine.gd (plaine_bake.res) :
## le maillage du sol et ses hauteurs (PlaineTerrain), et les bandes de la zone qui brûle (PlaineScatter). Ce sont
## les mêmes calculs, faits une fois : rien ne change à l'écran ni sous les pieds, le chargement fond.
## Chaque partie porte l'empreinte des réglages dont elle découle ; au chargement, si elle ne correspond plus (ou si
## quelques hauteurs recalculées s'en écartent), la partie est recalculée comme avant, avec un avertissement : il
## faut alors relancer tools/bake_plaine.gd.

## Empreinte des réglages du terrain (PlaineTerrain.settings_signature) quand le sol a été calculé.
@export var terrain_signature := ""
## Hauteurs aux sommets de la grille du sol, comme PlaineTerrain les calcule.
@export var heights := PackedFloat32Array()
## Niveau de la lave de chaque cratère, pour vérifier au chargement que le relief n'a pas changé.
@export var pool_levels := PackedFloat32Array()
## Maillage du sol, sans matériau (le terrain y pose le sien).
@export var ground: ArrayMesh
## Empreinte des réglages de la zone qui brûle (PlaineScatter.hazard_signature).
@export var hazard_signature := ""
## Bandes de la zone qui brûle : centre et taille de chaque boîte.
@export var hazard_positions := PackedVector3Array()
@export var hazard_sizes := PackedVector3Array()
