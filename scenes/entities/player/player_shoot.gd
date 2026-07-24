extends CharacterBody2D

@export var sprite : Sprite2D

@export var bullet_scene : PackedScene
@export var bullet_spawn_point : Node2D

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	if abs(rad_to_deg(transform.get_rotation())) > 90:
		sprite.flip_v = true
	else:
		sprite.flip_v = false
	
	# Makes the gun look like it's rotating around the player in 3D space
	if rad_to_deg(transform.get_rotation()) < -45 and rad_to_deg(transform.get_rotation()) > -135:
		sprite.z_index = 1
	else:
		sprite.z_index = 3

	if Input.is_action_just_pressed("M1"):
		var bullet : Node2D = bullet_scene.instantiate()
		bullet.global_transform = bullet_spawn_point.global_transform
		bullet.rotation = rotation
		add_child(bullet)
