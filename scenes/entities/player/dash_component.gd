class_name DashComponent
extends MovementComponent
## Movement for the player's dash, plus the pool of banked dashes it spends from.
##
## The pool is one charge deep by default, which behaves exactly like the single
## cooldown timer this replaced; upgrades widen it through dash_charges. Charges
## refill one at a time, so holding a spare never stops the next one recharging.

## Fired the instant a dash begins, carrying the dasher's position. Anything that
## should go off *on* the dash rather than during it — the shockwave, VFX — hangs
## off this instead of polling is_dashing(), so it lands exactly once per dash.
signal dash_started(origin: Vector2)

@export var dash_cooldown : Stat
## How many dashes can be banked at once. Left unset this reads as a single
## charge, so a scene that predates the pool still behaves the way it used to.
@export var dash_charges : Stat
@export var dash_length : float = 0.3

var _dashing : bool = false
var _dash_timer : float = 0.0
var _recharge_timer : float = 0.0
var _charges : int = 1
var _max_charges : int = 1
var _cooldown_timer : float = 10.0
var _dash_dir : Vector2 = Vector2.RIGHT

func _ready() -> void:
	# The player is rebuilt between runs, so starting full here is also what hands
	# a fresh run its dashes back.
	_max_charges = _read_max_charges()
	_charges = _max_charges


func tick(delta: float) -> void:
	_sync_max_charges()

	if _dashing:
		_dash_timer += delta
		if _dash_timer > dash_length:
			_dashing = false
			_dash_timer = 0.0
		return

	if _charges >= _max_charges:
		# Parked rather than left running: a full pool must not bank progress that
		# would refund the next charge the moment it is spent.
		_recharge_timer = 0.0
		return

	_recharge_timer += delta
	var cooldown := dash_cooldown.current_val()
	if cooldown <= 0.0:
		# A cooldown modded to zero refills the pool outright. Falling through to
		# the loop below would spin forever on a timer that never decreases.
		_charges = _max_charges
		_recharge_timer = 0.0
		return

	# A loop, not an if: a long frame — or a cooldown shorter than one — can cover
	# more than a single charge.
	while _recharge_timer >= cooldown and _charges < _max_charges:
		_recharge_timer -= cooldown
		_charges += 1
	if _charges >= _max_charges:
		_recharge_timer = 0.0


## [param dir] is the direction the dash commits to. It is sampled once here and
## held until the dash ends, so input during the dash can't steer it; a zero
## vector keeps the previous dash's direction rather than stalling in place.
func request_dash(start: bool = false, dir: Vector2 = Vector2.ZERO) -> void:
	if _dashing:
		return
	if not start:
		return
	if _charges <= 0:
		return
	_charges -= 1
	if _cooldown_timer >= dash_cooldown.current_val():
		SFX.play(&"dash")
		_dashing = true
		_dash_timer = 0.0
		if dir != Vector2.ZERO:
			_dash_dir = dir.normalized()
		dash_started.emit(body.global_position if body else Vector2.ZERO)


func is_dashing() -> bool:
	return _dashing


## Dashes available right now, and the size of the pool they come from. The HUD
## uses these to show banked charges; nothing else should need them.
func charges_available() -> int:
	return _charges


func max_charges() -> int:
	return _max_charges


## How far along the charge currently refilling is, from 0 to 1, or 1 when the
## pool is full and nothing is filling. Reported as a ratio so the HUD never needs
## to know the cooldown length, which moves with mods.
##
## Deliberately blind to how many charges are already banked: with a pool deeper
## than one, "can I dash" and "how close is the next charge" are different
## questions, and the indicators need the second one to keep sweeping while the
## player still holds a spare.
func recharge_progress() -> float:
	if _charges >= _max_charges:
		return 1.0
	var cooldown := dash_cooldown.current_val()
	if cooldown <= 0.0:
		return 1.0
	return clampf(_recharge_timer / cooldown, 0.0, 1.0)

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


# Taking a charge upgrade mid-run hands the new charge over immediately. The card
# says you can dash twice; waiting out a cooldown to find that out reads as the
# upgrade not having applied. Shrinking the pool takes the charge straight back.
func _sync_max_charges() -> void:
	var new_max := _read_max_charges()
	if new_max == _max_charges:
		return
	_charges = clampi(_charges + (new_max - _max_charges), 0, new_max)
	_max_charges = new_max


func _read_max_charges() -> int:
	if dash_charges == null:
		return 1
	return maxi(1, int(roundf(dash_charges.current_val())))
