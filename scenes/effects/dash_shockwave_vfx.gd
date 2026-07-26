class_name DashShockwaveVFX
extends Node2D
## The ring a dash shockwave leaves behind, drawn at exactly the blast radius.
##
## Drawn with _draw() rather than assembled from a scaled sprite on purpose. The
## whole job of the ring is to teach the player how far the blast reaches, and a
## texture would carry its own size that someone has to keep in step with the
## radius stat by hand — the first time those drift the ring is actively lying.
## Here the radius it is drawn at *is* the radius the damage query used.
##
## Parented to the world rather than to the player, so it stays where the dash
## started instead of being dragged along by the dash that set it off.

## Seconds from the blast to the ring vanishing.
const DURATION := 0.3
## Where the ring opens from, as a fraction of the blast radius. Starting at zero
## reads as a spark growing outward; starting near the real size reads as an area
## being struck at once, which is what actually happened.
const START_FRACTION := 0.55
const RING_WIDTH := 5.0
## The disc inside the ring. Faint — it marks the area without hiding the enemies
## in it, which are the thing the player is looking at.
const FILL_ALPHA := 0.16
const COLOR := Color(0.98, 0.88, 0.62)
## Roughly how many pixels of arc one segment should span. The segment count is
## derived from this per blast rather than fixed, because a count that looks round
## at one radius turns into a visible polygon at three times the size.
const ARC_SEGMENT_LENGTH := 12.0
const ARC_POINTS_MIN := 24
const ARC_POINTS_MAX := 256

# Where the dash went off, in world space. Applied in _ready() rather than at
# setup time, because a global position means nothing until we're in the tree.
var _origin := Vector2.ZERO
var _radius := 0.0
var _elapsed := 0.0


## Must be called *before* the effect is added to the tree.
func setup(origin: Vector2, radius: float) -> void:
	_origin = origin
	_radius = maxf(radius, 0.0)


func _ready() -> void:
	if _radius <= 0.0:
		queue_free()
		return
	global_position = _origin
	# Over the ground and the enemies it just hit, under the player, who should
	# stay readable through their own shockwave.
	z_index = 1
	# Physics interpolation is on, so without this the ring spends its first frame
	# streaking in from wherever it was spawned to where it belongs.
	reset_physics_interpolation()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_elapsed / DURATION, 0.0, 1.0)
	# Eased hard, so the ring snaps out to the full blast radius within the first
	# few frames and spends the rest of its life sitting on it. The size that
	# lingers is the one the player reads as the range, so it has to be the true
	# one; the opening is punch, not information.
	var opened := 1.0 - pow(1.0 - k, 4.0)
	var r := _radius * lerpf(START_FRACTION, 1.0, opened)
	var fade := 1.0 - k

	var points := clampi(int(TAU * r / ARC_SEGMENT_LENGTH), ARC_POINTS_MIN, ARC_POINTS_MAX)
	draw_circle(Vector2.ZERO, r, Color(COLOR, FILL_ALPHA * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, points, Color(COLOR, fade), RING_WIDTH, true)
