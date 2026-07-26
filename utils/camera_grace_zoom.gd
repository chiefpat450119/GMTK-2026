# Pushes the view in slightly while the death grace window is open, and lets it
# back out when the player survives it. Drop as a child of whatever owns the
# camera and point it at that camera.
#
# The step is added to whatever zoom the camera rests at rather than tweening to
# a fixed value, so retuning the camera's framing doesn't quietly retune how far
# grace pushes in.

class_name CameraGraceZoom
extends Node

@export var camera: Camera2D
## How much zoom the grace window adds on top of the camera's resting zoom.
## Positive pushes the view in.
@export var zoom_step: float = 0.25
@export var zoom_in_time: float = 0.1
## Longer than the push in. The snap in is the punctuation; the way out is the
## release, and matching their speeds makes surviving read as a second jolt.
@export var zoom_out_time: float = 0.22

## Curves are exported so the feel can be swept in the Inspector without a code
## change. Both default to EASE_OUT — all the speed at the start, decelerating
## into rest. EASE_IN is the one to avoid on a move this short: it accelerates
## into the target and stops dead there, which reads as a hitch rather than an
## arrival.
@export_group("Curve")
@export var zoom_in_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var zoom_in_ease: Tween.EaseType = Tween.EASE_OUT
@export var zoom_out_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var zoom_out_ease: Tween.EaseType = Tween.EASE_OUT

var _base_zoom: Vector2
var _tween: Tween


func _ready() -> void:
	if camera == null:
		push_warning("CameraGraceZoom has no camera assigned")
		return

	_base_zoom = camera.zoom

	# Player claims its static in _enter_tree, which runs before this _ready, so
	# the clock is already reachable by the time the camera comes up.
	var clock := _clock()
	if clock == null:
		push_warning("CameraGraceZoom found no TimeComponent to watch")
		return
	clock.grace_started.connect(_on_grace_started)
	clock.grace_survived.connect(_on_grace_survived)


func _on_grace_started() -> void:
	_zoom_to(_base_zoom + Vector2(zoom_step, zoom_step), zoom_in_time, zoom_in_trans, zoom_in_ease)


func _on_grace_survived() -> void:
	_zoom_to(_base_zoom, zoom_out_time, zoom_out_trans, zoom_out_ease)


# Death is deliberately not handled: the run ends framed the way it was lost,
# and the world is rebuilt from scratch for the next one.
func _zoom_to(target: Vector2, duration: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if camera == null:
		return

	# Surviving inside the push-in has to catch the zoom where it actually is,
	# not wherever the previous tween was headed.
	if _tween != null and _tween.is_valid():
		_tween.kill()

	# Scaled by how far there is left to go, so surviving a few frames into the
	# push-in doesn't spend the full duration crawling back across a gap that was
	# never opened. A move interrupted early should return just as early.
	if absf(zoom_step) > 0.0:
		duration *= clampf(absf(camera.zoom.x - target.x) / absf(zoom_step), 0.0, 1.0)

	if duration <= 0.0:
		camera.zoom = target
		return

	_tween = create_tween()
	# Grace runs the engine in slow motion, and a tween on scaled time would take
	# the slowdown's own factor longer to arrive — the push-in would still be
	# travelling well after the moment it exists to punctuate.
	_tween.set_ignore_time_scale(true)
	_tween.set_trans(trans).set_ease(ease_type)
	_tween.tween_property(camera, "zoom", target, duration)


func _clock() -> TimeComponent:
	if Player.instance == null:
		return null
	return Player.instance.time_component


func _get_configuration_warnings() -> PackedStringArray:
	if camera == null:
		return PackedStringArray(["CameraGraceZoom needs a Camera2D assigned to zoom."])
	return PackedStringArray()
