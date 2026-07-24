class_name AtkComponent
extends Node

@onready var base_atk_mul: float = 1
@export var atk_stat: Stat

func attack(damage: float, target: HealthComponent):
	target.remove_hp(atk_stat.current_val(damage * base_atk_mul))
