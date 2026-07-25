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
	_watch_run_clock()
	if spawner:
		spawner.begin_waves()


# The clock is what ends a run, so the wiring lives here rather than on the
# player: this node is the thing whose lifetime matches the run, and freeing it
# takes the connection with it.
func _watch_run_clock() -> void:
	if Player.instance == null:
		push_warning("GameWorld has no player — the run has no clock and can't end")
		return
	var clock := TimeComponent.find_in(Player.instance)
	if clock == null:
		push_warning("GameWorld: player has no TimeComponent — the run can't end")
		return
	clock.depleted.connect(GameStateManager.game_over)
