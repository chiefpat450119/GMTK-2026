class_name Player
extends CharacterBody2D
## Singleton containing data of relevant componentns for ease of access

static var instance: Player

@export var time_component : TimeComponent
@export var movement_component : MovementComponent
@export var dash_component : DashComponent
@export var sprite : AnimatedSprite2D


func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		queue_free() # Prevents duplicate instances from existing

func _exit_tree() -> void:
	# The world is freed and rebuilt between runs, so a stale instance here would
	# leave enemies chasing a dead Player. Guarded because duplicates that were
	# freed above also pass through here without ever having claimed the slot.
	if instance == self:
		instance = null

func _physics_process(_delta: float) -> void:
	dash_component.tick(_delta)
	dash_component.request_dash(Input.is_action_just_pressed("Shift"))
	
	var dir: Vector2 = Input.get_vector("Left", "Right", "Up", "Down")
	if dash_component.is_dashing():
		dash_component.move(dir)
	else:
		movement_component.move(dir)
	
	if Input.get_vector("Left", "Right", "Up", "Down") == Vector2.LEFT:
		sprite.flip_h = true
	elif Input.get_vector("Left", "Right", "Up", "Down") == Vector2.RIGHT:
		sprite.flip_h = false
	
