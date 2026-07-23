extends Area2D

@export var pickup_amount: int = 2
@export var despawn_time: float = -1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	#A despawn timer, set despawn time to a number greater than zero for use
	if despawn_time > 0:
		await get_tree().create_timer(10).timeout
		queue_free()

	
func _on_body_entered(body):
	#as sand is being picked up it adds time I think, then it deletes the item
	if body.is_in_group("Player"):
		PlayerManager.add_time(pickup_amount)
		queue_free()
