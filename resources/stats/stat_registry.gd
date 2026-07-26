class_name StatRegistry
extends Resource
## Flat list of every Stat that carries run-scoped Modifiers.
##
## Stat .tres files are shared and stay cached for the lifetime of the process,
## so upgrades picked in one run are still applied in the next unless something
## clears them. GameStateManager clears this list at the top of every run.
##
## Add every stat an Upgrade or the EnemyStatScaler can touch. A stat left out
## of here quietly keeps its modifiers across a retry.

@export var stats: Array[Stat] = []


func clear_all() -> void:
	for stat in stats:
		if stat:
			stat.clear_mods()
