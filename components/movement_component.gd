class_name MovementComponent
extends Node

# body to move. Should be root node for player and enemies
@export var body : CharacterBody2D
@export var speed_stat : Stat
@export var base_speed : float = 0.0

# Moves body. Velocity calculated by caller
func move(dir: Vector2):
	if body == null:
		print("no body found")
		return 
	
	body.velocity = speed_stat.current_val(base_speed) * dir
	body.move_and_slide()
