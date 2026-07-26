class_name MachineGun
extends Gun

# _unhandled_input only fires once per event, so it can't drive continuous
# fire directly. Instead we use it to track whether the trigger is held, then
# poll that flag every physics tick to call shoot().
var _trigger_held: bool = false


func _ready() -> void:
	super._ready()
	# When the tree is paused (upgrade screen, pause menu, gun select) the
	# action_released event for Fire is never delivered, leaving _trigger_held
	# true after the screen closes. Resetting on every return to PLAYING
	# catches all of those cases without needing to special-case each screen.
	if GameStateManager.instance:
		GameStateManager.instance.state_changed.connect(_on_state_changed)


func _on_state_changed(_from: int, to: int) -> void:
	if to == GameStateManager.GameState.PLAYING:
		_trigger_held = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Fire"):
		_trigger_held = true
	elif event.is_action_released("Fire"):
		_trigger_held = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _trigger_held:
		shoot()
