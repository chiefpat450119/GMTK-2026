# Crumbles the enemy this hangs off into dust when it dies.
#
# Drop it as a child of an enemy and it wires itself up: it finds the health
# component and the sprite on that enemy on its own, the same way HitFeedback does.
# Nothing has to be assigned and nothing has to call it — dying is the trigger, so
# any new enemy built on base_enemy.tscn gets the death for free.
#
# All this does is hand a still of the sprite to a DisintegrateEffect and park it
# next to the corpse; the effect owns the animation and frees itself. See
# disintegrate_effect.gd for why the body isn't kept alive to animate in place.

class_name DisintegrateOnDeath
extends Node

@export var health: HealthComponent  # Defaults to the health component on our parent
@export var sprite: Node2D  # Defaults to the first sprite on our parent
@export var effect_scene: PackedScene = preload("res://scenes/effects/disintegrate_effect.tscn")

## Seconds the crumble takes. Exported per enemy rather than fixed, because a tank
## holding its shape a beat longer is what sells it as heavy, and that same timing on
## a scout reads as sluggish. The default is the light-and-fast tuning.
@export var duration := 0.45


func _ready() -> void:
	if health == null:
		health = HealthComponent.find_in(get_parent())
	if sprite == null:
		sprite = Sprites.find_in(get_parent())

	if health == null or sprite == null:
		push_warning("DisintegrateOnDeath on %s needs a HealthComponent and a sprite" % get_parent().name)
		return

	health.died.connect(_on_died)


# The body is freed on this same call, so everything the effect needs is read here
# and now, and the effect is parented *beside* the corpse rather than inside it.
func _on_died() -> void:
	if effect_scene == null or sprite == null:
		return

	# The enemy's own parent, so the corpse lands in the same y-sorted world layer the
	# enemy was drawn in and settles into the right depth on its own.
	var host := get_parent().get_parent()
	if host == null:
		return

	var effect := effect_scene.instantiate() as DisintegrateEffect
	if effect == null:
		push_error("DisintegrateOnDeath on %s: effect_scene must have a DisintegrateEffect root" % get_parent().name)
		return

	effect.duration = duration
	effect.setup(sprite)
	host.add_child(effect)
