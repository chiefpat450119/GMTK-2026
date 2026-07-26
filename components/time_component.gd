# Time component to be used for player time only

class_name TimeComponent
extends Node

@export var max_time: Stat
@export var time_decay_scale: Stat  # Measured in seconds (value of time bar) per second (real life)

@onready var time_left := max_time.current_val()

@export var time_changed_event : GameEvent # Raise this for any changes to current, max time, and/or time decay
@export var time_damaged_event : GameEvent # Raise this when player takes damage

@export_category("Low Time Warning")
## Seconds remaining at which the warning sounds. Absolute.
@export var low_time_threshold : float = 10.0
## SoundBank id for that warning.
@export var low_time_sfx : StringName = &"low_time"

@export_category("Death Grace Period")
@export var death_grace_period : float = 3.0

# dies
signal depleted
signal grace_started
signal grace_survived
## Emitted only for time taken by a hit
signal damaged(amount: float)

# Terminal (cant grace)
var _dead: bool = false
var _in_grace: bool = false
var _grace_left: float = 0.0
var _low_time_warned: bool = false

static func find_in(entity: Node) -> TimeComponent:
	for child in entity.get_children():
		if child is TimeComponent:
			return child
	return null


func _process(delta: float) -> void:
	if _dead:
		return
	# The grace window is the one state decay doesn't run in: the clock is already
	# empty, and what counts down is the window itself.
	if _in_grace:
		_grace_left -= delta
		if _grace_left <= 0.0:
			_die()
		return
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
	time_damaged_event.raise()


func _set_time(value: float) -> void:
	if _dead:
		return
	time_left = clamp(value, 0, max_time.current_val())
	if time_changed_event:
		time_changed_event.raise()
	_check_low_time()
	if time_left <= 0.0:
		_enter_grace()
	elif _in_grace:
		_leave_grace()


func in_grace_period() -> bool:
	return _in_grace


func grace_remaining() -> float:
	return _grace_left if _in_grace else 0.0


func grace_ratio() -> float:
	if not _in_grace or death_grace_period <= 0.0:
		return 0.0
	return clampf(_grace_left / death_grace_period, 0.0, 1.0)


func is_dead() -> bool:
	return _dead


func _enter_grace() -> void:
	if _in_grace or _dead:
		return
	if death_grace_period <= 0.0:
		_die()
		return
	_in_grace = true
	_grace_left = death_grace_period
	grace_started.emit()


func _leave_grace() -> void:
	_in_grace = false
	_grace_left = 0.0
	grace_survived.emit()


func _die() -> void:
	if _dead:
		return
	_dead = true
	_in_grace = false
	_grace_left = 0.0
	depleted.emit()


func _check_low_time() -> void:
	if low_time_threshold <= 0.0:
		return
	if time_left > low_time_threshold:
		_low_time_warned = false
	elif not _low_time_warned:
		_low_time_warned = true
		SFX.play(low_time_sfx)


func time_percentage() -> float:
	if max_time == null:
		return 0.0
	var max_val := max_time.current_val()
	if max_val <= 0.0:
		return 0.0
	return time_left / max_val
