extends Area2D
## attracts to player

signal player_found()

@export var collision_shape: CollisionShape2D
@export var pickup_range : Stat

var circle_shape_resource: CircleShape2D

const accel: float = 300.0

@onready var target: Player = null
@onready var vel: float = 0.0

func _ready() -> void:
	circle_shape_resource = collision_shape.shape as CircleShape2D
	circle_shape_resource.radius = pickup_range.current_val()
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if target == null:
		return
	
	vel += (accel * _delta)
	var dir = target.position.direction_to(position).normalized()
	translate(dir * vel)

func _on_body_entered(body: PhysicsBody2D):
	if body is not Player:
		return
	var player := body as Player
	
	player_found.emit()
	target = player
