class_name SelectorState
extends State

# time before next state starts
const IDLE_TIME : float = 0.5
const CLOSE_THRESHOLD: int =  100
const FAR_THRESHOLD: int = 1000

@export var enemy: Enemy

@export var mid_state_pool : Array[State]

@export var close_state_pool: Array[State]
@export var far_state_pool: Array[State]


func enter():
	#maybe ignore prev state
	
	await get_tree().create_timer(IDLE_TIME).timeout
	
	switch_state(state_select())



func state_select() -> State:
	
	if player_dist() < CLOSE_THRESHOLD:
		return pick_state(close_state_pool)
	elif player_dist() > FAR_THRESHOLD:
		return pick_state(far_state_pool)
	
	return pick_state(mid_state_pool)

func pick_state(pool: Array[State]) -> State:
	return pool.pick_random() 


func player_dist() -> float:
	if Player.instance == null:
		return INF
	return enemy.get_to_player_vec().length()
