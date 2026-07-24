class_name Enemy
extends CharacterBody2D

@onready var player = Player.instance
@export var movement: MovementComponent
@export var atk: AtkComponent
@export var hp: HealthComponent

func move_towards_player(speed_mul: float):
	movement.move(get_to_player_vec().normalized() * speed_mul)

# Eases velocity toward a target instead of snapping to it. accel_time is the
# seconds to ramp up to full speed; decel_time is the seconds to coast back to a
# stop when dir is zero. Times of 0 snap instantly.
# Call every frame from _physics_process, passing a zero dir to coast to a stop.
func accelerate(dir: Vector2, speed_mul: float, accel_time: float, decel_time: float, delta: float):
	var max_speed := movement.speed_stat.current_val(movement.base_speed) * absf(speed_mul)
	var target := dir.normalized() * max_speed * signf(speed_mul)
	var ramp_time := accel_time if dir != Vector2.ZERO else decel_time
	var rate := INF if ramp_time <= 0.0 else max_speed / ramp_time
	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()

# Acceleration-based version of move_towards_player.
func accelerate_towards_player(speed_mul: float, accel_time: float, decel_time: float, delta: float):
	accelerate(get_to_player_vec(), speed_mul, accel_time, decel_time, delta)

func get_to_player_vec() -> Vector2:
	return player.global_position - global_position

func get_player_pos() -> Vector2:
	return player.global_position

func hit(damage: float):
	atk.attack(damage, player.time_component)
	# print(player.time_component.time_left)
