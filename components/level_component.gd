class_name LevelComponent
extends Node
## Run progression. Sand is the only XP source, so how fast upgrades arrive is a
## direct function of how greedily the player collects — the same choice that
## keeps their clock alive also decides how strong they get.
##
## Per-run state, deliberately: this rides on the player, which is rebuilt with
## the world on every start_run(), so there is nothing here to reset.

## Emitted once per level gained. GameWorld routes this to the upgrade screen —
## this component doesn't know the upgrade system exists.
signal leveled_up(new_level: int)

## Raised on every XP or level change so the HUD can redraw.
@export var xp_changed_event: GameEvent
## XP needed to get from level 1 to level 2.
@export var base_requirement: float = 8.0
## Multiplied into the requirement once per level already gained.
@export var growth: float = 1.35

var level: int = 1
var xp: float = 0.0


## Returns the LevelComponent hanging off an entity, or null if it has none.
## Mirrors TimeComponent.find_in.
static func find_in(entity: Node) -> LevelComponent:
	for child in entity.get_children():
		if child is LevelComponent:
			return child
	return null


## XP required to get from the current level to the next one.
func requirement() -> float:
	return base_requirement * pow(growth, level - 1)


func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	xp += amount
	# At most one level per pickup. The upgrade screen is modal with no queue
	# behind it, so a pickup big enough for two levels banks the overflow and the
	# next one collects the second level.
	var needed := requirement()
	if xp >= needed:
		xp -= needed
		level += 1
		leveled_up.emit(level)
	if xp_changed_event:
		xp_changed_event.raise()
