class_name CameraFollow
extends Node

@export var camera: Camera2D

@export_group("Follow")
## How hard the camera is pulled toward its target, per second. Higher is
## tighter and more responsive; lower is floatier and more prone to lagging
## behind during a dash.
@export var follow_speed: float = 18.0
## Constant shift applied to the anchor, before any look-ahead.
@export var follow_offset: Vector2 = Vector2.ZERO

@export_group("Look Ahead")
## Fraction of the cursor's distance from the centre of the screen that the view
## leads by — 0.2 means the cursor pulls the view a fifth of the way toward it.
@export_range(0.0, 0.9, 0.01) var cursor_lead: float = 0.18
## Ceiling on the cursor lead, in pixels. Keeps the player on screen no matter
## how far out the cursor goes.
@export var cursor_lead_max: float = 160.0
## Cursor distance that produces no lead at all. Without it, small movements
## with the cursor resting on the player would drift the whole view.
@export var cursor_deadzone: float = 40.0
## Seconds of player velocity to lead by. This is what makes a dash feel like it
## goes somewhere — velocity spikes, so the view surges ahead and settles back
## without anything having to tell it a dash happened.
@export var velocity_lead: float = 0.12
## Ceiling on the velocity lead, in pixels.
@export var velocity_lead_max: float = 120.0
## How fast the look-ahead itself eases, per second. Kept below follow_speed so
## the camera stays tight to the player while the framing drifts, but not so far
## below that pointing somewhere takes a beat to register.
@export var lead_speed: float = 9.0

var _acquired: bool = false
var _lead: Vector2 = Vector2.ZERO


func _ready() -> void:
	if camera == null:
		push_warning("CameraFollow has no camera assigned")
		return
	if camera.position_smoothing_enabled:
		push_warning("CameraFollow: disable position_smoothing on the camera, follow_speed already smooths")

	camera.top_level = true
	snap()


# The player moves in _physics_process
func _physics_process(delta: float) -> void:
	if camera == null or Player.instance == null:
		_acquired = false
		return

	var player := Player.instance
	var anchor := player.global_position + follow_offset
	var desired_lead := _cursor_lead() + _velocity_lead(player)

	# Nothing to ease from on the first frame the player exists.
	if not _acquired:
		_acquired = true
		_lead = desired_lead
		_teleport(anchor + _lead)
		return

	# Two exponential decays at different rates: the lead crawls toward where it
	# wants to be, and the camera chases the anchor plus that lead. The exp() is
	# what keeps both identical regardless of tick rate.
	_lead = desired_lead + (_lead - desired_lead) * exp(-lead_speed * delta)

	var target := anchor + _lead
	camera.global_position = target + (camera.global_position - target) * exp(-follow_speed * delta)


## Frames the player immediately, look-ahead included. For run starts and
## teleports — anywhere easing across the gap would read as the camera flying.
func snap() -> void:
	if camera == null or Player.instance == null:
		return
	var player := Player.instance
	_lead = _cursor_lead() + _velocity_lead(player)
	_acquired = true
	_teleport(player.global_position + follow_offset + _lead)


func _cursor_lead() -> Vector2:
	if cursor_lead <= 0.0:
		return Vector2.ZERO

	var from_centre := _cursor_screen_offset()
	var distance := from_centre.length()
	if distance <= cursor_deadzone:
		return Vector2.ZERO

	var reach := minf((distance - cursor_deadzone) * cursor_lead, cursor_lead_max)
	return from_centre / distance * reach


func _cursor_screen_offset() -> Vector2:
	var viewport := camera.get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var centre := viewport.get_visible_rect().size * 0.5
	return (viewport.get_mouse_position() - centre) / camera.zoom


func _velocity_lead(player: Player) -> Vector2:
	if velocity_lead <= 0.0:
		return Vector2.ZERO
	return (player.velocity * velocity_lead).limit_length(velocity_lead_max)


func _teleport(to: Vector2) -> void:
	camera.global_position = to
	# Physics interpolation is on project-wide, so a hard move has to be declared
	# or the camera spends a frame sliding in from where it used to be.
	camera.reset_physics_interpolation()


func _get_configuration_warnings() -> PackedStringArray:
	if camera == null:
		return PackedStringArray(["CameraFollow needs a Camera2D assigned to follow with."])
	return PackedStringArray()
