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
@export var damage_fill : ProgressBar
@export var time_listener: GameEventListener
@export var damaged_listener: GameEventListener
@export var spend_sand_listener: GameEventListener
@export var row: HBoxContainer
@export var segment_scene: PackedScene
@export var machine_sand_scene : PackedScene
@export var num_popup_scene : PackedScene
@export var sand_spawn_point : Control
@export var num_popup_spawn_point : Control

var _previous: float = 0.0
var _target: float = 0.0
var _shown: float = 0.0
var _shown_whole: int = -1
var _roll_from: float = 0.0
var _is_damage_rolling: bool = false
var _rolling: bool = false
var _synced: bool = false
var _roll_tween: Tween
var _color_tween: Tween
var _damage_tween: Tween
@onready var _fill_style: StyleBoxFlat = _own_fill_style()
@onready var _original_color: Color = _fill_style.bg_color

func _ready() -> void:
	
	time_listener.response.connect(_on_time_changed)
	damaged_listener.response.connect(_on_take_damage)
	spend_sand_listener.response.connect(_on_spend_sand)
	# The player enters the tree alongside this, so take the opening reading late.
	call_deferred("_on_time_changed")


# TimeComponent raises its event on every change, including the decay it applies
# each frame, so this is the only thing driving the readout.
func _on_time_changed() -> void:
	# This HUD lives in the shell and outlives the run, so between runs — on the
	# menus, and for the deferred opening read at boot — there is no player to
	# read from yet.
	if Player.instance == null:
		return
	var time_component := Player.instance.time_component

	# max_time is a Stat, so the cap moves when an upgrade adds a modifier.
	# Guarded because this fires every frame that decay runs, and rebuilding the
	# row is only worth doing when the cap actually moved.
	var cap := time_component.max_time.current_val()
	if not is_equal_approx(cap, fill.max_value):
		set_time_cap(cap)

	_previous = _target
	_target = time_component.time_left
	

	if not _synced:
		# First reading: snap, so the HUD doesn't roll up from zero on spawn.
		_synced = true
		_apply(_target)
	elif _target - _previous >= 0:
		_add_time(_target - _previous)
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


## Plays the time-gained reaction: rolls the readout up, kicks the mechanism,
## and displays a number popup.
## Called automatically when the component reports a gain, and safe to call
## directly.
func _add_time(amount: float) -> void:
	if is_zero_approx(amount):
		return
	
	_play_sand_intake_animation()
	_roll_readout()
	_play_mechanism()
	_flash_fill()

## Plays the time-removed reaction: displays time removed segment and rolls it down.
## Called automatically when TimeComponent emits the damaged signal
func _on_take_damage() -> void:
	# Resize damage bar to match time amount before damage taken
	damage_fill.max_value = fill.max_value
	damage_fill.anchor_right = fill.anchor_right
	if not _is_damage_rolling:
		damage_fill.value = _previous

	_is_damage_rolling = true
	
	# Damage bar drains down to new health
	damage_fill.show()
	_damage_tween = _restart(_damage_tween)
	var init_wait := 0.2
	var duration := 0.5
	# Accounts for the time that has passed while the tween is happening
	var dest := _shown - (duration + init_wait) 
	_damage_tween.tween_property(damage_fill, "value", dest, duration)\
	.set_delay(init_wait)\
	.set_ease(Tween.EASE_IN)\
	.set_trans(Tween.TRANS_CUBIC)
	_damage_tween.tween_callback(on_damage_tween_end)

func on_damage_tween_end():
	damage_fill.hide()
	_is_damage_rolling = false

## Creates a number popup to display amount of sand spent when shooting guns
func _on_spend_sand() -> void:
	var num_popup_instance : SandAmountPopup = num_popup_scene.instantiate()
	var sand_spent_amt =  snapped(_previous - _shown, 0.1)
	num_popup_instance.number_popup.text = "-" + str(sand_spent_amt)
	num_popup_instance.number_popup.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
	num_popup_spawn_point.add_child(num_popup_instance)

# Shows picked up sand being dropped into the intake pipe part of the
# time machine sprite and a number popup to show amount of sand gained
func _play_sand_intake_animation() -> void:
	var sand_instance : MachineSand = machine_sand_scene.instantiate()
	var sand_gained_amt =  snapped(_target - _shown, 0.1)
	var num_popup_instance : SandAmountPopup = num_popup_scene.instantiate()
	num_popup_instance.number_popup.text = "+" + str(sand_gained_amt)
	num_popup_instance.number_popup.add_theme_color_override("font_color", Color(1.0, 0.769, 0.0, 1.0))
	sand_spawn_point.add_child(sand_instance)
	num_popup_spawn_point.add_child(num_popup_instance)

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


# The fill stylebox is a scene sub-resource, so every instance of this scene
# shares one copy. Tweening it as-is would flash all of them together and, worse,
# leave the saved sub-resource holding whatever color the tween stopped on.
func _own_fill_style() -> StyleBoxFlat:
	var style := fill.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill.add_theme_stylebox_override("fill", style)
	return style


# Snaps the bar to white and fades it back, so a gain reads as a hit even when
# the fill barely moves. Snapping rather than tweening in means back-to-back
# pickups each get a visible peak instead of averaging into a dim glow. modulate
# is no good here: it tints the whole ProgressBar, and the fill's alpha would
# take the empty background down with it.
func _flash_fill() -> void:
	_color_tween = _restart(_color_tween)
	_fill_style.bg_color = Color.WHITE
	_color_tween.tween_property(_fill_style, "bg_color", _original_color, 0.25) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# Tweens are per-channel; a second pickup mid-animation restarts its own without
# disturbing the others. The guard is lifecycle, not setup: these start unset and
# only hold a tween once their channel has played at least once.
func _restart(tween: Tween) -> Tween:
	if tween:
		tween.kill()
	return create_tween()
