class_name BossMoveState
extends State


const PLAYER_DISTANCE_THRESHOLD : int = 50

@export var enemy: Enemy
@export var selector_state: SelectorState

@export var accel_time: float
@export var deccel_time: float



func physics_tick(_delta: float):
	var dir := enemy.get_to_player_vec().normalized()
	enemy.accelerate(dir, 1, accel_time, deccel_time, _delta)
	
	if dir.length() <= PLAYER_DISTANCE_THRESHOLD:
		switch_state(selector_state)
