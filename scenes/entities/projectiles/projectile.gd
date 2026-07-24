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

var team: Team = Team.PLAYER
var damage: float

var _velocity := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	body_entered.connect(_on_body_entered)


## Places, aims and arms the projectile. Call once, right after adding it to the
## tree. Damage is the final rolled number — the projectile applies it as given.
func launch(from: Vector2, angle: float, fired_by: Team, dmg: float) -> void:
	global_position = from
	global_rotation = angle
	team = fired_by
	damage = dmg
	_velocity = Vector2(speed, 0).rotated(angle)

	# Target filtering: mask in the opposing team only, so a projectile is
	# physically incapable of overlapping a friendly and no hit-time check for
	# "is this one of mine" is needed.
	collision_mask = CollisionLayers.ENEMY if team == Team.PLAYER else CollisionLayers.PLAYER


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# The mask already guarantees body is a valid target, so anything with a
	# damageable pool takes the hit regardless of its concrete type. Enemies
	# spend health; the player spends time.
	var health := HealthComponent.find_in(body)
	if health:
		health.remove_hp(damage)
	else:
		var time := TimeComponent.find_in(body)
		if time:
			time.remove_time(damage)

	queue_free()
