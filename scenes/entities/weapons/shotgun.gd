class_name Shotgun
extends Gun

# Firing a spread is just Gun with projectile_count > 1; see shotgun.tscn.

func _spawn_projectile() -> void:
	var projectile : Projectile = projectile_scene.instantiate()
	projectile.speed = get_speed(projectile_speed)
	projectile.trail_settings = projectile_trail

	# Parented to the scene, not the gun, so shots keep flying independently of
	# what the gun does after firing.
	get_tree().current_scene.add_child(projectile)

	var shot_spread := shot_spread_stat.current_val(base_spread)
	projectile.launch(
		projectile_spawn_point.global_position,
		global_rotation + deg_to_rad(randf_range(-shot_spread, shot_spread)),
		Projectile.Team.PLAYER,
		damage_stat.current_val(base_damage),
		get_penetration(),
	)

func get_speed(base: float) -> float:
	return base - (base * randf() * 0.4)
