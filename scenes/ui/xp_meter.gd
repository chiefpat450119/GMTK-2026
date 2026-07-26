class_name XPMeter
extends Control

## Width the meter's art and anchors are authored against. Every child anchors
## as a fraction of this box, so the whole meter stays aligned at any size.
const DESIGN_WIDTH := 1280.0

@export var xp_bar: TextureProgressBar
@export var level_label: Label
@export var xp_label: Label


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_viewport)
	resized.connect(_fit_to_viewport)
	_fit_to_viewport()

## Keeps the meter fully on screen on windows narrower than the design width.
## Never scales up: the rest of the HUD is fixed-size, so growing here would
## make the meter inconsistent with it on large windows.
func _fit_to_viewport() -> void:
	pivot_offset = Vector2(size.x * 0.5, 0.0)
	var s := minf(1.0, get_viewport_rect().size.x / DESIGN_WIDTH)
	scale = Vector2(s, s)

func update_xp(level: int, xp: int, requirement: int) -> void:
	xp_bar.max_value = requirement
	xp_bar.value = xp
	level_label.text = "Lv %d" % level
	xp_label.text = "%d / %d" % [xp, requirement]
