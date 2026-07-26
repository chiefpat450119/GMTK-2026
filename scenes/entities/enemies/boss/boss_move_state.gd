class_name BossMoveState
extends State


const PLAYER_DISTANCE_THRESHOLD : int = 50
const MIN_MOVE_TIME: float = 1.0 # will move for atleast this long

@export var enemy: Enemy
@export var selector_state: SelectorState
@export var attack_state: State
@export var contact_atk_component: AtkComponent

@export_category("STATE INFO")
@export var accel_time: float = 0.25
@export var deccel_time: float = 0.15
@export var max_move_time: float = 2.0 # swithces state if time exceeds this

@onready var state_timer := Cooldown.new(max_move_time)

func enter():
	state_timer.start()
	contact_atk_component.set_active(true)
	
	play_anim(&"Walk")


func physics_tick(_delta: float):
	state_timer.tick(_delta)
	
	var dir := enemy.get_to_player_vec()
	if enemy.get_to_player_vec().length() > PLAYER_DISTANCE_THRESHOLD:
		enemy.accelerate(dir.normalized(), 1, accel_time, deccel_time, _delta)
	
	_check_switch()


func _check_switch():
	# move for atleast Min move time
	if state_timer.time_elapsed() < MIN_MOVE_TIME and state_timer._duration > MIN_MOVE_TIME:
		return
	
	
	if state_timer.is_done():
		switch_state(selector_state)

func exit():
	state_timer.stop()
	contact_atk_component.set_active(false)
