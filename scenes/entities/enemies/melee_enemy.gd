class_name MeleeEnemy
extends Enemy

const HIT_DAMAGE := 2.8125  # Damage dealt per landed hit (before global atk mods)
const HIT_KNOCKBACK := 950.0  # Recoil speed away from the player the instant a hit lands
const KNOCKBACK_TIME := 0.28  # Seconds for the recoil to decay to a stop
const HITSTOP_TIME := 0.06  # Brief freeze the instant a hit lands, so the strike has a beat
const HIT_SQUASH := 0.65  # sprite scale.y multiplier at the peak of the impact
const HIT_RECOVER := 0.18  # Seconds for the sprite to spring back after the squash

# Minimum seconds between damaging hits. This is the balance knob: the enemy can
# deal at most one hit per attack_interval, so its damage ceiling is a fixed
# HIT_DAMAGE / attack_interval DPS, regardless of how the recoil/chase plays out.
@export var attack_interval: float
@export var accel_time: float  # Seconds to reach full speed
@export var decel_time: float  # Seconds to coast to a stop
@export var sprite: Sprite2D
@export var hurtbox: Area2D

@onready var base_scale_y: float = sprite.scale.y
@onready var attack_cd := Cooldown.new(attack_interval)
@onready var hitstop := Cooldown.new(HITSTOP_TIME)
@onready var knockback := Cooldown.new(KNOCKBACK_TIME)

var knockback_dir: Vector2


func _ready() -> void:
	hurtbox.monitoring = true
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	attack_cd.tick(delta)
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


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	# Always bounce off, even on a bump that deals no damage, so the enemy never
	# sits inside the player wobbling.
	_recoil()

	# Gate the actual damage behind attack_interval so the hit rate has a hard,
	# deterministic ceiling for balancing. is_started() is false until the first
	# hit, so the opening contact always lands.
	if not attack_cd.is_started() or attack_cd.is_done():
		hit(HIT_DAMAGE)
		_play_hit_reaction()
		attack_cd.start()


func _recoil() -> void:
	# Push straight away from the player; fall back to reversing our approach if we're
	# sitting dead-centre on them and the vector is degenerate.
	var away := -get_to_player_vec()
	if away.length() < 0.01:
		away = -velocity
	knockback_dir = away.normalized() if away.length() > 0.01 else Vector2.RIGHT

	knockback.start()
	hitstop.start()


func _play_hit_reaction() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale:y", base_scale_y * HIT_SQUASH, HITSTOP_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color(1, 0.5, 0.5), HITSTOP_TIME)
	tween.tween_property(sprite, "scale:y", base_scale_y, HIT_RECOVER) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, HIT_RECOVER)
