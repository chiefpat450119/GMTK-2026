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


# used by upgrade manager to generate runtime instance
func create_instance() -> UpgradeInstance: 
	return UpgradeInstance.new(self)

# Auto description falls back to joining each effect's describe() line.
func get_description() -> String:
	if not description_override.is_empty():
		return description_override
	var lines := PackedStringArray()
	for effect in effects:
		lines.append(effect.describe())
	return "\n".join(lines)


## Override `create_instance()` in subclasses to provide custom runtime behavior.
## Default instances apply all `effects` immediately when `UpgradeInstance.start()` is called.
