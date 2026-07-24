class_name AtkComponent
extends Node

@export var atk_stat: Stat

func attack(damage: float, target: HealthComponent):
	target.remove_hp(atk_stat.current_val(damage))
