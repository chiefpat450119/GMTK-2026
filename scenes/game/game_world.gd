class_name GameWorld
extends Node2D
## Root of a single run. Instanced under main.tscn's world mount by
## GameStateManager on start_run(), and freed outright when the run ends.
##
## Everything under here is disposable: player, spawner, camera, level geometry.
## Anything that has to outlive a run (menus, HUD, UpgradeManager) belongs in
## main.tscn instead.

@export var spawner: EnemySpawner
## Sand and other drops are parented here for the length of the run, which is
## what puts them in the right draw order and frees them with the world.
@export var collectables: Node2D


## Called by GameStateManager once the world is in the tree and the game is
## unpaused. Waves start here rather than in _ready(), or they'd tick away
## behind the main menu.
func begin() -> void:
	CollectableManagerInstance.bind_container(collectables)
	_wire_run_signals()
	if spawner:
		spawner.begin_waves()


func _wire_run_signals() -> void:
	var clock := TimeComponent.find_in(Player.instance)
	clock.depleted.connect(GameStateManager.game_over)
	var level := LevelComponent.find_in(Player.instance)
	level.leveled_up.connect(_on_leveled_up)

func _on_leveled_up(_new_level: int) -> void:
	GameStateManager.request_upgrade()