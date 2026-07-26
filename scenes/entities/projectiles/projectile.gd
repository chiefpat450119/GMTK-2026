class_name Projectile
extends Area2D
## Straight-flying projectile shared by the player's guns and enemy shooters.
##
## The only difference between a player shot and an enemy shot is who it may hit
## and how its damage was rolled — both of which the shooter decides at spawn —
## so a single scene covers both. Instance it, add it to the tree, then call
## launch(); everything after that is self-contained.

enum Team { PLAYER, ENEMY }

@export var speed: float
@export var lifetime: float
@export var damage_popup : DamageNumberPopup

var team: Team = Team.PLAYER
var damage: float
var penetration: int = 0
var trail_settings: TrailSettings

var _velocity := Vector2.ZERO
var _spent_on: Array[Node2D] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	body_entered.connect(_on_body_entered)


## Places, aims and arms the projectile. Call once, right after adding it to the
## tree. Damage is the final rolled number — the projectile applies it as given.
func launch(from: Vector2, angle: float, fired_by: Team, dmg: float, pierce: int = 0) -> void:
	global_position = from
	global_rotation = angle
	# Physics interpolation blends between the last two physics transforms, and this
	# node's first one is wherever add_child() left it — the origin. Without this the
	# shot renders streaking in from world origin instead of leaving the muzzle.
	reset_physics_interpolation()
	team = fired_by
	damage = dmg
	penetration = pierce
	_velocity = Vector2(speed, 0).rotated(angle)

	# Target filtering: mask in the opposing team only, so a projectile is
	# physically incapable of overlapping a friendly and no hit-time check for
	# "is this one of mine" is needed.
	collision_mask = CollisionLayers.ENEMY if team == Team.PLAYER else CollisionLayers.PLAYER

	# After the interpolation reset above, so the trail's first sample is the muzzle
	# rather than the origin the node was added at. The trail is parented to the scene
	# and outlives this projectile on purpose; see projectile_trail.gd.
	if trail_settings:
		ProjectileTrail.spawn(self, trail_settings)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body in _spent_on:
		return
	_spent_on.append(body)

	# The mask already guarantees body is a valid target, so anything with a
	# damageable pool takes the hit regardless of its concrete type. Enemies
	# spend health; the player spends time.
	var health := HealthComponent.find_in(body)
	if health:
		SFX.play(&"enemy_hit")
		health.remove_hp(damage)
		damage_popup.create_popup(roundi(damage), body.global_position) # Round to nearest whole num
	else:
		var time := TimeComponent.find_in(body)
		if time:
			time.damage(damage)

	# A body with no damageable pool still soaks a pierce — it blocked the shot
	# either way.
	if penetration <= 0:
		queue_free()
	else:
		penetration -= 1
