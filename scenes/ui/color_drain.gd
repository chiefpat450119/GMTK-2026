class_name ColorDrain
extends ColorRect

const OFF_EPSILON := 0.001

## Fraction of max time at which colour starts to go.
@export_range(0.0, 1.0) var appear_at: float = 0.5
## Fraction at or below which the screen is fully drained.
@export_range(0.0, 1.0) var full_at: float = 0.05
## How fast the drain chases the clock. Deliberately slower than the vignette's:
## patches of the screen snapping to grey the instant you take a hit reads as a
## glitch, where creeping reads as decay.
@export var response: float = 4.0

var _current: float = 0.0
@onready var _material: ShaderMaterial = _own_material()


func _ready() -> void:
	_apply(0.0)
	visible = false


func _process(delta: float) -> void:
	var target := _read_target()
	# Exponential ease, so the rate is the same whatever the framerate.
	_current = lerpf(_current, target, 1.0 - exp(-response * delta))

	if _current < OFF_EPSILON and target <= 0.0:
		_current = 0.0
		_apply(0.0)
		visible = false
		return

	visible = true
	_apply(_current)


# Maps time remaining onto 0..1. Inverted because the effect grows as the clock
# shrinks: appear_at reads 0 and full_at reads 1.
func _read_target() -> float:
	if Player.instance == null:
		return 0.0
	var clock := Player.instance.time_component
	if clock == null:
		return 0.0
	return clampf(inverse_lerp(appear_at, full_at, clock.time_percentage()), 0.0, 1.0)


func _apply(value: float) -> void:
	_material.set_shader_parameter("drain", value)


# The material is a scene sub-resource, so every instance of this scene shares
# one copy. Left shared, two drains would fight over the same value, and
# whatever the last one wrote would be saved back into the scene file.
func _own_material() -> ShaderMaterial:
	var owned := (material as ShaderMaterial).duplicate() as ShaderMaterial
	material = owned
	return owned
