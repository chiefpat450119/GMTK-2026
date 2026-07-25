class_name GunHolder
extends Node2D

const GUN_CLEARANCE: int = 50 # physical size allocation for a gun
const OFFSET := GUN_CLEARANCE * Vector2.UP

var guns: Array[Gun] = []

func equip_gun(gun: GunData):
	var gun_scene : Gun = gun.gun_scene.instantiate()
	if gun_scene == null:
		return
	add_child(gun_scene)
	guns.append(gun_scene)
	
	orient_children()

func equip_single(gun: GunData):
	remove_guns()
	equip_gun(gun)

func remove_guns():
	for gun in guns:
		gun.queue_free()
	
	guns.clear()

func orient_children():
	var num_children = guns.size()
	@warning_ignore("integer_division")
	var half_len = num_children * GUN_CLEARANCE / 2
	for i in range(guns.size()):
		guns[i].position = OFFSET * i - Vector2.UP * half_len
