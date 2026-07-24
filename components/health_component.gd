# Health component used for both enemies and player

class_name HealthComponent
extends Node

@export var max_hp: Stat
@export var base_hp: float
@export var hp_changed_event : GameEvent # Use this for players for changes to current and/or max hp

@onready var hp := max_hp.current_val(base_hp)

signal hp_changed_signal # Use this for enemies

## Returns the HealthComponent hanging off an entity, or null if it has none.
## Lets damage sources hurt anything with health without knowing its concrete type.
static func find_in(entity: Node) -> HealthComponent:
	for child in entity.get_children():
		if child is HealthComponent:
			return child
	return null


func add_hp(amount: float) -> void:
	_set_hp(hp + amount)


func remove_hp(amount: float) -> void:
	_set_hp(hp - amount)


func _set_hp(value: float) -> void:
	hp = clamp(value, 0, max_hp.current_val(base_hp))
	hp_changed_signal.emit()
	if hp_changed_event:
		hp_changed_event.raise()
