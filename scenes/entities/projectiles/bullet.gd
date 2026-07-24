class_name Bullet
extends CharacterBody2D

@export var speed : float
var damage : float

func _enter_tree() -> void:
	velocity = Vector2(speed, 0).rotated(rotation)

func _physics_process(delta: float) -> void:
	move_and_slide()
