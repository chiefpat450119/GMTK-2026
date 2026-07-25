# One notch of the time bar: a stretchable background covering some span of time,
# capped by a fixed-width pin whose label marks the running total.
#
# TimeHud instances these to build the bar. Instancing (rather than duplicating a
# node) is what keeps the exported references below bound to each copy's own
# children.

class_name BarSegment
extends HBoxContainer

# Art-space width of a full segment, measured post-centre to post-centre, and the
# width of the post itself. Laid out as Background + Pin, so the background of a
# full segment is PITCH - PIN_WIDTH.
const PITCH := 271.0
const PIN_WIDTH := 31.0

@export var background: Control
@export var label: Label


## Sizes this segment to `fraction` of a full one (1.0 being full) and marks its
## pin with `mark`. A fraction below roughly 0.115 is narrower than the pin art
## itself, so the background bottoms out and the pin lands slightly right of true.
func set_span(fraction: float, mark: float) -> void:
	# Width is proportional to the time covered, so the fill stays linear across
	# the whole bar. The pin is fixed art, so only the background takes the slack.
	background.custom_minimum_size.x = maxf(fraction * PITCH - PIN_WIDTH, 0.0)
	label.text = str(roundi(mark))
