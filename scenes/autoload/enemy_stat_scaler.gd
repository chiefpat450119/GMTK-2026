class_name EnemyStatScaler
extends Node

const SCALING_MOD_ID := &"time_scaling"
const HP_MUL = 0.03
const ATK_MUL = 0.02
const SPD_MUL = 0.006
const RANGE_MUL = 0.004

@export var hp_stat: Stat
@export var atk_stat: Stat
@export var speed_stat: Stat
@export var range_stat: Stat
@export var enabled: bool = true
@export var on_wave_change: GameEventListener

var _total: int = 0

func _ready() -> void:
    on_wave_change.response.connect(tick)

func tick() -> void:
    _total += 1
    _scale(hp_stat, HP_MUL * _total)     # +3.0% max hp
    _scale(atk_stat, ATK_MUL * _total)    # +2.0% attack
    _scale(speed_stat, SPD_MUL * _total)  # +0.6% move speed
    _scale(range_stat, RANGE_MUL * _total)  # +0.4% range

func reset() -> void:
    _total = 0
    _clear(hp_stat)
    _clear(atk_stat)
    _clear(speed_stat)
    _clear(range_stat)

func _scale(stat: Stat, mult_amount: float) -> void:
    if stat == null:
        return
    stat.remove_mod(SCALING_MOD_ID)
    stat.add_mod(SCALING_MOD_ID, mult_amount, Modifier.Operation.MULT)

func _clear(stat: Stat) -> void:
    if stat != null:
        stat.remove_mod(SCALING_MOD_ID)
