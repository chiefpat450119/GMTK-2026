# Harness for tuning the TimeHud gain animation. The button grants time through
# TimeComponent rather than poking the HUD, so what you see is the real path:
# add_time -> time_changed_event -> TimeHud._on_time_changed -> _add_time.
#
# Tweak the exports on the TimeHud node while the scene is running (remote
# inspector) and press the button to replay the animation.

extends Node2D

## Time granted per press. Set this negative to check the reverse flourish.
@export var amount: float = 10.0
## Where the bar starts, and where it drops back to when it runs out of
## headroom, so every press has room to show a gain.
@export var start_time: float = 10.0
## Stops TimeComponent draining, so the readout holds still between presses.
## Uncheck to tune against live decay instead.
@export var freeze_decay: bool = true

@export var button: Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

	var time_component := Player.instance.time_component
	# TimeHud takes its opening reading on a deferred call, so this lands first.
	time_component.time_left = start_time
	if freeze_decay:
		time_component.set_process(false)

	# The player is only here to own the TimeComponent. Stop it reading input so
	# clicking the button doesn't also drive it around and fire the shotgun.
	Player.instance.set_physics_process(false)


func _on_button_pressed() -> void:
	var time_component := Player.instance.time_component

	if time_component.time_left + amount > time_component.max_time.current_val():
		time_component.remove_time(time_component.time_left)

	time_component.add_time(amount)
