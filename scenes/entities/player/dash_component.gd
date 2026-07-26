class_name DashComponent
extends MovementComponent

@export var dash_cooldown : Stat
@export var dash_length : float = 0.3

var _dashing : bool = false
var _dash_timer : float = 0.0
var _cooldown_timer : float = 10.0
var _dash_dir : Vector2 = Vector2.RIGHT


func tick(delta: float) -> void:
	if _dashing:
		_dash_timer += delta
		if _dash_timer > dash_length:
			_dashing = false
			_dash_timer = 0.0
			_cooldown_timer = 0.0
	else:
		_cooldown_timer += delta


## [param dir] is the direction the dash commits to. It is sampled once here and
## held until the dash ends, so input during the dash can't steer it; a zero
## vector keeps the previous dash's direction rather than stalling in place.
func request_dash(start: bool = false, dir: Vector2 = Vector2.ZERO) -> void:
	if _dashing:
		return
	if not start:
		return
	if _cooldown_timer >= dash_cooldown.current_val():
		SFX.play(&"dash")
		_dashing = true
		_dash_timer = 0.0
		if dir != Vector2.ZERO:
			_dash_dir = dir.normalized()


func is_dashing() -> bool:
	return _dashing


## Direction the in-progress dash is locked to. Callers use it to pick the
## matching sprite so the visuals can't drift from the movement.
func dash_direction() -> Vector2:
	return _dash_dir


## Travels along the locked-in direction, ignoring the current input.
func move_dash() -> void:
	move(_dash_dir)


## How ready the dash is, from 0 (just spent) to 1 (usable). Reported as a ratio
## so the HUD never needs to know the cooldown length, which moves with mods.
func cooldown_progress() -> float:
	if _dashing:
		return 0.0
	var cooldown := dash_cooldown.current_val()
	if cooldown <= 0.0:
		return 1.0
	return clampf(_cooldown_timer / cooldown, 0.0, 1.0)
