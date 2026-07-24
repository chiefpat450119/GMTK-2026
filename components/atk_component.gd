class_name AtkComponent
extends Node

@export var atk_stat: Stat

func attack(damage: float, target: TimeComponent):
	target.remove_time(atk_stat.current_val(damage))
