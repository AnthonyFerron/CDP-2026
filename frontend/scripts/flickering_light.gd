class_name FlickeringLight
extends OmniLight3D
## Lumière qui vacille comme une flamme ou une braise.

@export_range(0.0, 1.0) var flicker := 0.25
@export var speed := 5.0

var _base_energy := 0.0
var _time := 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_base_energy = light_energy
	_noise.seed = randi()
	_noise.frequency = 1.0
	_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta * speed
	light_energy = _base_energy * (1.0 + _noise.get_noise_1d(_time) * flicker)
