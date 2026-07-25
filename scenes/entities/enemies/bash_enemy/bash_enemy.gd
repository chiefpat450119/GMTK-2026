class_name BashEnemy
extends Enemy

# The art is drawn side-on, so the body never spins to face the player the way a
# cube could — it flips to the player's side and leans, and the run cycle carries
# the sense of direction and effort instead.
const FACE_DEADZONE := 12.0  # Horizontal gap the player must clear before the sprite flips sides
const AIM_LEAN := 0.45  # Fraction of the angle to the player the body actually tips
const AIM_LEAN_MAX := deg_to_rad(16.0)  # Hard cap on the tip, so the side-on read never breaks
const CHARGE_LEAN := deg_to_rad(-13.0)  # Rears its head back through the wind-up
const BASH_LEAN := deg_to_rad(11.0)  # Drops its head into the charge
const LEAN_SMOOTH := 12.0  # Higher swings the body to its target lean faster

const CHARGE_SQUASH := 0.85  # Sprite scale.y multiplier at the end of the wind-up
const CHARGE_STRETCH := 1.07  # Sprite scale.x multiplier at the end of the wind-up
const BASH_SQUASH := 0.92  # Sprite scale.y multiplier the instant the bash fires
const BASH_STRETCH := 1.16  # Sprite scale.x multiplier the instant the bash fires
const CHARGE_TINT := Color(1.4, 0.45, 0.4)  # Hot red tell; stays bright enough to read the art through
const RECOVER_TIME := 0.1  # Seconds for the sprite to snap out of the coil as the bash fires
const SETTLE_TIME := 0.18  # Seconds for the launch stretch to ease back to rest

const IDLE_ANIM_SCALE := 0.25  # Legs keep pacing rather than freezing mid-stride when stopped
const CHARGE_ANIM_SCALE := 3.2  # Legs churn this much faster by the end of the wind-up
const BASH_ANIM_SCALE := 4.5  # Legs blur while the bash travels
const ANIM_SMOOTH := 10.0  # Higher ramps the run cycle to its target rate faster

@export var attack_interval: float  # Seconds between attacks
@export var charge_time: float  # Wind-up before the bash fires
@export var bash_duration: float  # How long the bash travels for
@export var bash_speed: float  # Speed multiplier while bashing
@export var charging_speed: float  # Speed multiplier while winding up
@export var attack_range: float  # Distance at which the enemy commits to an attack
@export var range_stat: Stat
@export var accel_time: float  # Seconds to reach full speed (approach only)
@export var decel_time: float  # Seconds to coast to a stop (approach only)

@export var sprite: AnimatedSprite2D

@onready var attack_cooldown := Cooldown.new(attack_interval)
@onready var charge_timer := Cooldown.new(charge_time)
@onready var bash_timer := Cooldown.new(bash_duration)
@onready var base_scale: Vector2 = sprite.scale

var bash_dir: Vector2
var facing := 1.0  # 1 when the sprite faces +x, -1 when it faces -x
var scale_tween: Tween  # Whoever is animating sprite.scale right now
var tint_tween: Tween  # Kept apart from the scale tween so neither can strand the other


func _ready() -> void:
	super()
	# Hit detection lives on the atk component; the bash only decides when its
	# hurtbox is live, so contact only hurts while the enemy is actually bashing.
	attack_cooldown.start()
	# The run cycle is left playing for good and paced with speed_scale, so the legs
	# and the movement can never fall out of step.
	sprite.play()


