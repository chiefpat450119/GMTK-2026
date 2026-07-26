class_name XPMeter
extends Control

@export var xp_bar: TextureProgressBar
@export var level_label: Label
@export var xp_label: Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func update_xp(level: int, xp: int, requirement: int) -> void:
	xp_bar.max_value = requirement
	xp_bar.value = xp
	level_label.text = "Lv %d" % level
	xp_label.text = "%d / %d" % [xp, requirement]
