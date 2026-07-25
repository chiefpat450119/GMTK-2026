class_name Gun
extends Node2D

@export var sprite : Sprite2D
@export var base_damage : float
@export var base_fire_cooldown : float
@export var base_spread : float
@export var base_cost : float
@export var base_penetration : int = 0

@export_category("Player Weapon Stats")
@export var damage_stat : Stat
@export var fire_cooldown_stat : Stat
@export var shot_spread_stat : Stat
@export var shot_cost_stat : Stat

@export_category("Projectile Info")
@export var projectile_scene : PackedScene
@export var projectile_spawn_point : Node2D


## Projectiles per shot. Above 1 they all leave on the same trigger pull, each
## rolling its own spread — that alone makes a shotgun.
@export var projectile_count : int = 1

@export_category("Feel")
## Camera trauma per trigger pull. Well under what a hit is worth: this fires
## constantly, so it wants to read as recoil rather than as an event.
@export var shot_trauma : float = 0.2
const SUSTAINED_TRAUMA_LIMIT : float = 2.0

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Fire"):
		shoot()

func shoot() -> void:
	if not can_fire:
		return

	can_fire = false
	Player.instance.time_component.remove_time(shot_cost_stat.current_val(base_cost))
	for i in projectile_count:
		_spawn_projectile()

	# Once per trigger pull, not per pellet — a shotgun blast is one kick.
	_shake_camera(shot_trauma)

	# Fire cooldown
	await get_tree().create_timer(fire_cooldown_stat.current_val(base_fire_cooldown)).timeout
	can_fire = true

func _shake_camera(trauma : float) -> void:
	CameraShake.shake_capped(trauma, trauma * SUSTAINED_TRAUMA_LIMIT)

func _spawn_projectile() -> void:
	var projectile : Projectile = projectile_scene.instantiate()

	# Parented to the scene, not the gun, so shots keep flying independently of
	# what the gun does after firing.
	get_tree().current_scene.add_child(projectile)

	var shot_spread := shot_spread_stat.current_val(base_spread)
	projectile.launch(
		projectile_spawn_point.global_position,
		global_rotation + deg_to_rad(randf_range(-shot_spread, shot_spread)),
		Projectile.Team.PLAYER,
		damage_stat.current_val(base_damage),
		base_penetration,
	)
