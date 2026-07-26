class_name BossClockAtkState
extends State

@export var enemy: Enemy
@export var selector_state: SelectorState
@export var clock_attack: PackedScene
var clock_instance: ClockAttackController

@export var windup_time: float = 1.0

func enter():
	super()
	
	await windup()
	await swing()
	
	switch_state(selector_state)

func windup():
	clock_instance = clock_attack.instantiate()
	enemy.add_child(clock_instance)
	
	clock_instance.orient_numbers()
	await get_tree().create_timer(windup_time).timeout

func swing():
	await clock_instance.swing_hand()

func exit():
	clock_instance.queue_free()
