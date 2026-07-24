class_name Player
extends CharacterBody2D
## Singleton containing data of relevant componentns for ease of access

# cant expose these in editor becuase Player_manager is an autoload
#@onready var health_component : HealthComponent = find_child("HealthComponent")
#@onready var time_component : TimeComponent = find_child("TimeComponent")
#@onready var movement_component : MovementComponent = find_child("MovementComponent")

@export var health_component : HealthComponent
@export var time_component : TimeComponent
@export var movement_component : MovementComponent


func _physics_process(_delta: float) -> void:
	var dir = Input.get_vector("Left", "Right", "Up", "Down")
	print(dir)
	movement_component.move(dir)
