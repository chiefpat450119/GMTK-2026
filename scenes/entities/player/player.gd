class_name Player
extends CharacterBody2D
## Singleton containing data of relevant componentns for ease of access

# cant expose these in editor becuase Player_manager is an autoload
#@onready var health_component : HealthComponent = find_child("HealthComponent")
#@onready var time_component : TimeComponent = find_child("TimeComponent")
#@onready var movement_component : MovementComponent = find_child("MovementComponent")


static var instance: Player

@export var health_component : HealthComponent
@export var time_component : TimeComponent
@export var movement_component : MovementComponent
@export var gun : Gun
@export var sprite : AnimatedSprite2D


func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		queue_free() # Prevents duplicate instances from existing


func _physics_process(_delta: float) -> void:
	var dir = Input.get_vector("Left", "Right", "Up", "Down")
	movement_component.move(dir)
	
	if Input.get_vector("Left", "Right", "Up", "Down") == Vector2.LEFT:
		sprite.flip_h = true
	elif Input.get_vector("Left", "Right", "Up", "Down") == Vector2.RIGHT:
		sprite.flip_h = false
	
	if Input.is_action_pressed("M1"):
		gun.shoot()
