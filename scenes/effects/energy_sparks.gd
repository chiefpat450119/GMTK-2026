class_name EnergySparks
extends Node2D

## Noise-driven arcs and flecks for something holding more energy than it wants to,
## such as a railgun coil sitting at full charge. The CPUParticles2D children carry
## the whole look; a caller only decides when it is live.

## Idempotent, and safe to set before the node is ready.
var emitting : bool = false:
	set(value):
		if emitting == value:
			return
		emitting = value
		for layer in _layers:
			layer.emitting = value

var _layers : Array[CPUParticles2D] = []

func _ready() -> void:
	for child in get_children():
		if child is CPUParticles2D:
			_layers.append(child)
			child.emitting = emitting

	# Physics interpolation is on project-wide, so without this sparks spawned away
	# from the origin spend their first frame streaking in from where they started.
	reset_physics_interpolation()
