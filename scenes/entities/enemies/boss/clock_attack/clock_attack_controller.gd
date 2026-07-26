class_name ClockAttackController
extends Node2D

const NUMBER_DISPLAY_DELAY = 0.05

@export var clock_radius: int

@export var clock_numbers: Array[ClockNumber]
@export var clock_hand: HourHand

#func _ready() -> void:
	#_orient_numbers()
	#
	#await get_tree().create_timer(1).timeout
	#
	#clock_hand.rotate_hand()
	##clock_hand.rotate_hand()
	##s

func orient_numbers():
	if clock_numbers.size() < 12:
		push_warning("not enough clock nubers bruv")
	
	for i in range(12):
		var rot := i * PI / 6
		var offset := Vector2.from_angle(rot) * clock_radius
		clock_numbers[i].move_to_pos(offset)
		await get_tree().create_timer(NUMBER_DISPLAY_DELAY).timeout

func swing_hand():
	await clock_hand.rotate_hand()
