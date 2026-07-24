class_name StateMachine
extends Node

@export var initial_state: State
@onready var current_state: State = get_init_state()

var states : Array[State]

func find_states():
	for c in get_children():
		if c is State:
			states.append(c)
			c.initialize(self)

func get_init_state() -> State:
	var state := initial_state if initial_state != null else get_child(0)
	switch_state(state)
	return state

func switch_state(new_state: State):
	if new_state == null:
		return
	
	if current_state != null:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state

func _process(delta):
	current_state.tick(delta)

func _physics_process(delta):
	current_state.physics_tick(delta)

func _unhandled_input(event):
	current_state.handle_input(event)
