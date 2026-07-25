class_name CollectableSand
extends Collectable

# Plain, not @onready: the manager sets this at spawn, and an @onready initializer
# would run afterwards and stomp it back to 1.0 the moment the drop entered the tree.
var pickup_amt : float = 1.0
## seconds until the drop despawns on its own; <= 0 means never
@export var despawn_time: float = -1.0

func set_pickup_amt(amt: float):
	pickup_amt = amt

func _ready() -> void:
	if despawn_time > 0:
		await get_tree().create_timer(despawn_time).timeout
		if not _collected:
			queue_free()


func _on_collected(player: Player) -> void:
	# picking up sand tops the player's time back up
	player.time_component.add_time(pickup_amt)
	# ...and is the only XP source in the run, so the same pickup drives progression
	var level := LevelComponent.find_in(player)
	if level:
		level.add_xp(pickup_amt)
