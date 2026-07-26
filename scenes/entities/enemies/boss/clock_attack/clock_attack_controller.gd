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
		var rot := i * PI / 6 - (PI / 3)
		var offset := Vector2.from_angle(rot) * clock_radius
		clock_numbers[i].move_to_pos(offset)
		await get_tree().create_timer(NUMBER_DISPLAY_DELAY).timeout

func expand_clock_edge(mod: float = 1.1):
	#clock_edge.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(clock_edge, "scale", 
	Vector2.ONE * ((clock_radius / SPRITE_RADIUS) * mod), 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

func expand_hand(mod: float = 1.3):
	var tween := create_tween()
	tween.tween_property(clock_hand, "scale", 
	Vector2.ONE * ((clock_radius / SPRITE_RADIUS) * mod), 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


func swing_hand():
	await clock_hand.rotate_hand()


func shoot_numbers():
	for i in range(12):
		clock_numbers[i].shoot_projectile()
		var delay := 0.3 - ((i / 12.0) * 0.15)
		await get_tree().create_timer(delay).timeout
