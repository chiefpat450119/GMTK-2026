class_name UpgradeManager
extends Node
## Owns the upgrade pool and run-time state (how many times each upgrade was
## taken). Provides weighted, duplicate-free rolls and applies picks.
##
## Stateless UI (UpgradeScreen) asks this for choices and reports the pick.

@export var pool: UpgradePool
## How many cards to offer per selection.
@export var choices_count: int = 3

# id -> times taken. Used to enforce max_stacks and to id Modifier stacks.
var _stacks: Dictionary = {}


# Returns up to `count` distinct upgrades, weighted by Upgrade.weight,
# excluding any that have hit max_stacks.
func roll(count: int = choices_count) -> Array[Upgrade]:
	var available: Array[Upgrade] = []
	for upgrade in pool.upgrades:
		if _is_available(upgrade):
			available.append(upgrade)
	var picks: Array[Upgrade] = []
	while picks.size() < count and not available.is_empty():
		var choice := _weighted_pick(available)
		picks.append(choice)
		available.erase(choice)
	return picks


# Applies an upgrade and bumps its stack count.
func apply(upgrade: Upgrade) -> void:
	var taken: int = _stacks.get(upgrade.id, 0)
	upgrade.apply(taken)
	_stacks[upgrade.id] = taken + 1


func times_taken(upgrade: Upgrade) -> int:
	return _stacks.get(upgrade.id, 0)

func _is_available(upgrade: Upgrade) -> bool:
	if upgrade.max_stacks <= 0:
		return true
	return times_taken(upgrade) < upgrade.max_stacks


func _weighted_pick(list: Array[Upgrade]) -> Upgrade:
	var total := 0.0
	for upgrade in list:
		total += maxf(upgrade.weight, 0.0)
	if total <= 0.0:
		return list.pick_random()
	var roll_val := randf() * total
	for upgrade in list:
		roll_val -= maxf(upgrade.weight, 0.0)
		if roll_val <= 0.0:
			return upgrade
	return list.back()
