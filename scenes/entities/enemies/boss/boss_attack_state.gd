class_name BossAttackState
extends State

@export var selector_state: SelectorState

@export var atk_component: AtkComponent

#@export var state_time: float = 2

#@export var sprite: Sprite2D


func enter():
	super()
	
	var yield_time := play_anim(&"Swing")
	# TEMP
	#var tween := create_tween()
	#tween.tween_property(sprite, "rotation_degrees", 360, 0.1) \
		#.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#
	SFX.play(&"boss_swing_charge")
	atk_component.set_active(true)
	await get_tree().create_timer(yield_time).timeout
	atk_component.set_active(false)
	SFX.play(&"boss_swing_attack")
	SFX.play(&"boss_swing_attack2")
	
	switch_state(selector_state)
