class_name GameEventListener
extends Node

signal response()
@export var event : GameEvent = null

func recieve_signal():
	response.emit()

func _enter_tree():
	event.register(self)

func _exit_tree():
	event.deregister(self)
