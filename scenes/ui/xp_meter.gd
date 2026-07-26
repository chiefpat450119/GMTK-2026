class_name XPMeter
extends Control

## The meter is 1280 wide, the project's base resolution, and every child anchors
## as a fraction of that box, so the whole meter stays aligned at any size. The
## window's content scaling (Display > Stretch, canvas_items) fits the base
## resolution to the screen, so nothing here has to scale itself: under the
## "expand" aspect the viewport is never narrower than the base, so the meter
## always has its full width to sit in.

@export var xp_bar: TextureProgressBar
@export var level_label: Label
@export var xp_label: Label


func update_xp(level: int, xp: int, requirement: int) -> void:
	xp_bar.max_value = requirement
	xp_bar.value = xp
	level_label.text = "Lv %d" % level
	xp_label.text = "%d / %d" % [xp, requirement]
