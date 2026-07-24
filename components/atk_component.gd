class_name AtkComponent
extends Node

@export var atk_stat: Stat

func attack(damage: float, target: TimeComponent):
	target.remove_time(damage_for(damage))

# Final damage this entity deals for a given base, with global atk mods applied.
# Use this when the hit lands somewhere else — on a projectile, say — instead of
# right here, so detached damage still scales with the same stat.
func damage_for(base: float) -> float:
	return atk_stat.current_val(base)
