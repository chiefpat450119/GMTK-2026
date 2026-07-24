extends Node2D
## Debug harness for the upgrade system.
##
## Press U to raise the "offer upgrades" event. UpgradeUI listens on the same
## GameEvent channel, rolls cards from the UpgradeManager, pauses the tree
## while they're up, and applies whichever one is clicked.

@export var offer_event: GameEvent


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U:
			_offer()


func _offer() -> void:
	if offer_event == null:
		push_warning("No offer_event assigned on the test harness")
		return
	offer_event.raise()
