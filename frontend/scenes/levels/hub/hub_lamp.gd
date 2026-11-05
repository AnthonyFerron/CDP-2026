extends Node3D
## Lumière chaude d'un intérieur du hub, sous le plafond d'un bâtiment reconstruit. Elle ne s'allume que quand la
## caméra approche du bâtiment, en fondu : le village compte une douzaine d'intérieurs, et la version web ne peut
## pas les garder tous allumés. Sa portée s'arrête aux murs, pour ne pas éclairer le sol du dehors à travers eux.

@export var color := Color(1.0, 0.7, 0.42)
@export var energy := 1.4
@export var light_range := 5.0
## Distance de la caméra au centre du bâtiment à laquelle la lumière commence à s'allumer, et celle où elle est
## pleinement allumée.
@export var reach := 16.0
@export var full := 11.0
## Points des lumières, dans le repère du nœud : une grande salle en a deux.
@export var spots := PackedVector3Array([Vector3.ZERO])

var _lights: Array[OmniLight3D] = []
var _level := -1.0


func _ready() -> void:
	for spot in spots:
		var light := OmniLight3D.new()
		light.light_color = color
		light.omni_range = light_range
		light.omni_attenuation = 1.0
		light.shadow_enabled = false
		light.position = spot
		light.visible = false
		add_child(light)
		_lights.append(light)
	_update()


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var distance := camera.global_position.distance_to(global_position)
	var level := clampf((reach - distance) / maxf(reach - full, 0.01), 0.0, 1.0)
	if is_equal_approx(level, _level):
		return
	_level = level
	for light in _lights:
		light.visible = level > 0.0
		light.light_energy = energy * level
