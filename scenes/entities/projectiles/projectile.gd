extends CharacterBody2D

@export var speed : float = 100

func _enter_tree() -> void:
	velocity = Vector2(speed, 0).rotated(rotation)

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
