# Time component to be used for player time only

class_name TimeComponent
extends Node

@export var max_time: Stat
@export var time_decay_scale: Stat  # Measured in seconds (value of time bar) per second (real life)

@onready var time_left := max_time.current_val()

@export var time_changed_event : GameEvent # Raise this for any changes to current, max time, and/or time decay

## Emitted the moment the clock hits zero. This is what ends a run — GameWorld
## connects it to GameStateManager.game_over(). Only fires on the crossing, so
## the run doesn't end again every frame the clock sits at zero.
signal depleted
## Emitted only for time taken by a hit
signal damaged(amount: float)

var _depleted: bool = false

## Returns the TimeComponent hanging off an entity, or null if it has none.
## Mirrors HealthComponent.find_in so damage sources can hurt the player — whose
## pool is time — without knowing its concrete type.
static func find_in(entity: Node) -> TimeComponent:
	for child in entity.get_children():
		if child is TimeComponent:
			return child
	return null


func _process(delta: float) -> void:
	remove_time(time_decay_scale.current_val() * delta)
	
	
func add_time(amount: float) -> void:
	_set_time(time_left + amount)


func remove_time(amount: float) -> void:
	_set_time(time_left - amount)


## Time taken by a hit. Same arithmetic as remove_time, announced as a blow so
## reactions can play off it. Damage sources should come through here; anything
## the player spends by choice, and the decay itself, stays on remove_time.
func damage(amount: float) -> void:
	remove_time(amount)
	damaged.emit(amount)


func _set_time(value: float) -> void:
	time_left = clamp(value, 0, max_time.current_val())
	if time_changed_event:
		time_changed_event.raise()
	if time_left <= 0.0:
		if not _depleted:
			_depleted = true
			depleted.emit()
	else:
		_depleted = false


func time_percentage() -> float:
	if max_time == null:
		return 0.0
	var max_val := max_time.current_val()
	if max_val <= 0.0:
		return 0.0
	return time_left / max_val
