class_name ShooterEnemy
extends Enemy

@export var shot_damage := 2.0  # Damage per landed shot (before global atk mods)

# The art is an upright figure with the barrel out front, so the body never spins to
# face the player — it mirrors to the player's side and leans to aim. Recoil runs
# along the barrel rather than up the body, which is the axis the gun actually fires on.
const FACE_DEADZONE := 12.0  # Horizontal gap the player must clear before the sprite flips sides
const AIM_LEAN := 0.35  # Fraction of the angle to the player the body actually tips
const AIM_LEAN_MAX := deg_to_rad(12.0)  # Hard cap on the tip, so an upright figure never looks toppled
const LEAN_SMOOTH := 10.0  # Higher swings the body to its target lean faster
const RECOIL_LEAN := deg_to_rad(-8.0)  # Muzzle flips up the instant the shot leaves
const RECOIL_LEAN_DECAY := deg_to_rad(40.0)  # Radians per second the muzzle flip settles back out

const BRACE_PULL := 0.96  # Sprite scale.x multiplier at the end of the wind-up — gathers back over the gun
const BRACE_SQUASH := 0.94  # Sprite scale.y multiplier at the end of the wind-up — hunkers down
const RECOIL_COMPRESS := 0.82  # Sprite scale.x multiplier as the shot leaves — the kick along the barrel
const RECOIL_BULGE := 1.1  # Sprite scale.y multiplier at that instant, so the body keeps its volume
const RECOIL_KICK := 7.0  # Pixels the sprite slams backwards along the barrel
const RECOIL_TIME := 0.06  # Seconds for the kick to land
const SETTLE_TIME := 0.14  # Seconds for the spring back out of the kick

# Most of a shot cycle the post-shot hitch is allowed to eat. The hitch has to end
# before the next shot or the kiting branch never runs at all: the shot fires and
# re-arms the hitch on its own cooldown, so a hitch that outlasts the cycle leaves
# the shooter frozen where it stands forever. Clamping here keeps a balance pass
# from disabling the kite by nudging two numbers past each other.
const MAX_HITCH_FRACTION := 0.6

@export var shoot_interval: float  # Seconds between shots
@export var wait_interval: float # Seconds after shooting where it doesnt move
@export var projectile_scene: PackedScene
@export var min_range: float  # Backs away from the player inside this
@export var max_range: float  # Closes on the player outside this
@export var sprite: AnimatedSprite2D
@export var range_stat: Stat
@export var accel_time: float  # Seconds to reach full speed
@export var decel_time: float  # Seconds to coast to a stop

@onready var shoot_cooldown := Cooldown.new(shoot_interval)
@onready var wait_period := Cooldown.new(_hitch_time())
@onready var base_scale: Vector2 = sprite.scale
@onready var base_pos: Vector2 = sprite.position

var facing := -1.0  # 1 when the sprite faces +x, -1 when it faces -x
var recoil_lean := 0.0  # Muzzle flip riding on top of the aim lean; decays back to zero
var scale_tween: Tween  # Whoever is animating sprite.scale right now
var pos_tween: Tween  # Kept apart from the scale tween so neither can strand the other


func _ready() -> void:
	# Enemy._ready() is what hooks death up to the sand drop. GDScript does not
	# chain _ready(), so overriding it without this silently costs the drop.
	super()
	shoot_cooldown.start()
	# The idle loop (the spinning rotor) is left alone — it runs off the scene's autoplay
	# and its rate says nothing about firing, so nothing here touches speed_scale.
	_brace(shoot_interval)


