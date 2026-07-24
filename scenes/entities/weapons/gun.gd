class_name Gun
extends CharacterBody2D

@export var sprite : Sprite2D
@export var base_damage : float
@export var base_fire_cooldown : float
@export var base_accuracy : float
@export var base_cost : float

@export_category("Player Weapon Stats")
@export var damage_stat : Stat
@export var firerate_stat : Stat
@export var accuracy_stat : Stat

@export_category("Bullet Info")
@export var bullet_scene : PackedScene
@export var bullet_spawn_point : Node2D

var can_fire : bool = true

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())

	if abs(rad_to_deg(transform.get_rotation())) > 90:
		sprite.flip_v = true
	else:
		sprite.flip_v = false
	
	# Makes the gun look like it's rotating around the player in 3D space
	var left_threshold := -45
	var right_threshold := -135
	if rad_to_deg(transform.get_rotation()) < left_threshold and rad_to_deg(transform.get_rotation()) > right_threshold:
		sprite.z_index = 1
	else:
		sprite.z_index = 3

	if Input.is_action_pressed("M1"):
		shoot()

func shoot():
	if (can_fire):
		can_fire = false
		
		# Spawn bullet
		var bullet : Bullet = bullet_scene.instantiate()
		bullet.global_transform = bullet_spawn_point.global_transform
		bullet.damage = damage_stat.current_val(base_damage)
		# Add inaccuracy
		var rng := RandomNumberGenerator.new()
		var accuracy := accuracy_stat.current_val(base_accuracy)
		bullet.rotation = rotation + deg_to_rad(rng.randf_range(-accuracy, accuracy))
		add_child(bullet)
		
		# Fire cooldown
		await get_tree().create_timer(firerate_stat.current_val(base_fire_cooldown)).timeout
		can_fire = true
