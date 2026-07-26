class_name BossSpawner
extends Node2D

const WHITE := Color(1,1,1,1)

@export var clock: ClockAttackController
@export var boss_visual: AnimController
@export var steam: SteamEffect

@export var boss_scene: PackedScene

func _ready() -> void:
	#SFX.play(&"boss_spawn")
	boss_visual.play(&"Idle")
	
	SFX.play(&"boss_clock_expand_edge")
	await clock.expand_clock_edge()
	await clock.expand_hand()
	SFX.play(&"boss_clock_numbers")
	await clock.orient_numbers()
	SFX.play(&"boss_spawn2")
	fade_in_visual()
	await tick_hand()
	
	clock.expand_clock_edge(0)
	await clock.expand_hand(0)
	
	var instance: Enemy = boss_scene.instantiate()
	get_parent().add_child(instance)
	instance.position = position
	
	SFX.play(&"boss_clock_swing")
	boss_visual.visible = false
	steam.stop()
	steam.reparent(get_parent())
	
	queue_free()

func tick_hand():
	for i in range(13):
		if i == 12:
			SFX.play(&"boss_clock_swing2") # Rings a bell when clock hits 12

		if i % 2 == 0:
			SFX.play(&"boss_clock_tick")
		else:
			SFX.play(&"boss_clock_tick2")
		
		await clock.tick_hand(i * PI / 6)
		disapear_number(i)
		await get_tree().create_timer(0.4).timeout
	

func disapear_number(i: int):
	if i == 0:
		return
	if i > 12:
		return
	var tween := create_tween()
	tween.tween_property(clock.clock_numbers[i - 1], "modulate", Color(1,1,1,0), .1) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


func fade_in_visual():
	steam.start()
	
	var tween := create_tween()
	tween.tween_property(boss_visual, "modulate", WHITE, 7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	
