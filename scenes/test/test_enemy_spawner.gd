extends Node2D
## Standalone harness for EnemySpawner.
##
## In the real game GameWorld.begin() starts the waves once the run is actually
## running. This stands in for that so the scene still does something on its own.

@export var spawner: EnemySpawner


func _ready() -> void:
	if spawner:
		spawner.begin_waves()
