class_name EnemyStatScaler
extends Node

const SCALING_MOD_ID := &"time_scaling"
const HP_MUL = 0.03
const ATK_MUL = 0.02
const SPD_MUL = 0.006
const RANGE_MUL = 0.004

## Difficulty is expressed as multipliers on figures tuned elsewhere, rather than
## as a second set of constants that would have to be kept in step with them.
## EASY is the baseline: at 1.0 every number is exactly what the rest of the game
## was balanced against.
##
## The setting lives on this node because enemy growth is the bulk of what it
## means, but it reaches past this file -- LevelComponent asks for the XP
## multiplier below, which is the other half of what makes a hard run hard.
enum Difficulty { EASY, HARD }

## How fast enemy stats climb per wave.
const ENEMY_GROWTH_MULTIPLIERS := {
	Difficulty.EASY: 0.9,
	Difficulty.HARD: 2.5,
}

## How much XP a level costs. Levels are what hand out upgrades, one apiece, so
## dearer levels are fewer upgrades -- thinned out across the whole run rather
## than cut off part way through it, which is what a cap on the count would do.
const XP_REQUIREMENT_MULTIPLIERS := {
	Difficulty.EASY: 1.0,
	Difficulty.HARD: 1.5,
}

@export var hp_stat: Stat
@export var atk_stat: Stat
@export var speed_stat: Stat
@export var range_stat: Stat
@export var enabled: bool = true
@export var on_wave_change: GameEventListener

## Chosen from the main menu, and deliberately left alone by reset(): it is a
## setting that outlives a run, not run state.
var difficulty: Difficulty = Difficulty.EASY:
	set(value):
		difficulty = value
		# Only reached between runs today, but a change mid-run should land at
		# once rather than wait for the next wave to re-derive the mods.
		_apply()

var _total: int = 0

func _ready() -> void:
	on_wave_change.response.connect(tick)
	GameStateManager.register_resettable(self)

func enemy_growth_multiplier() -> float:
	return ENEMY_GROWTH_MULTIPLIERS[difficulty]


## What one level costs against what LevelComponent has authored. Read there on
## every requirement, so switching difficulty is felt from the next level on
## rather than only by a run started afterwards.
func xp_requirement_multiplier() -> float:
	return XP_REQUIREMENT_MULTIPLIERS[difficulty]

func tick() -> void:
	_total += 1
	_apply()

func reset() -> void:
	_total = 0
	_clear(hp_stat)
	_clear(atk_stat)
	_clear(speed_stat)
	_clear(range_stat)

# The whole scaling is re-derived from the wave count every time rather than
# accumulated, so the difficulty can change under it without the mods already
# applied having been mixed at the old multiplier.
func _apply() -> void:
	var mult := enemy_growth_multiplier()
	_scale(hp_stat, HP_MUL * _total * mult)     # +3.0% max hp per wave on easy
	_scale(atk_stat, ATK_MUL * _total * mult)    # +2.0% attack
	_scale(speed_stat, SPD_MUL * _total * mult)  # +0.6% move speed
	_scale(range_stat, RANGE_MUL * _total * mult)  # +0.4% range

func _scale(stat: Stat, mult_amount: float) -> void:
	if stat == null:
		return
	stat.remove_mod(SCALING_MOD_ID)
	stat.add_mod(SCALING_MOD_ID, mult_amount, Modifier.Operation.MULT)

func _clear(stat: Stat) -> void:
	if stat != null:
		stat.remove_mod(SCALING_MOD_ID)
