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

#dash variables
@export var dash_speed : Stat
@export var dash_cooldown : Stat
@export var dash_length : float = 0.3
var dashing : bool = false
var dashing_dir : Vector2
var timer : float = 10


func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		queue_free() # Prevents duplicate instances from existing

#checks it should be dashing and adjusts dashing variables
func dash_check(start: bool = false):
	if not dashing and start:
		if timer > dash_cooldown.current_val():
			dashing_dir = Input.get_vector("Left", "Right", "Up", "Down")
			dashing = true
			timer = 0
	elif dashing and timer > dash_length:
		dashing = false
		timer = 0

func _physics_process(_delta: float) -> void:
	timer += _delta
	dash_check(Input.is_action_just_pressed("Shift"))
	
	if dashing:
		movement_component.move(dashing_dir, dash_speed.current_val())
	else:
		var dir = Input.get_vector("Left", "Right", "Up", "Down")
		movement_component.move(dir)
	
	if Input.get_vector("Left", "Right", "Up", "Down") == Vector2.LEFT:
		sprite.flip_h = true
	elif Input.get_vector("Left", "Right", "Up", "Down") == Vector2.RIGHT:
		sprite.flip_h = false
	
	if Input.is_action_pressed("M1"):
		gun.shoot()
