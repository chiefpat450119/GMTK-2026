class_name MachineGun
extends Gun

# _unhandled_input only fires once per event, so it can't drive continuous
# fire directly. Instead we use it to track whether the trigger is held, then
# poll that flag every physics tick to call shoot().
var _trigger_held: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("M1"):
		_trigger_held = true
	elif event.is_action_released("M1"):
		_trigger_held = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _trigger_held:
		shoot()
