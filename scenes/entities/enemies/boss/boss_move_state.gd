class_name BossMoveState
extends State


const PLAYER_DISTANCE_THRESHOLD : int = 50

@export var enemy: Enemy
@export var selector_state: SelectorState

@export_category("STATE INFO")
@export var accel_time: float = 0.25
@export var deccel_time: float = 0.15
@export var max_move_time: float = 2.0 # swithces state if time exceeds this

@onready var state_timer := Cooldown.new(max_move_time)

func enter():
	state_timer.start()


func physics_tick(_delta: float):
	state_timer.tick(_delta)
	
	var dir := enemy.get_to_player_vec()
	enemy.accelerate(dir.normalized(), 1, accel_time, deccel_time, _delta)
	
	if dir.length() <= PLAYER_DISTANCE_THRESHOLD or state_timer.is_done():
		switch_state(selector_state)


func exit():
	state_timer.stop()
