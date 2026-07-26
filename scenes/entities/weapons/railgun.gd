class_name Railgun
extends Gun

@export var max_charge_amount : float
@export var charge_rate : float
@export var max_damage : float

# A full charge kicks this much harder than a tapped shot, since it's the one
# weapon where the player chose to make the shot big.
const CHARGED_TRAUMA_SCALE : float = 3.0

## SoundBank id for the wind-up. Unlike the one-shots this is sustained, so it is
## started, retuned and stopped explicitly rather than fired and forgotten.
@export var charge_sfx : StringName

## How far the wind-up bends up by the time the coil is full.
const CHARGE_PITCH_RISE : float = 0.6

var cur_charge_amt : float = 0.0
var is_charging : bool = false

# The sound lives on the SFX autoload, not on this node, so nothing stops it if
# the run is torn down mid-charge — it would hold that note over the menus.
func _exit_tree() -> void:
	_end_charge_sfx()


func _ready() -> void:
	super._ready()
	# When the tree is paused (upgrade screen, pause menu, gun select) the
	# action_released event for Fire is never delivered. Without intervention
	# is_charging stays true: the gun keeps draining time and playing the
	# wind-up sound into the resumed game. Resetting on every return to
	# PLAYING catches all modal screens in one place.
	if GameStateManager.instance:
		GameStateManager.instance.state_changed.connect(_on_state_changed)


func _on_state_changed(_from: int, to: int) -> void:
	if to == GameStateManager.GameState.PLAYING:
		_cancel_charge()


## Aborts an in-progress charge without firing: resets state, clears charge
## accumulator, and silences the wind-up sound.
func _cancel_charge() -> void:
	if not is_charging:
		return
	is_charging = false
	cur_charge_amt = 0.0
	sprite.modulate = Color.WHITE
	_end_charge_sfx()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_charging and can_fire:
		cur_charge_amt = minf(cur_charge_amt + charge_rate * delta, max_charge_amount)
		Player.instance.time_component.remove_time(base_cost * delta)
		spend_sand_event.raise()
		sprite.modulate = Color.RED.lerp(Color.WHITE, 1.0 - (cur_charge_amt / max_charge_amount))
		SFX.set_pitch(charge_sfx, 1.0 + _charge_ratio(cur_charge_amt) * CHARGE_PITCH_RISE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Fire") and can_fire:
		is_charging = true
		SFX.play(charge_sfx)

	if event.is_action_released("Fire") and is_charging:
		is_charging = false
		_end_charge_sfx()
		var charge := cur_charge_amt
		cur_charge_amt = 0.0
		shoot(charge)

func _charge_ratio(charge: float) -> float:
	if max_charge_amount <= 0.0:
		return 0.0
	return clampf(charge / max_charge_amount, 0.0, 1.0)

# stop() resets the pitch too, so the next wind-up starts from the bottom again.
func _end_charge_sfx() -> void:
	SFX.stop(charge_sfx)

func shoot(charge: float = 0.0) -> void:
	if not can_fire:
		return

	can_fire = false
	var projectile : Projectile = projectile_scene.instantiate()
	projectile.speed = projectile_speed
	get_tree().current_scene.add_child(projectile)
	var shot_spread := shot_spread_stat.current_val(base_spread)
	projectile.launch(
		projectile_spawn_point.global_position,
		global_rotation + deg_to_rad(randf_range(-shot_spread, shot_spread)),
		Projectile.Team.PLAYER,
		damage_stat.current_val(base_damage + pow(charge, 2) * (max_damage - base_damage) / pow(max_charge_amount, 2)),
		base_penetration,
	)

	var charge_ratio := _charge_ratio(charge)
	_shake_camera(shot_trauma * lerpf(1.0, CHARGED_TRAUMA_SCALE, charge_ratio))
	# This overrides Gun.shoot() outright rather than calling into it, so the shot
	# report has to be raised here as well.
	SFX.play(fire_sfx)

	# Fire cooldown
	sprite.modulate = Color(0.198, 0.198, 0.198, 1.0)
	await get_tree().create_timer(fire_cooldown_stat.current_val(base_fire_cooldown)).timeout
	sprite.modulate = Color.WHITE
	can_fire = true
	SFX.play(reload_sfx)
