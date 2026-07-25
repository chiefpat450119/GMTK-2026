class_name DamageNumber
extends Node2D

@export var label : Label

func _ready() -> void:
	# Damage numbers appear above enemies' heads
	label.position.y -= 50
	
	# A little bit of random offset so popups don't overlap 
	# when there are many of them at once
	label.position.x += randf_range(-10,10)
	label.position.y += randf_range(-10,10)
	
	# Little bit of random colour variation
	label.modulate.g += randf_range(0, 0.6)
	
	# Float upwards
	var tween1 := create_tween()
	var dest := label.position + Vector2(randf_range(-20,20), -20)
	var duration := 1
	tween1.tween_property(label, "position", dest, duration)\
            .set_ease(Tween.EASE_OUT)\
            .set_trans(Tween.TRANS_EXPO)
	
	# Turn transparent
	var tween2 := create_tween()
	duration = 1
	tween2.tween_property(self, "modulate", Color.TRANSPARENT, duration)\
            .set_ease(Tween.EASE_IN)\
            .set_trans(Tween.TRANS_CUBIC)
	tween2.tween_callback(queue_free)