func _physics_process(delta: float) -> void:
	attack_cooldown.tick(delta)
	charge_timer.tick(delta)
	bash_timer.tick(delta)

	# Committed to the charge: facing stays locked to the direction it launched at,
	# so a player who sidesteps doesn't drag the sprite around with them.
	if bash_timer.is_started():
		_update_bash()
		_lean_towards(BASH_LEAN, delta)
		_run_at(BASH_ANIM_SCALE, delta)
		return

	var dir := get_to_player_vec()
	_update_facing(dir)

	if charge_timer.is_started():
		_update_charge(dir, delta)
		return

	# Approach/idle movement eases in and out; charging and bashing stay instant.
	# move_dir stays zero to coast to a stop while waiting or holding range.
	var move_dir := Vector2.ZERO

	if attack_cooldown.is_started() and not attack_cooldown.is_done():
		pass  # Waiting between attacks — coast to a stop.
	elif attack_cooldown.is_done() and dir.length() < attack_range:
		_start_charge()
		return
	elif dir.length() > range_stat.current_val(attack_range):
		move_dir = dir

	accelerate(move_dir, 1, accel_time, decel_time, delta)

	# The run cycle rides actual speed, so the legs never skate over the ground.
	var max_speed := movement.speed_stat.current_val(movement.base_speed)
	var stride := velocity.length() / maxf(max_speed, 0.001)
	_run_at(maxf(stride, IDLE_ANIM_SCALE), delta)
	_lean_towards(_aim_lean(dir), delta)


func _start_charge() -> void:
	attack_cooldown.stop()
	charge_timer.start()

	# Coils down and thickens — the weight gathering before the launch.
	var coiled := Vector2(base_scale.x * CHARGE_STRETCH, base_scale.y * CHARGE_SQUASH)
	_take_scale_tween().tween_property(sprite, "scale", coiled, charge_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_take_tint_tween().tween_property(sprite, "modulate", CHARGE_TINT, charge_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _update_charge(dir: Vector2, delta: float) -> void:
	move_towards_player(charging_speed)

	# Barely moving, but the legs churn harder the closer the wind-up gets to firing.
	_run_at(lerpf(1.0, CHARGE_ANIM_SCALE, charge_timer.percent_complete()), delta)
	_lean_towards(CHARGE_LEAN, delta)

	if charge_timer.is_done():
		charge_timer.stop()
		_start_bash(dir)


func _start_bash(dir: Vector2) -> void:
	bash_dir = dir.normalized()  # Locked here, so the bash can be dodged
	bash_timer.start()
	atk.set_active(true)

	# Snaps out of the coil and elongates along the charge, then settles mid-bash.
	var launched := Vector2(base_scale.x * BASH_STRETCH, base_scale.y * BASH_SQUASH)
	var tween := _take_scale_tween()
	tween.tween_property(sprite, "scale", launched, RECOVER_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, SETTLE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_take_tint_tween().tween_property(sprite, "modulate", Color.WHITE, RECOVER_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _update_bash() -> void:
	movement.move(bash_dir * bash_speed)

	if bash_timer.is_done():
		bash_timer.stop()
		atk.set_active(false)
		attack_cooldown.start()


# Mirror the art to the player's side rather than rotating onto it. The deadzone
# stops a player hovering directly above or below from strobing the flip.
func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) < FACE_DEADZONE:
		return

	facing = signf(dir.x)
	sprite.flip_h = facing > 0.0  # The art is drawn facing -x


# How far the body tips to point at a player above or below it, expressed as if the
# sprite faced +x. Only a fraction of the true angle, and capped, so the sprite reads
# as a running animal leaning rather than a sprite spun on its centre.
func _aim_lean(dir: Vector2) -> float:
	var pitch := atan2(dir.y, maxf(absf(dir.x), 1.0))
	return clampf(pitch * AIM_LEAN, -AIM_LEAN_MAX, AIM_LEAN_MAX)


# Rotation is eased every frame rather than tweened, so it can never fight the
# scale tweens for ownership of the sprite's transform.
func _lean_towards(target: float, delta: float) -> void:
	sprite.rotation = lerp_angle(sprite.rotation, target * facing, 1.0 - exp(-LEAN_SMOOTH * delta))


func _run_at(target: float, delta: float) -> void:
	sprite.speed_scale = lerpf(sprite.speed_scale, target, 1.0 - exp(-ANIM_SMOOTH * delta))


# Only one tween may own sprite.scale at a time, otherwise the coil and the launch
# stretch fight over it frame to frame.
func _take_scale_tween() -> Tween:
	if scale_tween != null and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween()
	return scale_tween


func _take_tint_tween() -> Tween:
	if tint_tween != null and tint_tween.is_valid():
		tint_tween.kill()
	tint_tween = create_tween()
	return tint_tween
