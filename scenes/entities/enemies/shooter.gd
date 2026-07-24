class_name ShooterEnemy
extends Enemy

const CHARGE_SQUASH := 0.6  # Sprite scale.y multiplier just before firing
const RECOIL_STRETCH := 1.6  # Sprite scale.y multiplier the moment the shot leaves
const RECOIL_TIME := 0.1  # Seconds for each half of the recoil pop

@export var shoot_interval: float  # Seconds between shots
@export var wait_interval: float # Seconds after shooting where it doesnt move
@export var projectile_scene: PackedScene
@export var min_range: float  # Backs away from the player inside this
@export var max_range: float  # Closes on the player outside this
@export var sprite: Sprite2D
@export var range_stat: Stat
@export var accel_time: float  # Seconds to reach full speed
@export var decel_time: float  # Seconds to coast to a stop

@onready var shoot_cooldown := Cooldown.new(shoot_interval)
@onready var wait_period := Cooldown.new(wait_interval)
@onready var base_scale_y: float = sprite.scale.y

func _ready() -> void:
	shoot_cooldown.start()


func _physics_process(delta: float) -> void:
	shoot_cooldown.tick(delta)
	wait_period.tick(delta)

	var dir := get_to_player_vec()
	global_rotation = dir.angle()

	# Desired move direction; stays zero when the enemy wants to hold position,
	# so accelerate() eases the velocity down to a stop instead of cutting it.
	var move_dir := Vector2.ZERO

	if shoot_cooldown.is_done():
		_shoot(dir)
		wait_period.start()
	elif (not wait_period.is_started()) or wait_period.is_done():
		_update_tell()
		wait_period.stop()

		var dist := dir.length()
		if dist < range_stat.current_val(min_range):
			move_dir = -dir
		elif dist > range_stat.current_val(max_range):
			move_dir = dir

	# Called every frame so deceleration is applied even when move_dir is zero.
	accelerate(move_dir, 1, accel_time, decel_time, delta)


func _shoot(dir: Vector2) -> void:
	shoot_cooldown.start()

	var projectile: Node2D = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.rotation = dir.angle()  # Read by the projectile on _enter_tree
	add_child(projectile)

	var tween := create_tween()
	tween.tween_property(sprite, "scale:y", base_scale_y * RECOIL_STRETCH, RECOIL_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale:y", base_scale_y, RECOIL_TIME) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _update_tell() -> void:
	var elapsed := shoot_interval - shoot_cooldown.time_left
	var progress := remap(maxf(elapsed - shoot_interval / 2.0, 0.0), 0.0, shoot_interval, 0.0, 1.0)
	sprite.scale.y = lerpf(sprite.scale.y, base_scale_y * CHARGE_SQUASH, progress)
