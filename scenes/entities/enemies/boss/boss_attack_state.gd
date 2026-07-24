class_name BossAttackState
extends State

@export var selector_state: SelectorState

# TODO: implement
func enter():
	switch_state(selector_state)
