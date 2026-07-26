class_name BossSpawner
extends Node2D

const WHITE := Color(1,1,1,1)

@export var clock: ClockAttackController
@export var boss_visual: AnimController
@export var steam: SteamEffect

@export var boss_scene: PackedScene

func _ready() -> void:
	boss_visual.play(&"Idle")
	
	await clock.expand_clock_edge()
	await clock.expand_hand()
	await clock.orient_numbers()
	fade_in_visual()
	await tick_hand()
	
	clock.expand_clock_edge(0)
	await clock.expand_hand(0)
	
	var instance: Enemy = boss_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = global_position
	
	steam.reparent(get_tree().current_scene)
	
	queue_free()

func tick_hand():
	for i in range(13):
		await clock.tick_hand(i * PI / 6)
		await get_tree().create_timer(0.4).timeout

func fade_in_visual():
	steam.start()
	
	var tween := create_tween()
	tween.tween_property(boss_visual, "modulate", 
	WHITE, 7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	
	steam.stop()