func _physics_process(delta: float) -> void:
	shoot_cooldown.tick(delta)
	wait_period.tick(delta)

	var dir := get_to_player_vec()
	_update_facing(dir)

	recoil_lean = move_toward(recoil_lean, 0.0, RECOIL_LEAN_DECAY * delta)
	_lean_towards(_aim_lean(dir) + recoil_lean, delta)

	# Desired move direction; stays zero when the enemy wants to hold position,
	# so accelerate() eases the velocity down to a stop instead of cutting it.
	var move_dir := Vector2.ZERO

	if shoot_cooldown.is_done():
		_shoot(dir)
		wait_period.start()
	elif (not wait_period.is_started()) or wait_period.is_done():
		wait_period.stop()

		var dist := dir.length()
		if dist < range_stat.current_val(min_range):
			move_dir = -dir
		elif dist > range_stat.current_val(max_range):
			move_dir = dir

	# Called every frame so deceleration is applied even when move_dir is zero.
	accelerate(move_dir, 1, accel_time, decel_time, delta)


# How long the shooter actually holds still after a shot. See MAX_HITCH_FRACTION:
# a hitch that outlasts the shot cycle costs the shooter its kiting entirely, so an
# over-long wait_interval is trimmed to leave a movement window rather than obeyed.
func _hitch_time() -> float:
	return minf(wait_interval, shoot_interval * MAX_HITCH_FRACTION)


func _shoot(dir: Vector2) -> void:
	shoot_cooldown.start()

	# Parented to the scene, not the enemy, so shots outlive the shooter. The launch
	# angle comes from dir, not the body, so aiming never depended on the body spinning.
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.launch(global_position, dir.angle(), Projectile.Team.ENEMY, atk.damage_for(shot_damage))

	recoil_lean = RECOIL_LEAN

	# Slams back along the barrel, springs past its resting shape, then gathers into
	# the brace for the next shot — one chain, so nothing else can grab the scale.
	var kicked := Vector2(base_scale.x * RECOIL_COMPRESS, base_scale.y * RECOIL_BULGE)
	var tween := _take_scale_tween()
	tween.tween_property(sprite, "scale", kicked, RECOIL_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, SETTLE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", _braced_scale(), _brace_time()) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# The kick shoves the whole sprite backwards, which reads as a gun far more than
	# any amount of squash does.
	var recoiled := base_pos - Vector2(facing * RECOIL_KICK, 0.0)
	var kick := _take_pos_tween()
	kick.tween_property(sprite, "position", recoiled, RECOIL_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	kick.tween_property(sprite, "position", base_pos, SETTLE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Mirror the art to the player's side rather than rotating onto it. The deadzone
# stops a player hovering directly above or below from strobing the flip.
func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) < FACE_DEADZONE:
		return

	facing = signf(dir.x)
	sprite.flip_h = facing > 0.0  # The art is drawn facing -x


# How far the body tips to aim at a player above or below it, expressed as if the
# sprite faced +x. Only a fraction of the true angle, and capped tightly, since an
# upright figure reads as toppling long before a running one does.
func _aim_lean(dir: Vector2) -> float:
	var pitch := atan2(dir.y, maxf(absf(dir.x), 1.0))
	return clampf(pitch * AIM_LEAN, -AIM_LEAN_MAX, AIM_LEAN_MAX)


# Rotation is eased every frame rather than tweened, so it can never fight the
# scale tweens for ownership of the sprite's transform.
func _lean_towards(target: float, delta: float) -> void:
	sprite.rotation = lerp_angle(sprite.rotation, target * facing, 1.0 - exp(-LEAN_SMOOTH * delta))


# The wind-up: pulls back over the gun and hunkers down. Deliberately slight — the
# tell is meant to read as bracing, not as the body deflating.
func _braced_scale() -> Vector2:
	return Vector2(base_scale.x * BRACE_PULL, base_scale.y * BRACE_SQUASH)


func _brace_time() -> float:
	return maxf(shoot_interval - RECOIL_TIME - SETTLE_TIME, 0.05)


func _brace(duration: float) -> void:
	_take_scale_tween().tween_property(sprite, "scale", _braced_scale(), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# Only one tween may own sprite.scale at a time, otherwise the brace and the recoil
# fight over it frame to frame.
func _take_scale_tween() -> Tween:
	if scale_tween != null and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween()
	return scale_tween


func _take_pos_tween() -> Tween:
	if pos_tween != null and pos_tween.is_valid():
		pos_tween.kill()
	pos_tween = create_tween()
	return pos_tween
