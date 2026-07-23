# Time component to be used for player time only

class_name TimeComponent
extends Node

@export var max_time: Stat
@export var time_decay_scale: Stat

@onready var time_left := max_time.current_val()

func _process(delta: float) -> void:
	remove_time(time_decay_scale.current_val() * delta)
	print(time_left)
	
	
func add_time(amount: float) -> void:
	_set_time(time_left + amount)


func remove_time(amount: float) -> void:
	_set_time(time_left - amount)


func _set_time(value: float) -> void:
	time_left = clamp(value, 0, max_time.current_val())
