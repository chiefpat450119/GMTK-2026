class_name MeleeEnemy
extends Enemy

# Every timing below is exported because this script drives bodies of very different
# weights: the fast melee enemy patters, the tank lumbers. A bounce tuned for one reads
# as the wrong creature on the other, so the defaults here are the light-and-fast tuning
# and a heavier enemy overrides them in its own scene.

@export var accel_time: float  # Seconds to reach full speed
@export var decel_time: float  # Seconds to coast to a stop
@export var sprite: Node2D

# One looping bounce while moving. Slower bodies want a longer cycle and a deeper
# squash: a quick shallow patter on something heavy reads as a much lighter creature.
@export_group("Walk Bob")
@export var walk_squash := 0.95  # scale multiplier on the squashed axis of the walk bob
@export var walk_cycle_time := 0.36  # Seconds for one full squash -> stretch -> squash bounce
@export var walk_settle_time := 0.12  # Seconds to ease back to the resting scale when stopping
@export var walk_min_speed := 5.0  # Below this speed the enemy counts as standing still

# The art is a round body carried on four thin legs with nothing to swing, so the
# strike is a pounce: it throws its whole weight at the player and pitches over its
# front legs. Rearing up *tall and narrow* is also the exact inverse of the flattening
# squash HitFeedback plays on damage, so a strike can never be misread as a flinch.
@export_group("Strike")
@export var lunge_dist := 26.0  # Pixels the body throws itself at the player at full extension
@export var lunge_stretch := 1.18  # scale.y multiplier there — rears up over the target
@export var lunge_narrow := 0.87  # scale.x multiplier there, so the volume roughly holds
@export var lunge_time := 0.05  # Seconds to throw out to full extension; keep <= hitstop_time
@export var lunge_return := 0.3  # Seconds for the sprite to trail back to rest behind the recoil
@export var lunge_pitch_deg := 15.0  # Tips this far into the player as it connects
@export var rear_pitch_deg := -12.0  # Then whips back the other way as the recoil throws it off
@export var pitch_smooth := 14.0  # Higher snaps the pitch to its target faster
@export var hitstop_time := 0.06  # Brief freeze the instant a hit lands, so the strike has a beat

# The recoil should read as roughly the same shove relative to how fast the body walks,
# so a slow enemy wants a much smaller speed here than a fast one.
@export_group("Recoil")
@export var hit_knockback := 950.0  # Recoil speed away from the player the instant a hit lands
@export var knockback_time := 0.28  # Seconds for the recoil to decay to a stop

@onready var base_scale: Vector2 = sprite.scale
@onready var base_pos: Vector2 = sprite.position
@onready var hitstop := Cooldown.new(hitstop_time)
@onready var knockback := Cooldown.new(knockback_time)

var knockback_dir: Vector2
var pitch_facing := 1.0  # Which way the pounce tips over; locked when the strike lands
var scale_tween: Tween  # Whoever is animating sprite.scale right now
var pos_tween: Tween  # Whoever is animating sprite.position right now
var walking: bool  # True while the walk bob owns the scale tween


func _ready() -> void:
	super()
	# Hit detection lives on the atk component; this enemy only reacts to it.
	atk.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	hitstop.tick(delta)
	knockback.tick(delta)

	# Pitch is eased every frame rather than tweened, so it can never fight the scale
	# and position tweens for ownership of the sprite's transform.
	_pitch_towards(_strike_pitch(), delta)

	# Freeze in place for a beat the instant a hit lands. The pounce runs out to full
	# extension across this window, so the strike lands on a body that is holding still.
	if hitstop.is_started() and not hitstop.is_done():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Recoiling: coast backwards, decaying to a stop. This reads the hit rather than
	# pacing it — the atk component's attack_interval is what gates the next strike.
	if knockback.is_started() and not knockback.is_done():
		var t := knockback.time_left / knockback_time  # 1 -> 0 over the recoil
		velocity = knockback_dir * hit_knockback * t
		move_and_slide()
		return

	accelerate_towards_player(1, accel_time, decel_time, delta)

	# Bob only while actually walking, so an enemy coasting to a stop settles flat.
	if velocity.length() > walk_min_speed:
		_start_walk_anim()
	else:
		_stop_walk_anim()


