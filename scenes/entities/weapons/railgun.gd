class_name Railgun
extends Gun

@export var charge_time : float
@export var max_charge_amount : float
@export var charge_rate : float

var cur_charge_amt : float = 0
var is_charging : bool = false


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
	
	# Holding left click charges up railgun
	if Input.is_action_pressed("M1") and can_fire:
		sprite.modulate = Color.RED
		is_charging = true
		print("Railgun charge amt: " + str(cur_charge_amt))
		cur_charge_amt += charge_rate * delta
		Player.instance.time_component.remove_time(base_cost)
		if cur_charge_amt >= max_charge_amount:
			cur_charge_amt = max_charge_amount
	
	# Releasing left click while charging fires the railgun
	if is_charging == true and Input.is_action_just_released("M1"):
		is_charging = false
		shoot()
		cur_charge_amt = 0

func shoot():
	can_fire = false
	# Spawn bullet
	var bullet : Bullet = bullet_scene.instantiate()
	bullet.global_transform = bullet_spawn_point.global_transform
	bullet.damage = damage_stat.current_val(base_damage + pow(cur_charge_amt, 2))
	# Add inaccuracy
	var rng := RandomNumberGenerator.new()
	var accuracy := accuracy_stat.current_val(base_accuracy)
	bullet.rotation = rotation + deg_to_rad(rng.randf_range(-accuracy, accuracy))
	add_child(bullet)
	
	# Fire cooldown
	sprite.modulate = Color(0.198, 0.198, 0.198, 1.0)
	await get_tree().create_timer(firerate_stat.current_val(base_fire_cooldown)).timeout
	sprite.modulate = Color.WHITE
	can_fire = true
