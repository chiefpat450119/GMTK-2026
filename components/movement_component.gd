class_name MovementComponent
extends Node

# body to move. Should be root node for player and enemies
@export var body : CharacterBody2D
@export var speed_stat : Stat
@export var base_speed : float = 0.0

# Moves body. Direction calculated by caller, speed override is optional
func move(dir: Vector2):
	if body == null:
		return 
	var speed: float

	speed = speed_stat.current_val(base_speed)
		
	body.velocity = speed * dir
	body.move_and_slide()
