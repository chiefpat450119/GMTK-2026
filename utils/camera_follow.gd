class_name CameraFollow
extends Node

@export var camera: Camera2D
@export var follow_speed: float = 8.0
@export var follow_offset: Vector2 = Vector2.ZERO

var _acquired: bool = false


func _ready() -> void:
	if camera == null:
		push_warning("CameraFollow has no camera assigned")
		return
	if camera.position_smoothing_enabled:
		push_warning("CameraFollow: disable position_smoothing on the camera, follow_speed already smooths")


# The player moves in _physics_process, so follow there — sampling it during
# _process would read a stale position on frames between physics ticks.
func _physics_process(delta: float) -> void:
	if camera == null or Player.instance == null:
		_acquired = false
		return

	var target := Player.instance.global_position + follow_offset

	# Nothing to ease from on the first frame the player exists.
	if not _acquired:
		_acquired = true
		camera.global_position = target
		return

	# Exponential decay toward the target. The exp() is what keeps the easing
	# identical regardless of tick rate.
	camera.global_position = target + (camera.global_position - target) * exp(-follow_speed * delta)


func snap() -> void:
	if camera == null or Player.instance == null:
		return
	camera.global_position = Player.instance.global_position + follow_offset
	_acquired = true


func _get_configuration_warnings() -> PackedStringArray:
	if camera == null:
		return PackedStringArray(["CameraFollow needs a Camera2D assigned to follow with."])
	return PackedStringArray()
