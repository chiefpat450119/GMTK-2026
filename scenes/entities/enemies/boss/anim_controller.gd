class_name AnimController
extends Node2D

@export var anim: AnimationPlayer

# returns anim time
func play(anim_name: StringName, speed_mul : float = 1.0) -> float:
	anim.play(anim_name, -1, speed_mul)
	return anim.current_animation_length
