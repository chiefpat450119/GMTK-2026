class_name BossAttackState
extends State

@export var selector_state: SelectorState

@export var atk_component: AtkComponent

#@export var state_time: float = 2

#@export var sprite: Sprite2D


func enter():
	var yield_time := play_anim(&"Swing")
	SFX.play(&"boss_swing_charge")
  
	# wind up time
	await get_tree().create_timer(0.5).timeout
	SFX.play(&"boss_swing_attack")
	SFX.play(&"boss_swing_attack2")
  
	atk_component.set_active(true)
	await get_tree().create_timer(yield_time - 0.5).timeout
	atk_component.set_active(false)
	
	
	switch_state(selector_state)
