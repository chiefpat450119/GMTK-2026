class_name BossChargeState
extends State


@export var enemy: Enemy
@export var selector_state: SelectorState
@export var movement: MovementComponent
@export var sprite: Sprite2D

@onready var init_sprite_scale_y := sprite.scale.y

@export_category("STATE INFO")
@export var windup_time: float = 1.0
#@export var charge_speed: float = 1000.0
@export var charge_time: float = 0.85
@export var speed_mul: float = 1000.0
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
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale:y", init_sprite_scale_y * 0.75, charge_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.CRIMSON, charge_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# temp fx
func _end_windup():
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale:y", init_sprite_scale_y, 0.1) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func physics_tick(_delta: float):
	if not charge_timer.is_started():
		return
	
	charge_timer.tick(_delta)
	
<<<<<<< Updated upstream

	if charge_timer.is_done():
		switch_state(selector_state)
	else:
		movement.move(charge_dir * speed_mul)
		
=======
	if charge_timer.is_done():
		switch_state(selector_state)
	else:
		charge_movement.move(charge_dir)

func wind_down():
	pass
>>>>>>> Stashed changes

func exit():
	charge_timer.stop()
	enemy.movement.hard_set_vel(Vector2.ZERO)
