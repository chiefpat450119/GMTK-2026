class_name TimeVignette
extends ColorRect
## Screen-edge vignette that closes in as the run clock empties.
##
## Silent above `appear_at` of the player's max time, at its worst at or below
## `full_at`, and beating faster the closer the run is to ending.
##
## Reads the clock straight off Player.instance every frame rather than through
## the time-changed event: the ease and the pulse need a per-frame tick anyway,
## and polling means the effect clears itself when the player is freed between
## runs instead of waiting for an event that will never come.

# Under this the effect is switched off outright, which also drops the
# full-screen pass and the screen copy the shader reads.
const OFF_EPSILON := 0.001

## Fraction of max time at which the vignette starts to show.
@export_range(0.0, 1.0) var appear_at: float = 0.20
## Fraction at or below which it is fully exaggerated.
@export_range(0.0, 1.0) var full_at: float = 0.05
## How fast the drawn intensity chases the clock. Higher snaps harder to a hit.
@export var response: float = 12.0
## Pulse rate at `appear_at` and at `full_at`, in beats per second.
@export var pulse_hz_min: float = 0.7
@export var pulse_hz_max: float = 2.0
## Share of the opacity the pulse swings once the vignette is at its worst. It
## fades in with the intensity, so the effect arrives steady and only starts
## breathing as the clock actually runs out. 0 for no pulse at all.
@export_range(0.0, 1.0) var pulse_depth: float = 0.12

var _current: float = 0.0
var _phase: float = 0.0
@onready var _material: ShaderMaterial = _own_material()


func _ready() -> void:
	_apply(0.0, 1.0)
	visible = false


func _process(delta: float) -> void:
	var target := _read_target()
	# Exponential ease, so the rate is the same whatever the framerate. Mostly
	# this matters for damage, which drops the clock in one step.
	_current = lerpf(_current, target, 1.0 - exp(-response * delta))

	if _current < OFF_EPSILON and target <= 0.0:
		_current = 0.0
		# Reset so the next time the player drops low the pulse opens on the
		# swing up rather than wherever the last one happened to stop.
		_phase = 0.0
		_apply(0.0, 1.0)
		visible = false
		return

	visible = true
	_phase = fmod(_phase + delta * lerpf(pulse_hz_min, pulse_hz_max, _current) * TAU, TAU)
	var beat := 0.5 - 0.5 * cos(_phase)
	var depth := pulse_depth * _current
	_apply(_current, lerpf(1.0 - depth, 1.0, beat))


# Maps time remaining onto 0..1. Inverted because the effect grows as the clock
# shrinks: appear_at reads 0 and full_at reads 1.
func _read_target() -> float:
	if Player.instance == null:
		return 0.0
	var clock := Player.instance.time_component
	if clock == null:
		return 0.0
	return clampf(inverse_lerp(appear_at, full_at, clock.time_percentage()), 0.0, 1.0)


# The beat rides on the opacity alone. Folded into the intensity it would drag
# the ring's radius along with it, and a vignette that inflates and deflates
# reads as the screen breathing rather than as a warning.
func _apply(value: float, beat: float) -> void:
	_material.set_shader_parameter("intensity", value)
	_material.set_shader_parameter("pulse", beat)


# The material is a scene sub-resource, so every instance of this scene shares
# one copy. Left shared, two vignettes would fight over the same intensity, and
# whatever the last one wrote would be saved back into the scene file.
func _own_material() -> ShaderMaterial:
	var owned := (material as ShaderMaterial).duplicate() as ShaderMaterial
	material = owned
	return owned
