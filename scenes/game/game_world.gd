class_name GameWorld
extends Node2D
## Root of a single run. Instanced under main.tscn's world mount by
## GameStateManager on start_run(), and freed outright when the run ends.
##
## Everything under here is disposable: player, spawner, camera, level geometry.
## Anything that has to outlive a run (menus, HUD, UpgradeManager) belongs in
## main.tscn instead.

@export var spawner: EnemySpawner


## Called by GameStateManager once the world is in the tree and the game is
## unpaused. Waves start here rather than in _ready(), or they'd tick away
## behind the main menu.
func begin() -> void:
	if spawner:
		spawner.begin_waves()
