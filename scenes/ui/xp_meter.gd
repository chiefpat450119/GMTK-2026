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

## Seconds the bar takes to roll up to a newly gained value.
@export var fill_duration: float = 0.4

var _synced: bool = false
var _shown: float = 0.0
var _roll_from: float = 0.0
var _roll_target: float = 0.0
var _roll_tween: Tween


func update_xp(level: int, xp: int, requirement: int) -> void:
	xp_bar.max_value = requirement
	level_label.text = "Lv %d" % level
	xp_label.text = "%d / %d" % [xp, requirement]

	if not _synced:
		# First reading: snap so the bar doesn't animate up from its scene default.
		_synced = true
		_cancel_roll()
		_apply(xp)
	elif xp < _shown:
		# Level-up: the bar rolled over, so snap to the new position instantly.
		_cancel_roll()
		_apply(xp)
	elif xp > _shown:
		_roll_to(xp)


func _roll_to(target: float) -> void:
	_roll_from = _shown
	_roll_target = target

	if _roll_tween:
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.tween_method(_roll, 0.0, 1.0, fill_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _roll(weight: float) -> void:
	_apply(lerpf(_roll_from, _roll_target, weight))


func _apply(value: float) -> void:
	_shown = value
	xp_bar.value = value


func _cancel_roll() -> void:
	if _roll_tween:
		_roll_tween.kill()
		_roll_tween = null
