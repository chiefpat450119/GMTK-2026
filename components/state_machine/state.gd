class_name State
extends Node

var sm : StateMachine

signal on_enter()
signal on_exit()

func initialize(machine: StateMachine):
	sm = machine

func enter():
	on_enter.emit()

func exit():
	on_exit.emit()

func tick(_delta: float):
	pass

func physics_tick(_delta: float):
	pass

func handle_input(_event: InputEvent):
	pass

func switch_state(state: State):
	sm.switch_state(state)
