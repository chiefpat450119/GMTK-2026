# Health component used for both enemies and player

class_name HealthComponent
extends Node

@export var max_hp : Stat

@onready var hp := max_hp.current_val()

@export var hp_changed_event : GameEvent # Use this for players for changes to current and/or max hp
signal hp_changed_signal # Use this for enemies

func add_hp(amount: float) -> void:
	_set_hp(hp + amount)


func remove_hp(amount: float) -> void:
	_set_hp(hp - amount)


func _set_hp(value: float) -> void:
	hp = clamp(value, 0, max_hp.current_val())
	hp_changed_signal.emit()
	if hp_changed_event:
		hp_changed_event.raise()
