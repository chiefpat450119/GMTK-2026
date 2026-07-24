class_name Upgrade
extends Resource
## One selectable upgrade card.
##
## Holds display data and a list of UpgradeEffects. Applying it pushes a
## Modifier onto each targeted Stat. 

@export var id: StringName = &""
@export var title: String = "New Upgrade"
## Leave blank to auto-generate the description from the effect list.
@export_multiline var description_override: String = ""
@export var icon: Texture2D
## Relative draw weight in the pool. Higher == more common.
@export var weight: float = 1.0
## How many times this upgrade may be taken. 0 == unlimited.
@export var max_stacks: int = 0
@export var effects: Array[UpgradeEffect] = []


# Auto description falls back to joining each effect's describe() line.
func get_description() -> String:
	if not description_override.is_empty():
		return description_override
	var lines := PackedStringArray()
	for effect in effects:
		lines.append(effect.describe())
	return "\n".join(lines)


# Applies every effect. stack_index makes each application's Modifier ids
# unique so a later remove_mod() can target a specific stack if ever needed.
func apply(stack_index: int = 0) -> void:
	for effect in effects:
		if effect.target_stat == null:
			push_warning("Upgrade '%s' has an effect with no target_stat" % id)
			continue
		var mod_id := StringName("upgrade:%s#%d" % [id, stack_index])
		effect.target_stat.add_mod(mod_id, effect.value, effect.operation)
