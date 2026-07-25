class_name MeleeEnemy
extends Enemy

const HIT_KNOCKBACK := 950.0  # Recoil speed away from the player the instant a hit lands
const KNOCKBACK_TIME := 0.28  # Seconds for the recoil to decay to a stop
const HITSTOP_TIME := 0.06  # Brief freeze the instant a hit lands, so the strike has a beat
const HIT_SQUASH := 0.65  # sprite scale.y multiplier at the peak of the impact
const HIT_STRETCH := 1.2  # sprite scale.x multiplier at the peak of the impact
const HIT_RECOVER := 0.18  # Seconds for the sprite to spring back after the squash
const WALK_SQUASH := 0.95  # scale multiplier on the squashed axis of the walk bob
const WALK_CYCLE_TIME := 0.36  # Seconds for one full squash -> stretch -> squash bounce
const WALK_SETTLE_TIME := 0.12  # Seconds to ease back to the resting scale when stopping
const WALK_MIN_SPEED := 5.0  # Below this speed the enemy counts as standing still

@export var accel_time: float  # Seconds to reach full speed
@export var decel_time: float  # Seconds to coast to a stop
@export var sprite: Sprite2D

@onready var base_scale: Vector2 = sprite.scale
@onready var hitstop := Cooldown.new(HITSTOP_TIME)
@onready var knockback := Cooldown.new(KNOCKBACK_TIME)

var knockback_dir: Vector2
var scale_tween: Tween  # Whoever is animating sprite.scale right now
var walking: bool  # True while the walk bob owns the scale tween


func _ready() -> void:
	# Enemy._ready() is what hooks death up to the sand drop. GDScript does not
	# chain _ready(), so overriding it without this silently costs the drop.
	super()
	# Hit detection lives on the atk component; this enemy only reacts to it.
	atk.contacted.connect(_on_contacted)
	atk.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	hitstop.tick(delta)
	knockback.tick(delta)

	# Freeze in place for a beat the instant a hit lands, then launch into the recoil.
	if hitstop.is_started() and not hitstop.is_done():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Recoiling: coast backwards, decaying to a stop. The enemy can't hit again until it
	# has re-approached, so the recoil — not a silent timer — paces the attacks.
	if knockback.is_started() and not knockback.is_done():
		var t := knockback.time_left / KNOCKBACK_TIME  # 1 -> 0 over the recoil
		velocity = knockback_dir * HIT_KNOCKBACK * t
		move_and_slide()
		return

	accelerate_towards_player(1, accel_time, decel_time, delta)

	# Bob only while actually walking, so an enemy coasting to a stop settles flat.
	if velocity.length() > WALK_MIN_SPEED:
		_start_walk_anim()
	else:
		_stop_walk_anim()


# Bounce off every contact, even one the rate limiter ate, so the enemy never
# sits inside the player wobbling.
func _on_contacted(_body: Node2D) -> void:
	_recoil()


func _on_hit_landed(_body: Node2D, _damage: float) -> void:
	_play_hit_reaction()


func _recoil() -> void:
	# Push straight away from the player; fall back to reversing our approach if we're
	# sitting dead-centre on them and the vector is degenerate.
	var away := -get_to_player_vec()
	if away.length() < 0.01:
		away = -velocity
	knockback_dir = away.normalized() if away.length() > 0.01 else Vector2.RIGHT

	knockback.start()
	hitstop.start()
	# Settle out of the bob for the freeze/recoil. contacted always fires before
	# hit_landed, so the impact squash still takes the scale over on a damaging hit.
	_stop_walk_anim()


func _play_hit_reaction() -> void:
	walking = false  # The impact squash takes the scale over from the walk bob.

	var squashed := Vector2(base_scale.x * HIT_STRETCH, base_scale.y * HIT_SQUASH)
	var tween := _take_scale_tween()
	tween.tween_property(sprite, "scale", squashed, HITSTOP_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, HIT_RECOVER) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Colour rides its own tween so a scale tween replacing this one mid-flash can't
	# strand the sprite red.
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color(1, 0.5, 0.5), HITSTOP_TIME)
	flash.tween_property(sprite, "modulate", Color.WHITE, HIT_RECOVER)


# One looping bounce: squat wide-and-short, then stretch tall-and-thin. The two axes
# move inversely so the sprite keeps roughly the same visual volume.
func _start_walk_anim() -> void:
	if walking:
		return
	walking = true

	var squashed := Vector2(base_scale.x / WALK_SQUASH, base_scale.y * WALK_SQUASH)
	var stretched := Vector2(base_scale.x * WALK_SQUASH, base_scale.y / WALK_SQUASH)

	var tween := _take_scale_tween().set_loops()
	tween.tween_property(sprite, "scale", squashed, WALK_CYCLE_TIME * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", stretched, WALK_CYCLE_TIME * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_walk_anim() -> void:
	if not walking:
		return  # Already settling — don't respawn the settle tween every idle frame.
	walking = false

	_take_scale_tween().tween_property(sprite, "scale", base_scale, WALK_SETTLE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Only one tween may own sprite.scale at a time, otherwise the walk loop and the hit
# squash fight over it frame to frame.
func _take_scale_tween() -> Tween:
	if scale_tween != null and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween()
	return scale_tween
