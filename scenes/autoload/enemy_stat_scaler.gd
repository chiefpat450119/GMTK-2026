class_name EnemyStatScaler
extends Node

const SCALING_MOD_ID := &"time_scaling"

@export var hp_stat: Stat
@export var atk_stat: Stat
@export var speed_stat: Stat
@export var range_stat: Stat
@export var enabled: bool = true

var _elapsed: float = 0.0

func _process(delta: float) -> void:
	if not enabled:
		return
	_elapsed += delta
	tick(_elapsed)

func tick(elapsed: float) -> void:
	_scale(hp_stat, 0.030 * elapsed)     # +3.0% max hp per second
	_scale(atk_stat, 0.020 * elapsed)    # +2.0% attack per second
	_scale(speed_stat, 0.006 * elapsed)  # +0.6% move speed per second
	_scale(range_stat, 0.004 * elapsed)  # +0.4% range per second

# Clears all scaling and restarts the ramp from zero (e.g. on a new run).
func reset() -> void:
	_elapsed = 0.0
	_clear(hp_stat)
	_clear(atk_stat)
	_clear(speed_stat)
	_clear(range_stat)

# Seconds of play time accumulated so far.
func elapsed() -> float:
	return _elapsed

# Rewrites the scaling modifier on a stat to the given multiplicative amount.
func _scale(stat: Stat, mult_amount: float) -> void:
	if stat == null:
		return
	stat.remove_mod(SCALING_MOD_ID)
	stat.add_mod(SCALING_MOD_ID, mult_amount, Modifier.Operation.MULT)

func _clear(stat: Stat) -> void:
	if stat != null:
		stat.remove_mod(SCALING_MOD_ID)
