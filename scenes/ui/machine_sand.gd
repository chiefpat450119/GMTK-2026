class_name MachineSand
extends Control

@export var sand_drop : TextureRect
@export var number_popup : Label

func _ready() -> void:
	# Sand drop falls into intake pipe
	var sand_tween := create_tween()
	var sand_dest := sand_drop.position.y + 105
	var sand_duration := 0.5
	sand_tween.tween_property(sand_drop, "position:y", sand_dest, sand_duration)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# Number pops up to indicate amount of sand gained
	var num_tween := create_tween()
	var num_dest := Vector2(0, -40)
	const num_duration := 1
	num_tween.parallel().tween_property(number_popup, "position", num_dest, num_duration)\
			.as_relative()\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_EXPO)
	num_tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, num_duration)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)

	num_tween.tween_callback(queue_free)
