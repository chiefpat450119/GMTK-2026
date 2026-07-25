class_name DashComponent
extends MovementComponent

@export var dash_cooldown : Stat
@export var dash_length : float = 0.3

var _dashing : bool = false
var _dash_timer : float = 0.0
var _cooldown_timer : float = 10.0


func tick(delta: float) -> void:
	if _dashing:
		_dash_timer += delta
		if _dash_timer > dash_length:
			_dashing = false
			_dash_timer = 0.0
			_cooldown_timer = 0.0
	else:
		_cooldown_timer += delta


func request_dash(start: bool = false) -> void:
	if _dashing:
		return
	if not start:
		return
	if _cooldown_timer >= dash_cooldown.current_val():
		_dashing = true
		_dash_timer = 0.0


func is_dashing() -> bool:
	return _dashing


## How ready the dash is, from 0 (just spent) to 1 (usable). Reported as a ratio
## so the HUD never needs to know the cooldown length, which moves with mods.
func cooldown_progress() -> float:
	if _dashing:
		return 0.0
	var cooldown := dash_cooldown.current_val()
	if cooldown <= 0.0:
		return 1.0
	return clampf(_cooldown_timer / cooldown, 0.0, 1.0)