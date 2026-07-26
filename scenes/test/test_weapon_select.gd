extends Node

@export var gun_offer_event: GameEvent

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_O:
			gun_offer_event.raise()
