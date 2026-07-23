extends CharacterBody2D

@export var speed : float = 100

func _enter_tree() -> void:
	velocity = Vector2(speed, 0).rotated(rotation)

func _physics_process(delta: float) -> void:
	move_and_slide()
