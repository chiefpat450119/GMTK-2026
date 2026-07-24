class_name Player
extends CharacterBody2D
## Singleton containing data of relevant componentns for ease of access

@export var health_component : HealthComponent
@export var time_component : TimeComponent
@export var movement_component : MovementComponent


func _physics_process(_delta: float) -> void:
	var dir = Input.get_vector("Left", "Right", "Up", "Down")
	print(dir)
	movement_component.move(dir)
