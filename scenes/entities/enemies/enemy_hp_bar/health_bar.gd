#This part is to make sure the rotation is constant
#This can be deleted if you don't mind the healthbar rotating with the enemy
#It might also be possible to avoid this if you add a parent scene to the enemy so feel free to do that

extends Node2D

var parent
var displacement: float

func _ready() -> void:
	parent = get_parent()
	displacement = position.y

#sets the position for the health bar
func _process(delta: float) -> void:
	global_rotation = 0.0
	global_position = parent.global_position
	global_position.y += displacement
	
