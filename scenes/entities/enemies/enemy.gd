class_name Enemy
extends CharacterBody2D

@onready var player = Player.instance
@export var movement: MovementComponent
@export var atk: AtkComponent

func move_towards_player(speed_mul: float):
	movement.move(get_to_player_vec().normalized() * speed_mul)

func get_to_player_vec() -> Vector2:
	return player.global_position - global_position

func get_player_pos() -> Vector2:
	return player.global_position

func hit(damage: float):
	atk.attack(damage, player.time_component)
	# print(player.time_component.time_left)
