class_name State
extends Node

var sm : StateMachine

signal state_entered()
signal state_exited()

func initialize(machine: StateMachine):
	sm = machine

func enter():
	state_entered.emit()

func exit():
	state_exited.emit()

func tick(_delta: float):
	pass

func physics_tick(_delta: float):
	pass

func handle_input(_event: InputEvent):
	pass

func switch_state(state: State):
	sm.switch_state(state)
