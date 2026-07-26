class_name VictoryOnDeath
extends Node

@export var health: HealthComponent  # Defaults to the health component on our parent
## Seconds between the death and the victory screen. Long enough for
## DisintegrateOnDeath's crumble to finish, so the boss is seen to die rather than
## blinking out under the screen — the tree is paused for VICTORY, and whatever is
## still mid-animation when it lands freezes there.
@export var delay: float = 1.2


func _ready() -> void:
	if health == null:
		health = HealthComponent.find_in(get_parent())

	if health == null:
		push_warning("VictoryOnDeath on %s needs a HealthComponent" % get_parent().name)
		return

	health.died.connect(_on_died)


# HealthComponent frees the body on this same call, so the wait is handed to
# GameStateManager rather than kept here — a timer awaited on this node would come
# back to a freed object. The manager marks the run won as soon as this lands, so
# the clock running out during the wait can't take the win back.
func _on_died() -> void:
	if GameStateManager.instance == null:
		return
	GameStateManager.instance.victory(delay)
