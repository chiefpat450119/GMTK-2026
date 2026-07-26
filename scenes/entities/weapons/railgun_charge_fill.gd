class_name RailgunChargeFill
extends Node2D

const BREECH_X : float = 150.0
const MUZZLE_X : float = 1184.0
const BREECH_TOP_Y : float = -178.0
const BREECH_BOTTOM_Y : float = -110.0
const MUZZLE_TOP_Y : float = -149.0
const MUZZLE_BOTTOM_Y : float = -93.0
const BAR_COLOR : Color = Color(0.66, 0.87, 1.0)

const ALPHA_MIN : float = 0.75
const ALPHA_MAX : float = 1.0

## 0 leaves the channel dark, 1 fills it to the muzzle.
var charge_ratio : float = 0.0:
	set(value):
		var clamped := clampf(value, 0.0, 1.0)
		if is_equal_approx(charge_ratio, clamped):
			return
		charge_ratio = clamped
		queue_redraw()

var flipped : bool = false:
	set(value):
		if flipped == value:
			return
		flipped = value
		queue_redraw()

func _draw() -> void:
	if charge_ratio <= 0.0:
		return

	if flipped:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, -1.0))

	var bar := BAR_COLOR
	bar.a = lerpf(ALPHA_MIN, ALPHA_MAX, charge_ratio)
	draw_colored_polygon(_bar_polygon(), bar)

## The charged part of the channel, breech end to leading edge.
func _bar_polygon() -> PackedVector2Array:
	var tip_x := lerpf(BREECH_X, MUZZLE_X, charge_ratio)
	return PackedVector2Array([
		Vector2(BREECH_X, BREECH_TOP_Y),
		Vector2(tip_x, lerpf(BREECH_TOP_Y, MUZZLE_TOP_Y, charge_ratio)),
		Vector2(tip_x, lerpf(BREECH_BOTTOM_Y, MUZZLE_BOTTOM_Y, charge_ratio)),
		Vector2(BREECH_X, BREECH_BOTTOM_Y),
	])
