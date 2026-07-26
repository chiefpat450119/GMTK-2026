# Trauma-based camera shake. Drop as a child of whatever owns the camera and
# point it at that camera.
#
# Callers add trauma (0..1) instead of driving the shake directly; trauma decays
# on its own and the actual displacement is trauma squared, so small hits stay
# subtle while stacked hits ramp up hard. Shake is layered on top of whatever
# offset/rotation the camera had at _ready, so it composes with camera follow.

class_name CameraShake
extends Node

static var instance: CameraShake

@export var camera: Camera2D
@export var max_angle: float = 3.0
@export var max_offset: float = 24.0
@export var angle_frequency: float = 10.0
@export var offset_frequency: float = 10.0
@export var decay: float = 0.55

var trauma: float = 0.0

const _LANE_ANGLE: float = 0.5
const _LANE_X: float = 100.5
const _LANE_Y: float = 200.5

var _noise := FastNoiseLite.new()
var _time: float = 0.0
var _base_offset: Vector2
var _base_rotation: float


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0

	if camera == null:
		push_warning("CameraShake has no camera assigned")
		return

	instance = self
	_base_offset = camera.offset
	_base_rotation = camera.rotation

	# Camera2D ignores its own rotation by default, which would eat the wobble.
	if max_angle > 0.0:
		camera.ignore_rotation = false


func _exit_tree() -> void:
	# The world this lives in is freed and rebuilt between runs. Without this the
	# static would point at a freed node, and shake() would call into it.
	if instance == self:
		instance = null


func _process(delta: float) -> void:
	if trauma <= 0.0 or camera == null:
		return

	_time += delta
	trauma = clampf(trauma - delta * decay, 0.0, 1.0)

	var shake := trauma * trauma
	var angle := max_angle * shake * _noise.get_noise_2d(_LANE_ANGLE, _time * angle_frequency)
	var off_x := max_offset * shake * _noise.get_noise_2d(_LANE_X, _time * offset_frequency)
	var off_y := max_offset * shake * _noise.get_noise_2d(_LANE_Y, _time * offset_frequency)

	camera.offset = _base_offset + Vector2(off_x, off_y)
	camera.rotation = _base_rotation + deg_to_rad(angle)


## Adds trauma to the active shaker. Safe to call before one exists.
## Roughly: 0.2 for a light tap, 0.4 for a hit, 1.0 for something big.
static func shake(amount: float) -> void:
	if instance == null:
		return
	instance.add_trauma(amount)


## Like shake(), but never pushes trauma past `ceiling`. For anything that
## repeats fast — firing, footsteps — so holding it down settles into a steady
## rattle instead of stacking all the way to a full-screen shake.
static func shake_capped(amount: float, ceiling: float) -> void:
	if instance == null:
		return
	instance.add_trauma_capped(amount, ceiling)


## Adds trauma to this shaker specifically, clamped to 1. Stacks with whatever
## shake is already running.
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Raises trauma toward `ceiling` and stops there. Trauma already above the
## ceiling was put there by something bigger than us, so it's left alone rather
## than pulled down.
func add_trauma_capped(amount: float, ceiling: float) -> void:
	if trauma >= ceiling:
		return
	trauma = clampf(minf(trauma + amount, ceiling), 0.0, 1.0)


## Cuts the shake immediately and snaps the camera back to its resting offset.
func clear() -> void:
	trauma = 0.0
	if camera == null:
		return
	camera.offset = _base_offset
	camera.rotation = _base_rotation


func _get_configuration_warnings() -> PackedStringArray:
	if camera == null:
		return PackedStringArray(["CameraShake needs a Camera2D assigned to shake."])
	return PackedStringArray()
