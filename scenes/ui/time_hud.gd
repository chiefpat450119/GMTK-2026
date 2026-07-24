class_name TimeHud
extends CanvasLayer

# Remainders below this don't earn a stub segment. Segment art dimensions live
# on BarSegment, which is the only thing that needs them.
const REMAINDER_EPSILON := 0.01

## Time each bar segment represents. Segment count times this should equal
## max_time, or the fill won't reach the last pin.
@export var units_per_segment: int = 10
## Seconds the readout takes to roll up to a newly gained value.
@export var count_duration: float = 0.4

@export var gear: Control
@export var hourglass: Control
@export var hourglassLabel: Label
@export var fill: ProgressBar
@export var time_listener: GameEventListener
@export var row: HBoxContainer
@export var segment_scene: PackedScene

# The real time value, straight off the component.
var _target: float = 0.0
# What the readout is showing. Equal to _target except while rolling up.
var _shown: float = 0.0
var _shown_whole: int = -1
var _roll_from: float = 0.0
var _rolling: bool = false
var _synced: bool = false
var _roll_tween: Tween


func _ready() -> void:
	time_listener.response.connect(_on_time_changed)
	# The player enters the tree alongside this, so take the opening reading late.
	call_deferred("_on_time_changed")


# TimeComponent raises its event on every change, including the decay it applies
# each frame, so this is the only thing driving the readout.
func _on_time_changed() -> void:
	var time_component := Player.instance.time_component

	# max_time is a Stat, so the cap moves when an upgrade adds a modifier.
	# Guarded because this fires every frame that decay runs, and rebuilding the
	# row is only worth doing when the cap actually moved.
	var cap := time_component.max_time.current_val()
	if not is_equal_approx(cap, fill.max_value):
		set_time_cap(cap)

	var previous := _target
	_target = time_component.time_left

	if not _synced:
		# First reading: snap, so the HUD doesn't roll up from zero on spawn.
		_synced = true
		_apply(_target)
	elif _target - previous >= 1:
		_add_time(_target - previous)
	elif not _rolling:
		# Decay arrives as a stream of small decreases, which just track. While
		# a roll-up is running it owns the readout instead.
		_apply(_target)


## Rebuilds the bar to represent `seconds` of time: one segment per
## `units_per_segment`, plus a short final segment for any remainder. A cap of 34
## with 10s segments gives three full segments and a 4s stub. Pins are renumbered
## to match, with the last one showing the cap itself.
func set_time_cap(seconds: float) -> void:
	fill.max_value = seconds

	var full := floori(seconds / units_per_segment)
	var remainder := seconds - full * units_per_segment
	var partial := remainder > REMAINDER_EPSILON
	_fit_segments(full + (1 if partial else 0))

	var segments := _segments()
	for i in segments.size():
		var is_stub := partial and i == full
		var covers: float = remainder if is_stub else float(units_per_segment)
		var mark: float = seconds if is_stub else float((i + 1) * units_per_segment)
		segments[i].set_span(covers / units_per_segment, mark)


func get_segment_count() -> int:
	return _segments().size()


# Grows or shrinks the row to `count` segments. New ones come from
# segment_scene, so art edits live in bar_segment.tscn and reach every segment.
func _fit_segments(count: int) -> void:
	var segments := _segments()
	count = maxi(count, 0)

	while segments.size() > count:
		var last: BarSegment = segments.pop_back()
		# Detached before freeing, so the row re-sorts now rather than whenever
		# the queued free lands.
		row.remove_child(last)
		last.queue_free()

	while segments.size() < count:
		var segment := segment_scene.instantiate() as BarSegment
		row.add_child(segment)
		# add_child appends past EndSlot, so put it back in front of the cap.
		row.move_child(segment, row.get_child_count() - 2)
		segments.append(segment)


func _segments() -> Array[BarSegment]:
	var found: Array[BarSegment] = []
	for child in row.get_children():
		if child is BarSegment:
			found.append(child)
	return found


## Plays the time-gained reaction: rolls the readout up and kicks the mechanism.
## Called automatically when the component reports a gain, and safe to call
## directly.
func _add_time(amount: float) -> void:
	if is_zero_approx(amount):
		return

	_roll_readout()
	_play_mechanism()


# Interpolates a 0..1 weight rather than a fixed end value, so decay landing
# mid-roll is tracked and the readout finishes on the real number.
func _roll_readout() -> void:
	_roll_from = _shown
	_rolling = true

	_roll_tween = _restart(_roll_tween)
	_roll_tween.tween_method(_roll, 0.0, 1.0, count_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_roll_tween.tween_callback(_end_roll)


func _roll(weight: float) -> void:
	_apply(lerpf(_roll_from, _target, weight))


func _end_roll() -> void:
	_rolling = false


func _apply(value: float) -> void:
	_shown = value
	fill.value = value

	# Only touch the Label when the whole number changes; assigning text
	# re-shapes it every time.
	var whole := roundi(value)
	if whole != _shown_whole:
		_shown_whole = whole
		hourglassLabel.text = str(whole)


func _play_mechanism() -> void:
	var gear_tween := create_tween()
	var hourglass_tween := create_tween()

	hourglass_tween.tween_property(hourglass, "offset_transform_rotation", deg_to_rad(16), 0.1) \
			.set_ease(Tween.EASE_OUT)

	hourglass_tween.tween_property(hourglass, "offset_transform_rotation", deg_to_rad(145), 0.15) \
			.set_delay(0.1) \
			.set_ease(Tween.EASE_IN_OUT)

	hourglass_tween.tween_property(hourglass, "offset_transform_rotation", deg_to_rad(-16), 0.3) \
			.set_delay(0.15) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_BACK)

	gear_tween.tween_property(gear, "offset_transform_rotation", deg_to_rad(20), 0.1)
	gear_tween.tween_property(gear, "offset_transform_rotation", deg_to_rad(0), 0.15)
	gear_tween.tween_property(gear, "offset_transform_rotation", deg_to_rad(-40), 0.2).set_delay(0.1)
	gear_tween.tween_property(gear, "offset_transform_rotation", deg_to_rad(0), 0.2).set_delay(0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# Tweens are per-channel; a second pickup mid-animation restarts its own without
# disturbing the others. The guard is lifecycle, not setup: these start unset and
# only hold a tween once their channel has played at least once.
func _restart(tween: Tween) -> Tween:
	if tween:
		tween.kill()
	return create_tween()
