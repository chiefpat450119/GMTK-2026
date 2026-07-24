# Health component used for enemies only — the player has no hp, their time bar is their health

class_name HealthComponent
extends Node

signal hp_changed_signal
signal died()

@export var max_hp: Stat
@export var base_hp: float
@export var hp_changed_event: GameEvent # Optional, for listeners that can't connect to the signal directly

@export var death_event: GameEvent # shared event for when *any* enemy dies

@onready var effective_max_hp := max_hp.current_val(base_hp)
@onready var hp := effective_max_hp


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
	
	if hp <= 0:
		die()

func die():
	died.emit()
	if death_event:
		death_event.raise()
	
	owner.queue_free()
