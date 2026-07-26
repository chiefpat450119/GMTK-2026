class_name DashShockwave
extends Node
## Damages enemies around the dasher the instant a dash begins.
##
## Inert until an upgrade mods damage above zero, so this can sit on the player
## unconditionally and the upgrade stays a plain stat change — which also means
## StatRegistry clears it between runs like every other stat, with no instance
## left over to unhook.

## Enemy physics layer, from project.godot (2d_physics/layer_4="Enemy"). Matches
## what projectiles mask against, so the blast hits exactly what a bullet would.
const ENEMY_LAYER_MASK := 1 << 3

## Ceiling on bodies one blast can return. Well past the count a dash can
## realistically be surrounded by; intersect_shape needs *some* bound.
const MAX_TARGETS := 32

@export var dash_component: DashComponent
@export var damage: Stat
@export var radius: Stat
## Spawns the floating numbers. The blast damages enemies without a projectile
## ever touching them, so it needs its own popup rather than borrowing a bullet's.
@export var damage_popup: DamageNumberPopup


func _ready() -> void:
	if dash_component == null:
		push_warning("DashShockwave has no DashComponent assigned")
		return
	dash_component.dash_started.connect(_on_dash_started)


func _on_dash_started(origin: Vector2, _iframe_duration: float) -> void:
	var dmg := damage.current_val()
	var blast_radius := radius.current_val()
	# Nothing has granted the shockwave yet, which is the common case.
	if dmg <= 0.0 or blast_radius <= 0.0:
		return

	var body := dash_component.body
	if body == null:
		return

	_show_ring(origin, blast_radius)

	var shape := CircleShape2D.new()
	shape.radius = blast_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, origin)
	query.collision_mask = ENEMY_LAYER_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false

	# One query at the dash's start rather than an Area2D switched on for its
	# duration: monitoring only reports overlaps on the *following* physics frame,
	# so a short dash could end before the blast ever saw anyone.
	var space := body.get_world_2d().direct_space_state
	for hit in space.intersect_shape(query, MAX_TARGETS):
		var health := HealthComponent.find_in(hit.collider)
		if health:
			health.remove_hp(dmg)
			if damage_popup and hit.collider is Node2D:
				# Rounded like the projectile's, so a blast and a bullet dealing the
				# same damage can't read as two different numbers.
				damage_popup.create_popup(roundi(dmg), hit.collider.global_position)


# Handed the same radius the query above is built from, rather than reading the
# stat again: one read per blast is what keeps the ring honest about the area that
# actually got hit.
func _show_ring(origin: Vector2, blast_radius: float) -> void:
	# The world, not the player — a ring parented to the dasher would be towed
	# along by the dash and stop marking where the blast went off.
	var world := dash_component.body.get_parent()
	if world == null:
		return
	var ring := DashShockwaveVFX.new()
	ring.setup(origin, blast_radius)
	world.add_child(ring)
