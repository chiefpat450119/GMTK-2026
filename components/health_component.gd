class_name HealthComponent
extends Node

@export var max_hp : Stat

@onready var hp := max_hp.current_val()

@export var hp_changed_event : GameEvent

func add_hp(amount: float) -> void:
	_set_hp(hp + amount)


func remove_hp(amount: float) -> void:
	_set_hp(hp - amount)


func _set_hp(value: float) -> void:
	hp = clamp(value, 0, max_hp)
	hp_changed_event.raise()
