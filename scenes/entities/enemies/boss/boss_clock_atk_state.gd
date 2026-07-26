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
	await delay(0.2)
	
	await clock_instance.shoot_numbers()
	
	await delay(0.75)
	
	await retract()
	
	switch_state(selector_state)

func retract():
	clock_instance.expand_clock_edge(0)
	await clock_instance.expand_hand(0)

func delay(time: float):
	await get_tree().create_timer(time).timeout


func windup():
	SFX.play(&"boss_clock_charge")
	SFX.play(&"boss_clock_charge2")
	clock_instance = clock_attack.instantiate()
	enemy.add_child.call_deferred(clock_instance)
	
	clock_instance.expand_clock_edge()
	SFX.play(&"boss_clock_expand_edge")
	
	await delay(0.1)
	
	clock_instance.expand_hand()
	
	play_anim(&"Clock")
	
	await delay(0.5)
	
	clock_instance.orient_numbers()
	SFX.play(&"boss_clock_numbers")
	

	await get_tree().create_timer(play_anim(&"Clock") - 0.3).timeout
	
	SFX.play(&"boss_clock_swing2")
	await delay(0.8)
	SFX.play(&"boss_clock_swing")

func swing():
	await clock_instance.swing_hand()

func exit():
	clock_instance.queue_free()
