class_name BossAttackState
extends State

@export var selector_state: SelectorState

@export var anim: AnimationPlayer

@export var atk_component: AtkComponent

@export var state_time: float = 2

@export var sprite: Sprite2D


func enter():
	switch_state(selector_state)
