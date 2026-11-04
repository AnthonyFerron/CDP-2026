class_name SearchableBook
extends Interactable
## Livre d'un rayonnage, que le joueur peut ouvrir. Certains cachent un fragment de la conversation.
## Le nœud se pose juste devant la tranche du livre, sa face +Z tournée vers la pièce (tools/build_plaine.py en donne
## les places) : le livre dépasse de sa rangée, ses nervures dorées accrochent la lumière quand on le regarde, et un
## signet pend sur le bord de la tablette. Une fois lu, il rentre dans le rang et perd son signet.

## Épaisseur, hauteur et profondeur du livre.
const SIZE := Vector3(0.11, 0.36, 0.27)
## Recul du livre une fois lu, pour qu'il s'aligne sur ses voisins.
const PUSHED_BACK := 0.08

@export var title := "Un vieux livre"
@export_multiline var body := ""
## Numéro du fragment caché entre ses pages, ou -1 s'il n'en cache aucun.
@export var fragment := -1
@export var cover_color := Color(0.45, 0.18, 0.12)

var searched := false

var _book: Node3D
var _cover: StandardMaterial3D
var _bands: StandardMaterial3D
var _ribbon: MeshInstance3D
var _glow := 0.0


func _ready() -> void:
	super._ready()
	if prompt == "Interagir":
		prompt = "Examiner le livre"
	_book = Node3D.new()
	add_child(_book)
	_cover = StandardMaterial3D.new()
	_cover.albedo_color = cover_color
	_cover.roughness = 0.8
	_cover.emission_enabled = true
	_cover.emission = cover_color.lightened(0.3)
	_cover.emission_energy_multiplier = 0.0
	_bands = StandardMaterial3D.new()
	_bands.albedo_color = Color(0.78, 0.6, 0.25)
	_bands.metallic = 0.6
	_bands.roughness = 0.4
	_bands.emission_enabled = true
	_bands.emission = Color(1.0, 0.75, 0.35)
	_bands.emission_energy_multiplier = 0.35
	var label := StandardMaterial3D.new()
	label.albedo_color = cover_color.darkened(0.55)
	# Couverture et dos, puis les nervures dorées et l'étiquette sombre du dos, face à la pièce.
	_add_box(SIZE, Vector3(0.0, 0.0, -SIZE.z * 0.5), _cover)
	for height in [-0.12, 0.12]:
		_add_box(Vector3(SIZE.x + 0.006, 0.018, 0.008), Vector3(0.0, height, 0.002), _bands)
	_add_box(Vector3(SIZE.x * 0.7, 0.07, 0.006), Vector3(0.0, 0.035, 0.002), label)
	# Signet de tissu, qui pend devant le bord de la tablette.
	var silk := StandardMaterial3D.new()
	silk.albedo_color = Color(0.85, 0.75, 0.45)
	_ribbon = _add_box(Vector3(0.024, 0.15, 0.004), Vector3(0.025, -SIZE.y * 0.5 - 0.07, 0.006), silk)


func _process(delta: float) -> void:
	# Lueur discrète sous le regard du joueur.
	var target := 1.0 if focused else 0.0
	_glow = move_toward(_glow, target, delta * 4.0)
	_cover.emission_energy_multiplier = 0.25 * _glow
	_bands.emission_energy_multiplier = (0.1 if searched else 0.35) + 1.2 * _glow


func mark_searched() -> void:
	searched = true
	prompt = "Relire le livre"
	_ribbon.visible = false
	_book.position.z = -PUSHED_BACK


func _add_box(size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	_book.add_child(instance)
	return instance
