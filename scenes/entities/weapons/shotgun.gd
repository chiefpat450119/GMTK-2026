class_name Shotgun
extends Gun

@export var base_projectile_count : float

func shoot():
	if (can_fire):
		can_fire = false
		for i in range(base_projectile_count):
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