# Pounce off damaging hits only. A contact the rate limiter ate isn't a strike, so the
# enemy stays on the player and keeps pressuring instead of flinching for free.
func _on_hit_landed(_body: Node2D, _damage: float) -> void:
	# Straight at the player; fall back to our heading if we're sitting dead-centre on
	# them and the vector is degenerate.
	var towards := get_to_player_vec()
	if towards.length() < 0.01:
		towards = velocity
	var dir := towards.normalized() if towards.length() > 0.01 else Vector2.RIGHT

	_play_attack_anim(dir)
	_recoil(dir)


# The pounce. Deliberately carries no colour flash: a red flash is damage taken, and
# this enemy is the one dealing it.
func _play_attack_anim(dir: Vector2) -> void:
	walking = false  # The pounce takes the scale over from the walk bob.
	# Tip over whichever side the player is on. A player straight above or below gets
	# the lunge without a pitch, rather than an arbitrary lean.
	pitch_facing = signf(dir.x)

	var extended := Vector2(base_scale.x * lunge_narrow, base_scale.y * lunge_stretch)
	var scale_t := _take_scale_tween()
	scale_t.tween_property(sprite, "scale", extended, lunge_time) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	scale_t.tween_property(sprite, "scale", base_scale, lunge_return) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Thrown out over the player while the body is frozen, then eased home. TRANS_BACK
	# undershoots past rest on the way, so the sprite drags behind its own recoil.
	var pos_t := _take_pos_tween()
	pos_t.tween_property(sprite, "position", base_pos + dir * lunge_dist, lunge_time) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	pos_t.tween_property(sprite, "position", base_pos, lunge_return) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _recoil(dir: Vector2) -> void:
	knockback_dir = -dir
	knockback.start()
	hitstop.start()


# Tips into the player over the frames the strike connects, whips back the other way as
# the recoil throws it off its feet, then levels out once it is back on them.
func _strike_pitch() -> float:
	if hitstop.is_started() and not hitstop.is_done():
		return deg_to_rad(lunge_pitch_deg) * pitch_facing
	if knockback.is_started() and not knockback.is_done():
		return deg_to_rad(rear_pitch_deg) * pitch_facing
	return 0.0


func _pitch_towards(target: float, delta: float) -> void:
	sprite.rotation = lerp_angle(sprite.rotation, target, 1.0 - exp(-pitch_smooth * delta))


# One looping bounce: squat wide-and-short, then stretch tall-and-thin. The two axes
# move inversely so the sprite keeps roughly the same visual volume.
func _start_walk_anim() -> void:
	if walking:
		return
	walking = true

	var squashed := Vector2(base_scale.x / walk_squash, base_scale.y * walk_squash)
	var stretched := Vector2(base_scale.x * walk_squash, base_scale.y / walk_squash)

	var tween := _take_scale_tween().set_loops()
	tween.tween_property(sprite, "scale", squashed, walk_cycle_time * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", stretched, walk_cycle_time * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_walk_anim() -> void:
	if not walking:
		return  # Already settling — don't respawn the settle tween every idle frame.
	walking = false

	_take_scale_tween().tween_property(sprite, "scale", base_scale, walk_settle_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Only one tween may own a given sprite property at a time, otherwise the walk bob and
# the pounce fight over it frame to frame.
func _take_scale_tween() -> Tween:
	scale_tween = _restart(scale_tween)
	return scale_tween


func _take_pos_tween() -> Tween:
	pos_tween = _restart(pos_tween)
	return pos_tween


func _restart(tween: Tween) -> Tween:
	if tween != null and tween.is_valid():
		tween.kill()
	return create_tween()
