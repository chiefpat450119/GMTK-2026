class_name ClockAttackController
extends Node2D

const NUMBER_DISPLAY_DELAY = 0.05

const SPRITE_RADIUS := 920.0

@export var clock_radius: float

@export var clock_numbers: Array[ClockNumber]
@export var clock_hand: HourHand

@export var clock_edge: Sprite2D


func orient_numbers():
	if clock_numbers.size() < 12:
		push_warning("not enough clock nubers bruv")
	
	for i in range(12):
		var rot := i * PI / 6
		var offset := Vector2.from_angle(rot) * clock_radius
		clock_numbers[i].move_to_pos(offset)
		await get_tree().create_timer(NUMBER_DISPLAY_DELAY).timeout

func expand_clock_edge():
	#clock_edge.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(clock_edge, "scale", 
	Vector2.ONE * ((clock_radius / SPRITE_RADIUS) * 1.1), 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

func expand_hand():
	var tween := create_tween()
	tween.tween_property(clock_hand, "scale", 
	Vector2.ONE * ((clock_radius / SPRITE_RADIUS) * 1.1), 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


func swing_hand():
	await clock_hand.rotate_hand()
