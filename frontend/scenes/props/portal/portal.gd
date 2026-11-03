@tool
class_name Portal
extends Node3D
## Portail en arche : deux piliers reliés en haut par un demi-cercle, ouverts sur une surface lumineuse.
## Fermé, il refuse le passage ; ouvert, on le traverse à pied ou avec la touche d'interaction.

signal travel_requested
signal refused

@export var closed_prompt := "Portail fermé"
@export var open_prompt := "Traverser le portail"
@export var is_open := false:
	set = set_open

@export_group("Forme")
## Écart entre les deux piliers, au sol.
@export var opening_width := 2.0
## Hauteur des piliers droits, sous le demi-cercle.
@export var pillar_height := 2.2
@export var thickness := 0.4
@export var depth := 0.6
@export var arc_segments := 14

## Shader de la surface, déclaré dans la scène pour qu'il parte bien dans l'export web.
@export var surface_shader: Shader

@export_group("Couleurs")
@export var inner_color := Color(1.0, 0.85, 0.4)
@export var outer_color := Color(0.9, 0.12, 0.03)
@export var stone_color := Color(0.3, 0.27, 0.29)

var _surface: MeshInstance3D
var _light: OmniLight3D
var _runes: StandardMaterial3D
var _interactable: Interactable


func _ready() -> void:
	_build()
	_refresh()


func set_open(value: bool) -> void:
	is_open = value
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	_surface.visible = is_open
	_light.visible = is_open
	_runes.emission_energy_multiplier = 2.5 if is_open else 0.2
	_interactable.prompt = open_prompt if is_open else closed_prompt


func _on_interacted() -> void:
	if is_open:
		travel_requested.emit()
	else:
		refused.emit()


func _on_body_entered(body: Node3D) -> void:
	if is_open and body is Player:
		travel_requested.emit()


func _build() -> void:
	var half := opening_width * 0.5
	var stone := StandardMaterial3D.new()
	stone.albedo_color = stone_color
	stone.roughness = 1.0
	_runes = StandardMaterial3D.new()
	_runes.albedo_color = stone_color.darkened(0.3)
	_runes.emission_enabled = true
	_runes.emission = outer_color

	var arch := MeshInstance3D.new()
	arch.mesh = _arch_mesh(stone)
	add_child(arch)

	var base := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(opening_width + thickness * 2.0 + 0.6, 0.2, depth + 0.6)
	slab.material = stone
	base.mesh = slab
	base.position.y = 0.1
	add_child(base)

	var material := ShaderMaterial.new()
	material.shader = surface_shader
	material.set_shader_parameter("inner_color", inner_color)
	material.set_shader_parameter("outer_color", outer_color)
	material.set_shader_parameter("opening_width", opening_width)
	material.set_shader_parameter("pillar_height", pillar_height)
	var height := pillar_height + half
	var quad := QuadMesh.new()
	quad.size = Vector2(opening_width, height)
	quad.material = material
	_surface = MeshInstance3D.new()
	_surface.mesh = quad
	_surface.position.y = 0.2 + height * 0.5
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_surface)

	_light = OmniLight3D.new()
	_light.light_color = outer_color.lerp(inner_color, 0.4)
	_light.light_energy = 2.5
	_light.omni_range = 9.0
	_light.position = Vector3(0.0, height * 0.6, 0.8)
	add_child(_light)

	# Collisions des piliers seulement : l'ouverture reste franchissable.
	var body := StaticBody3D.new()
	add_child(body)
	for side in [-1.0, 1.0]:
		var shape := BoxShape3D.new()
		shape.size = Vector3(thickness, pillar_height + half + thickness, depth)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = Vector3(side * (half + thickness * 0.5), 0.2 + shape.size.y * 0.5, 0.0)
		body.add_child(collision)

	var trigger_shape := BoxShape3D.new()
	trigger_shape.size = Vector3(opening_width - 0.2, pillar_height, 0.5)
	var trigger_collision := CollisionShape3D.new()
	trigger_collision.shape = trigger_shape
	var trigger := Area3D.new()
	trigger.position.y = 0.2 + pillar_height * 0.5
	trigger.add_child(trigger_collision)
	add_child(trigger)

	_interactable = Interactable.new()
	_interactable.radius = 4.0
	add_child(_interactable)
	if not Engine.is_editor_hint():
		trigger.body_entered.connect(_on_body_entered)
		_interactable.interacted.connect(_on_interacted)


## Arche extrudée : la même silhouette pour le bord extérieur et l'ouverture, reliées face à face.
func _arch_mesh(stone: Material) -> ArrayMesh:
	var half := opening_width * 0.5
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	outer.append(Vector2(-half - thickness, 0.0))
	inner.append(Vector2(-half, 0.0))
	for i in arc_segments + 1:
		var angle := PI - PI * i / arc_segments
		var direction := Vector2(cos(angle), sin(angle))
		outer.append(Vector2(0.0, pillar_height) + direction * (half + thickness))
		inner.append(Vector2(0.0, pillar_height) + direction * half)
	outer.append(Vector2(half + thickness, 0.0))
	inner.append(Vector2(half, 0.0))

	var front := depth * 0.5
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(stone)
	for i in outer.size() - 1:
		var o0 := Vector3(outer[i].x, outer[i].y + 0.2, 0.0)
		var o1 := Vector3(outer[i + 1].x, outer[i + 1].y + 0.2, 0.0)
		var i0 := Vector3(inner[i].x, inner[i].y + 0.2, 0.0)
		var i1 := Vector3(inner[i + 1].x, inner[i + 1].y + 0.2, 0.0)
		for z in [front, -front]:
			var flip: bool = z < 0.0
			_quad(tool, i0 + Vector3(0, 0, z), o0 + Vector3(0, 0, z), o1 + Vector3(0, 0, z), i1 + Vector3(0, 0, z), flip)
		_quad(tool, o0 + Vector3(0, 0, front), o0 - Vector3(0, 0, front), o1 - Vector3(0, 0, front), o1 + Vector3(0, 0, front), false)
	tool.generate_normals()
	var mesh := tool.commit()

	# Bord intérieur de l'arche, sur une surface à part : ses runes s'allument quand le portail s'ouvre.
	var runes := SurfaceTool.new()
	runes.begin(Mesh.PRIMITIVE_TRIANGLES)
	runes.set_material(_runes)
	for i in inner.size() - 1:
		var i0 := Vector3(inner[i].x, inner[i].y + 0.2, 0.0)
		var i1 := Vector3(inner[i + 1].x, inner[i + 1].y + 0.2, 0.0)
		_quad(runes, i0 - Vector3(0, 0, front), i0 + Vector3(0, 0, front), i1 + Vector3(0, 0, front), i1 - Vector3(0, 0, front), false)
	runes.generate_normals()
	return runes.commit(mesh)


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool) -> void:
	var points := [a, b, c, a, c, d] if not flip else [a, c, b, a, d, c]
	for point: Vector3 in points:
		tool.add_vertex(point)
