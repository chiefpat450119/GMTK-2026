# Health component used for enemies only — the player has no hp, their time bar is their health

class_name HealthComponent
extends Node

@export var max_hp: Stat
@export var base_hp: float
@export var hp_changed_event : GameEvent # Optional, for listeners that can't connect to the signal directly

@onready var hp := max_hp.current_val(base_hp)

signal hp_changed_signal

func add_hp(amount: float) -> void:
	_set_hp(hp + amount)


func remove_hp(amount: float) -> void:
	_set_hp(hp - amount)


func _set_hp(value: float) -> void:
	hp = clamp(value, 0, max_hp.current_val(base_hp))
	hp_changed_signal.emit()
	if hp_changed_event:
		hp_changed_event.raise()
