class_name HealthComponent
extends Node

@export var max_hp : Stat

@onready var hp := max_hp.current_val()

func add_hp(amount: float) -> void:
	_set_hp(hp + amount)


func remove_hp(amount: float) -> void:
	_set_hp(hp - amount)


func _set_hp(value: float) -> void:
	hp = clamp(value, 0, max_hp)
