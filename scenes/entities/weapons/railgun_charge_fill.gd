class_name RailgunChargeFill
extends Node2D

const BREECH_X : float = 150.0
const MUZZLE_X : float = 1184.0
const BREECH_TOP_Y : float = -178.0
const BREECH_BOTTOM_Y : float = -110.0
const MUZZLE_TOP_Y : float = -149.0
const MUZZLE_BOTTOM_Y : float = -93.0
# The body stays inside display range. A flat fill driven past 1.0 clamps on every
# channel and comes out white, so the overbright that the glow needs lives in a
# separate thin core instead — leaving the channel itself reading light blue.
const BODY_COLOR : Color = Color(0.55, 0.8, 1.0)
const BODY_GAIN_MIN : float = 0.85
const BODY_GAIN_MAX : float = 1.15

# Weighted late by CORE_GAIN_CURVE: most of the climb happens over the last stretch
# of the wind-up, which is what makes full charge read apart from nearly-charged.
const CORE_COLOR : Color = Color(0.85, 0.95, 1.0)
const CORE_INSET : float = 20.0
const CORE_GAIN_MIN : float = 0.9
const CORE_GAIN_MAX : float = 5.0
const CORE_GAIN_CURVE : float = 3.0

# Only once full, so the throb means "let go" rather than just "charging".
const PULSE_HZ : float = 9.0
const PULSE_DEPTH : float = 0.3

# Derived so the sparks follow the channel if its edges are ever retuned.
const SPARKS_POSITION := Vector2(
	(BREECH_X + MUZZLE_X) * 0.5,
	(BREECH_TOP_Y + BREECH_BOTTOM_Y + MUZZLE_TOP_Y + MUZZLE_BOTTOM_Y) * 0.25
)

## Arcs venting off the coil while it sits full. Optional — the bar works alone.
@export var sparks : EnergySparks

## 0 leaves the channel dark, 1 fills it to the muzzle.
var charge_ratio : float = 0.0:
	set(value):
		var clamped := clampf(value, 0.0, 1.0)
		if is_equal_approx(charge_ratio, clamped):
			return
		charge_ratio = clamped
		var full := is_equal_approx(charge_ratio, 1.0)
		if full != _full:
			_full = full
			_pulse_time = 0.0
			# The pulse is the only thing here that needs a clock, so the frame
			# callback only runs while the coil is actually sitting full.
			set_process(full)
			if sparks:
				sparks.emitting = full
		queue_redraw()

var flipped : bool = false:
	set(value):
		if flipped == value:
			return
		flipped = value
		_place_sparks()
		queue_redraw()

var _full : bool = false
var _pulse_time : float = 0.0

func _ready() -> void:
	set_process(false)
	_place_sparks()

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _place_sparks() -> void:
	if sparks:
		var y := SPARKS_POSITION.y
		sparks.position = Vector2(SPARKS_POSITION.x, -y if flipped else y)

func _draw() -> void:
	if charge_ratio <= 0.0:
		return

	if flipped:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, -1.0))

	var body := BODY_COLOR * lerpf(BODY_GAIN_MIN, BODY_GAIN_MAX, charge_ratio)
	body.a = 1.0
	draw_colored_polygon(_bar_polygon(0.0), body)

	var core := CORE_COLOR * _core_gain()
	core.a = 1.0
	draw_colored_polygon(_bar_polygon(CORE_INSET), core)

func _core_gain() -> float:
	var gain := lerpf(CORE_GAIN_MIN, CORE_GAIN_MAX, pow(charge_ratio, CORE_GAIN_CURVE))
	if _full:
		gain *= 1.0 + PULSE_DEPTH * sin(_pulse_time * TAU * PULSE_HZ)
	return gain

## The charged part of the channel, breech end to leading edge, pulled in from the
## rails by [param inset].
func _bar_polygon(inset: float) -> PackedVector2Array:
	var tip_x := lerpf(BREECH_X, MUZZLE_X, charge_ratio)
	return PackedVector2Array([
		Vector2(BREECH_X, BREECH_TOP_Y + inset),
		Vector2(tip_x, lerpf(BREECH_TOP_Y, MUZZLE_TOP_Y, charge_ratio) + inset),
		Vector2(tip_x, lerpf(BREECH_BOTTOM_Y, MUZZLE_BOTTOM_Y, charge_ratio) - inset),
		Vector2(BREECH_X, BREECH_BOTTOM_Y - inset),
	])
