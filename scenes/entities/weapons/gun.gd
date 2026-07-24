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

@export_category("Projectile Info")
@export var projectile_scene : PackedScene
@export var projectile_spawn_point : Node2D
## Projectiles per shot. Above 1 they all leave on the same trigger pull, each
## rolling its own spread — that alone makes a shotgun.
@export var projectile_count : int = 1

var can_fire : bool = true

func _physics_process(_delta: float) -> void:
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

func shoot():
	if not can_fire:
		return

	can_fire = false
	for i in projectile_count:
		_spawn_projectile()

	# Fire cooldown
	await get_tree().create_timer(firerate_stat.current_val(base_fire_cooldown)).timeout
	can_fire = true

func _spawn_projectile():
	var projectile : Projectile = projectile_scene.instantiate()

	# Parented to the scene, not the gun, so shots keep flying independently of
	# what the gun does after firing.
	get_tree().current_scene.add_child(projectile)

	var accuracy := accuracy_stat.current_val(base_accuracy)
	projectile.launch(
		projectile_spawn_point.global_position,
		global_rotation + deg_to_rad(randf_range(-accuracy, accuracy)),
		Projectile.Team.PLAYER,
		damage_stat.current_val(base_damage),
	)
