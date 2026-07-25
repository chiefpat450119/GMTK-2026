class_name DamageNumber
extends Node2D

@export var label : Label

func _ready() -> void:
	# Damage numbers appear above enemies' heads
	label.position.y -= 50
	
	# A little bit of random offset so popups don't overlap 
	# when there are many of them at once
	label.position.x += randf_range(-40, 40)
	label.position.y += randf_range(-40, 40)
	
	# Little bit of random colour variation
	label.modulate.g += randf_range(0, 0.6)
	
	# Float upwards
	var tween := create_tween()
	var dest := Vector2(randf_range(-20, 20), -40)
	const duration := 1
	tween.parallel().tween_property(label, "position", dest, duration)\
            .as_relative()\
            .set_ease(Tween.EASE_OUT)\
            .set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, duration)\
            .set_ease(Tween.EASE_IN)\
            .set_trans(Tween.TRANS_CUBIC)

	tween.tween_callback(queue_free)
