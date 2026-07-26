class_name CollectableSand
extends Collectable

var pickup_amt : float 
## seconds until the drop despawns on its own; <= 0 means never
@export var despawn_time: float = -1.0

@export var sprite : Sprite2D

func setup(amt: float):
	pickup_amt = amt
	#sprite.scale = Vector2(amt, amt)
	if despawn_time > 0:
		await get_tree().create_timer(despawn_time).timeout
		if not _collected:
			queue_free()

#func _ready() -> void:
	#if despawn_time > 0:
		#await get_tree().create_timer(despawn_time).timeout
		#if not _collected:
			#queue_free()


func _on_collected(player: Player) -> void:
	# A cleared wave drops a lot of these at once and the player walks through
	# them in a burst, so this is the one sound that genuinely needs polyphony —
	# see its max_polyphony and retrigger_cooldown in sound_bank.tres.
	SFX.play(&"gain_exp")

	# picking up sand tops the player's time back up
	player.time_component.add_time(pickup_amt)
	# ...and is the only XP source in the run, so the same pickup drives progression
	var level := LevelComponent.find_in(player)
	if level:
		level.add_xp(pickup_amt)
