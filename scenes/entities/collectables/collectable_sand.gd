class_name CollectableSand
extends Collectable

@onready var  pickup_amt : float = 1.0
## seconds until the drop despawns on its own; <= 0 means never
@export var despawn_time: float = -1.0

@export var sprite : Sprite2D

func set_pickup_amt(amt: float):
	pickup_amt = amt
	sprite.scale = Vector2(amt, amt)

func _ready() -> void:
	if despawn_time > 0:
		await get_tree().create_timer(despawn_time).timeout
		if not _collected:
			queue_free()


func _on_collected(player: Player) -> void:
	# picking up sand tops the player's time back up
	player.time_component.add_time(pickup_amt)
