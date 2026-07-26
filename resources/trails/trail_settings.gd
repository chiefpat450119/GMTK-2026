class_name TrailSettings
extends Resource
## The streak a weapon's shots drag behind them.
##
## Every gun and the shooter enemy fire the same projectile.tscn, so the trail
## cannot live on the bullet — in flight it is the only thing that tells a railgun
## slug apart from a shotgun pellet. It lives on the shooter instead, which hands
## it to each shot at spawn. One resource is shared by all ten pellets of a blast.


## Seconds of flight the tail holds on to. This is the knob that separates the
## weapons. At a given speed it *is* the length of the streak, and expressing it as
## time rather than as a point count keeps that length honest when a shot is faster
## or slower than another, or when the framerate dips.
@export_range(0.0, 2.0, 0.01) var lifetime := 0.1

## Thickness at the head, in pixels, before the taper.
@export_range(0.0, 200.0, 0.5) var width := 6.0

## Tint of the streak. Channels above 1.0 are deliberate and legal here — the
## viewport is HDR and the world has a bloom pass, so an over-bright colour is what
## makes a shot glow rather than merely being pale.
@export var color := Color(1.0, 1.0, 1.0)

## Pixels the shot must cover before another point is committed. Purely a budget:
## the head of the streak tracks the bullet every frame regardless, so raising this
## costs smoothness on tight curves, which straight-flying shots do not have.
@export_range(0.5, 32.0, 0.5) var min_distance := 4.0

## Additive blending, for anything meant to read as light. Off for smoke or dust,
## which has to be able to darken what it crosses.
@export var additive := true

## Optional. Alpha and colour along the streak, tail (0.0) to head (1.0). Left
## empty, the trail builds a ramp from `color` that fades the tail out to nothing.
@export var gradient : Gradient

## Optional. Width along the streak, same direction, as a multiplier on `width`.
## Left empty, the trail tapers from a point at the tail to full width at the head.
@export var width_curve : Curve
