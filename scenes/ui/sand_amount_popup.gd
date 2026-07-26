class_name SandAmountPopup
extends Control

@export var number_popup : Label

func _ready() -> void:
	# Number pops up to indicate amount of sand gained/spent
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
