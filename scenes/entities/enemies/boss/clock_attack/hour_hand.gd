class_name HourHand
extends Node2D

@export var atk_component: AtkComponent
@export var clock_rotate_time: float = 0.5

func rotate_hand():
	atk_component.set_active(true)
	
	var tween := create_tween()
	tween.tween_property(self, "rotation", 2 * PI, clock_rotate_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(end)
	await tween.finished


func end():
	atk_component.set_active(false)
