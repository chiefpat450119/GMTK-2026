class_name BossChargeState
extends State


@export var enemy: Enemy
@export var selector_state: SelectorState
@export var charge_movement: MovementComponent
@export var sprite: Sprite2D

@export var anim: AnimationPlayer

@onready var init_sprite_scale_y := sprite.scale.y

@export_category("STATE INFO")
@export var windup_time: float = 1.0
#@export var charge_speed: float = 1000.0
@export var charge_time: float = 0.85
#@export var speed_stat: Stat

@onready var charge_timer := Cooldown.new(charge_time)


var charge_dir := Vector2.ZERO

func enter():
	# find player dir and lock it in
	
	# PLAY ANIMATION USING SIGNAL state_entered()
	_windup()
	
	await get_tree().create_timer(windup_time).timeout
	
	charge_dir = enemy.get_to_player_vec().normalized()
	
	charge_timer.start()
	
	_end_windup()

# temp fx
func _windup():
	#var tween := create_tween().set_parallel()
	#tween.tween_property(sprite, "scale:y", init_sprite_scale_y * 0.75, charge_time) \
		#.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#tween.tween_property(sprite, "modulate", Color.CRIMSON, charge_time) \
		#.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	anim.play(&"Dash")

# temp fx
func _end_windup():
	#var tween := create_tween().set_parallel()
	#tween.tween_property(sprite, "scale:y", init_sprite_scale_y, 0.1) \
		#.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#tween.tween_property(sprite, "modulate", Color.WHITE, 0.1) \
		#.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	anim.play(&"Dash_Airborne")

func physics_tick(_delta: float):
	if not charge_timer.is_started():
		return
	
	charge_timer.tick(_delta)
	
	charge_movement.move(charge_dir)

	if charge_timer.is_done():
		charge_timer.stop()
		wind_down()
	else:
		movement.move(charge_dir * speed_mul)

func wind_down():
	anim.play(&"Dash_End")
	await get_tree().create_timer(anim.current_animation_length).timeout
	switch_state(selector_state)


func exit():
	charge_timer.stop()
	enemy.movement.hard_set_vel(Vector2.ZERO)
