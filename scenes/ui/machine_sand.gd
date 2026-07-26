class_name MachineSand
extends Control

@export var sand_drop : TextureRect

func _ready() -> void:
	# Sand drop falls into intake pipe
	var sand_tween := create_tween()
	var sand_dest := sand_drop.position.y + 105
	var sand_duration := 0.5
	sand_tween.tween_property(sand_drop, "position:y", sand_dest, sand_duration)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

	sand_tween.tween_callback(queue_free)
