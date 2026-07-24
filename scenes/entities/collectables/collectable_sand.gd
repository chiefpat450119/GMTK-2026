class_name CollectableSand
extends Collectable

@export var pickup_amount: int = 2
## seconds until the drop despawns on its own; <= 0 means never
@export var despawn_time: float = -1.0


func _ready() -> void:
	if despawn_time > 0:
		await get_tree().create_timer(despawn_time).timeout
		if not _collected:
			queue_free()


func _on_collected(player: Player) -> void:
	# picking up sand tops the player's time back up
	player.time_component.add_time(pickup_amount)
