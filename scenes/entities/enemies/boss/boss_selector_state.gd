class_name SelectorState
extends State

# time before next state starts
const IDLE_TIME : float = 0.5

@export var state_pool : Array[State]

func enter():
	#maybe ignore prev state
	var next_state : State = state_pool.pick_random() 
	
	await get_tree().create_timer(IDLE_TIME).timeout
	
	sm.switch_state(next_state)
