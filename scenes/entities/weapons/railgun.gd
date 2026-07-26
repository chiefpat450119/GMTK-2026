class_name Railgun
extends Gun

@export var max_charge_amount : float
@export var charge_rate : float

# A full charge kicks this much harder than a tapped shot, since it's the one
# weapon where the player chose to make the shot big.
const CHARGED_TRAUMA_SCALE : float = 3.0

var cur_charge_amt : float = 0.0
var is_charging : bool = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_charging and can_fire:
		cur_charge_amt = minf(cur_charge_amt + charge_rate * delta, max_charge_amount)
		Player.instance.time_component.remove_time(base_cost * delta)
		spend_sand_event.raise()
		sprite.modulate = Color.RED.lerp(Color.WHITE, 1.0 - (cur_charge_amt / max_charge_amount))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Fire") and can_fire:
		is_charging = true

	if event.is_action_released("Fire") and is_charging:
		is_charging = false
		var charge := cur_charge_amt
		cur_charge_amt = 0.0
		shoot(charge)

func shoot(charge: float = 0.0) -> void:
	if not can_fire:
		return

	can_fire = false
	var projectile : Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	var shot_spread := shot_spread_stat.current_val(base_spread)
	projectile.launch(
		projectile_spawn_point.global_position,
		global_rotation + deg_to_rad(randf_range(-shot_spread, shot_spread)),
		Projectile.Team.PLAYER,
		damage_stat.current_val(base_damage + pow(charge, 2)),
		base_penetration,
	)

	var charge_ratio := charge / max_charge_amount if max_charge_amount > 0.0 else 0.0
	_shake_camera(shot_trauma * lerpf(1.0, CHARGED_TRAUMA_SCALE, clampf(charge_ratio, 0.0, 1.0)))

	# Fire cooldown
	sprite.modulate = Color(0.198, 0.198, 0.198, 1.0)
	await get_tree().create_timer(fire_cooldown_stat.current_val(base_fire_cooldown)).timeout
	sprite.modulate = Color.WHITE
	can_fire = true
