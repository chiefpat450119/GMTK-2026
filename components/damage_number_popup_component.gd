class_name DamageNumberPopup
extends Node

@export var damage_number : PackedScene

func _ready() -> void:
	pass

func create_popup(num : float, pos : Vector2):
	var dmg_num_instance : DamageNumber = damage_number.instantiate()
	get_tree().current_scene.add_child(dmg_num_instance)
	dmg_num_instance.global_position = pos
	dmg_num_instance.label.text = str(num)
