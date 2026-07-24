class_name BashEnemy
extends Enemy

const ROTATION_SPEED := 12.0  # Radians per second the body turns to face the player
const CHARGE_SQUASH := 0.6  # Sprite scale.y multiplier at the end of the wind-up
const RECOVER_TIME := 0.1  # Seconds for the sprite to snap back as the bash fires

@export var attack_interval: float  # Seconds between attacks
@export var charge_time: float  # Wind-up before the bash fires
@export var bash_duration: float  # How long the bash travels for
@export var bash_speed: float  # Speed multiplier while bashing
@export var charging_speed: float  # Speed multiplier while winding up
@export var attack_range: float  # Distance at which the enemy commits to an attack
@export var range_stat: Stat
@export var accel_time: float  # Seconds to reach full speed (approach only)
@export var decel_time: float  # Seconds to coast to a stop (approach only)

@export var sprite: Sprite2D
@export var hurtbox: Area2D

@onready var attack_cooldown := Cooldown.new(attack_interval)
@onready var charge_timer := Cooldown.new(charge_time)
@onready var bash_timer := Cooldown.new(bash_duration)
@onready var base_scale_y: float = sprite.scale.y

var bash_dir: Vector2


func _ready() -> void:
	hurtbox.monitoring = false
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	attack_cooldown.start()


func _physics_process(delta: float) -> void:
	attack_cooldown.tick(delta)
	charge_timer.tick(delta)
	bash_timer.tick(delta)
	

	look_at(get_player_pos())

	if bash_timer.is_started():
		_update_bash()
		return

	var dir := get_to_player_vec()
	if charge_timer.is_started():
		_update_charge(dir)
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


func _start_charge() -> void:
	attack_cooldown.stop()
	charge_timer.start()

	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale:y", base_scale_y * CHARGE_SQUASH, charge_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.CRIMSON, charge_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _update_charge(dir: Vector2) -> void:
	move_towards_player(charging_speed)

	if charge_timer.is_done():
		charge_timer.stop()
		_start_bash(dir)


func _start_bash(dir: Vector2) -> void:
	bash_dir = dir.normalized()  # Locked here, so the bash can be dodged
	bash_timer.start()
	hurtbox.monitoring = true

	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale:y", base_scale_y, RECOVER_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, RECOVER_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _update_bash() -> void:
	movement.move(bash_dir * bash_speed)

	if bash_timer.is_done():
		bash_timer.stop()
		hurtbox.monitoring = false
		attack_cooldown.start()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body is Player:
		hit(1)
