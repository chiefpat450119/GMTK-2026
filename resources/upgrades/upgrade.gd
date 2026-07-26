class_name Upgrade
extends Resource
## One selectable upgrade card.
##
## Holds display data and a list of UpgradeEffects. Applying it pushes a
## Modifier onto each targeted Stat. 

## Draw tier. Rarer tiers are drawn less often — see RARITY_WEIGHTS. Ordered
## common-to-rare so the enum reads as an escalation and so a card that forgot to
## set one lands on the harmless default rather than on Legendary.
enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

## Relative draw weight per tier. Higher == more common. These are the only draw
## weights in the pool: one knob per card, so rarity alone says how often it shows
## up and two tiers can't quietly disagree about what "rare" means.
const RARITY_WEIGHTS := {
	Rarity.COMMON: 10.0,
	Rarity.RARE: 5.0,
	Rarity.EPIC: 3.0,
	Rarity.LEGENDARY: 1.0,
}

@export var id: StringName = &""
@export var title: String = "New Upgrade"
## Leave blank to auto-generate the description from the effect list.
@export_multiline var description_override: String = ""
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
## How many times this upgrade may be taken. 0 == unlimited.
@export var max_stacks: int = 0
@export var effects: Array[UpgradeEffect] = []
@export var is_tradeoff: bool = false


## Relative draw weight in the pool, taken from this card's rarity.
func get_weight() -> float:
	return float(RARITY_WEIGHTS.get(rarity, 0.0))


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
