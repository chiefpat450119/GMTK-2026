class_name DashCooldown
extends Control

@export var fill: TextureProgressBar

func _ready() -> void:
	# The component reports a 0..1 ratio, so the bar reads it straight. step 0
	# keeps the sweep continuous instead of snapping to 1% notches.
	fill.min_value = 0.0
	fill.max_value = 1.0
	fill.step = 0.0
	fill.value = 0.0


# Nothing raises an event as the cooldown runs down, so this samples it. The
# player enters the tree alongside the HUD, hence the guard on the first frames.
func _process(_delta: float) -> void:
	if Player.instance == null:
		return
	fill.value = Player.instance.dash_component.cooldown_progress()
