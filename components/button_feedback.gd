# Hover, hold and click reaction for anything clickable.
#
# Drop as a child of the control that gets clicked — an upgrade card, a gun card,
# a menu button — and it wires itself to that parent. Nothing has to call it, and
# it is never told what the click *does*, so the upgrade screen and the gun select
# screen can share one copy of the feel without either knowing it exists. It
# reacts to a Button through the button signals and to a bare Control that reads
# its own clicks through raw events, which is the only difference between them.
#
# Rides Control's offset transform rather than scale/position/rotation. Those
# belong to the container: the cards sit in an HBoxContainer, and a card writing
# its own scale would either be re-laid-out under the tween or shove its
# neighbours along the row. The offset transform is visual only, which also pins
# the click rect where the layout put it — a button that swelled its own hitbox on
# hover flickers in and out of hover along the new edge, and a card that shrank it
# under a held mouse would drop the click.
#
# Every reaction is the same few properties moving to a new pose, so there is one
# place that decides where those properties belong and no way for a hover landing
# mid-click to settle the scale and strand the rotation.

class_name ButtonFeedback
extends Node

@export var target: Control  # Defaults to our parent

@export_group("Hover")
## Resting scale multiplier while hovered or focused.
@export var hover_scale := 1.15
## How far the button rises, as a fraction of its own height. Taken off the height
## rather than given in pixels because this rides cards over a thousand px tall
## and buttons a tenth of that.
@export var hover_lift := 0.012
## Degrees of lean while hovered. Neighbours lean opposite ways, see _tilt_sign.
@export var hover_tilt := 1.2
## Tint multiplier while hovered. Above 1 brightens.
@export var hover_brightness := 1.08
@export var hover_duration := 0.12

@export_group("Hold")
## Resting scale multiplier while the button is held down.
@export var press_scale := 0.95
## Short on purpose: the squash is the button acknowledging the click, and an
## acknowledgement that takes time to arrive reads as lag.
@export var press_duration := 0.06

@export_group("Click")
## Scale the release starts from, before springing back to rest. Overshoots hover
## because the release is the payoff for the whole interaction.
@export var click_scale := 1.25
## Degrees of kick the release starts from.
@export var click_tilt := 3.0
## Tint the release starts from. The flash is what carries the click when the
## button is small enough that the scale pop is barely visible.
@export var click_flash := 1.4
@export var click_duration := 0.4
@export var flash_duration := 0.18

# Resting pose, read from the scene rather than assumed: the upgrade cards are
# authored at 1.27 scale, so every reaction is a multiplier on what the scene says
# instead of an absolute this component would have to be told about.
var _rest_scale: Vector2
var _rest_offset: Vector2
var _rest_rotation: float
var _rest_modulate: Color
var _rest_z: int

var _hovered := false
# Focused *and* worth highlighting for it, which is not the same as having focus —
# see _on_focus_changed.
var _focused := false
var _held := false
# Whether the release that is arriving was a real click, or the button being let
# go of somewhere else. Both orders of pressed/button_up end on the same pose, so
# this doesn't depend on which of the two the engine emits first.
var _clicked := false
# Which way this button leans. Fixed per instance rather than random per hover, so
# sweeping the mouse along a row reads as three objects with their own weight
# instead of one animation played three times.
var _tilt_sign := 1.0

# Shape and colour ride their own tween. A click landing mid-hover restarts one
# without cutting the other short, and an owner script that grabs modulate back
# can't strand the transform mid-flight.
var _shape_tween: Tween
var _color_tween: Tween


func _ready() -> void:
	if target == null:
		target = get_parent() as Control
	if target == null:
		push_warning("ButtonFeedback on %s needs a Control to react for" % get_parent().name)
		return

	target.offset_transform_enabled = true
	# Forced rather than left to the scene: the whole approach depends on the
	# transform staying out of layout and out of input picking.
	target.offset_transform_visual_only = true

	_rest_scale = target.offset_transform_scale
	_rest_offset = target.offset_transform_position
	_rest_rotation = target.offset_transform_rotation
	_rest_modulate = target.modulate
	_rest_z = target.z_index

	_tilt_sign = 1.0 if target.get_index() % 2 == 0 else -1.0

	target.mouse_entered.connect(_on_hover_changed.bind(true))
	target.mouse_exited.connect(_on_hover_changed.bind(false))
	# Keyboard and pad navigation gets the same highlight as the mouse, so a
	# focused button is never the only one on screen that looks dead.
	target.focus_entered.connect(_on_focus_changed.bind(true))
	target.focus_exited.connect(_on_focus_changed.bind(false))
	target.visibility_changed.connect(_on_visibility_changed)

	var button := target as BaseButton
	if button != null:
		button.button_down.connect(_on_press)
		button.pressed.connect(_on_click)
		button.button_up.connect(_on_release)
	else:
		target.gui_input.connect(_on_gui_input)


# A bare Control that reads its own clicks — CardUI does — gets the same three
# moments out of the raw event. The signal fires ahead of the control's own
# _gui_input, so the accept_event() in there doesn't hide the press from us.
func _on_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		_on_press()
	elif _held:
		# Released on the button is a click; dragged off and released is not, and
		# the cursor having left already turned _hovered off.
		if _hovered:
			_on_click()
		_on_release()


func _on_hover_changed(hovered: bool) -> void:
	if _is_inert() or _hovered == hovered:
		return
	_hovered = hovered
	# While held, the press pose owns the button — Godot keeps a held button held
	# when the cursor wanders off it, and so should the look of it.
	if not _held:
		_settle()


# Focus taken by a click belongs to the mouse, not to focus. Clicking a Control
# focuses it, and that focus outlives the click, so a button that counted it as a
# highlight would sit in the hover pose for good: the cursor leaving clears
# _hovered, and _focused holds the pose up behind it. The cursor being on the
# button is what says the mouse put the focus there — it had to move onto it to
# click it — and hover is already lighting the button up in that case. Navigation
# focus arrives with the cursor elsewhere, and still gets the highlight.
func _on_focus_changed(focused: bool) -> void:
	var highlights := focused and not _hovered
	if _focused == highlights:
		return
	_focused = highlights
	if not _held:
		_settle()


func _on_press() -> void:
	if _is_inert():
		return
	_held = true
	_clicked = false
	# Snaps in and stays down for as long as the button is held: taking the weight
	# of the cursor is what makes it feel like a physical thing rather than a
	# picture that plays an animation when poked.
	_pose(press_scale, 0.0, 0.0, press_duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_tint(1.0, press_duration)


# Springs out of the squash. Starts *at* the overshoot instead of easing up to it,
# so the pop is already at full throw on the first frame — a frame spent
# travelling to the peak is a frame where the click hasn't visibly registered.
func _on_click() -> void:
	if _is_inert():
		return
	_clicked = true
	_shape_tween = _restart(_shape_tween)
	_shape_tween.set_parallel(true)
	_shape_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_shape_tween.tween_property(target, "offset_transform_scale",
			_rest_scale * _settled_scale(), click_duration) \
			.from(_rest_scale * click_scale)
	_shape_tween.tween_property(target, "offset_transform_rotation",
			_rest_rotation + deg_to_rad(_settled_tilt()), click_duration) \
			.from(_rest_rotation + deg_to_rad(click_tilt * _tilt_sign))
	# The lift comes back with a spring rather than a wobble; two elastic curves on
	# one object turn a pop into a jelly.
	_shape_tween.tween_property(target, "offset_transform_position",
			_rest_offset + _lift_offset(_settled_lift()), click_duration) \
			.set_trans(Tween.TRANS_BACK)
	_ride_above(_shape_tween)

	_tint(_settled_brightness(), flash_duration, click_flash)


func _on_release() -> void:
	_held = false
	# A click already posed the button on its way out. This is the other release:
	# let go of somewhere else, so it just goes back to wherever it belongs.
	if not _clicked:
		_settle()


# Cards are hidden and re-shown as offers come and go. One that was mid-pop when
# its screen closed would come back still holding that pose, and one hidden while
# hovered never gets the mouse_exited that would have cleared the highlight.
func _on_visibility_changed() -> void:
	_hovered = false
	_focused = false
	_held = false
	_clicked = false
	_snap_to_rest()


# Moves to whatever pose the current state calls for. Every path that isn't the
# press or the click ends here, so hover-out, focus-out and an abandoned press all
# agree on where the button lands.
func _settle() -> void:
	_pose(_settled_scale(), _settled_lift(), _settled_tilt(), hover_duration,
			Tween.TRANS_BACK, Tween.EASE_OUT)
	_tint(_settled_brightness(), hover_duration)


func _pose(scale_mul: float, lift: float, tilt: float, duration: float,
		trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	_shape_tween = _restart(_shape_tween)
	_shape_tween.set_parallel(true)
	_shape_tween.set_trans(trans).set_ease(ease_type)
	_shape_tween.tween_property(target, "offset_transform_scale", _rest_scale * scale_mul, duration)
	_shape_tween.tween_property(target, "offset_transform_position", _rest_offset + _lift_offset(lift), duration)
	_shape_tween.tween_property(target, "offset_transform_rotation", _rest_rotation + deg_to_rad(tilt), duration)
	_ride_above(_shape_tween)


# `from_brightness` snaps the tint before the fade, for the click flash. Left off,
# the colour just travels from wherever it is.
func _tint(brightness: float, duration: float, from_brightness := -1.0) -> void:
	_color_tween = _restart(_color_tween)
	var step := _color_tween.tween_property(target, "modulate",
			_brighten(_rest_modulate, brightness), duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if from_brightness >= 0.0:
		step.from(_brighten(_rest_modulate, from_brightness))


# Lifted out of the row while it is moving, so a button grown past its neighbours
# is drawn over them rather than under one of them. Put back only once it has
# finished settling: dropping it the moment the settle starts would send it behind
# the neighbour it is still overlapping. z_index leaves child order alone, unlike
# move_to_front, so the container is undisturbed.
func _ride_above(tween: Tween) -> void:
	target.z_index = _rest_z + 1
	if _is_highlighted():
		return  # Stays up for as long as it is the one being pointed at.
	# chain() so this lands after the pose instead of alongside it.
	tween.chain().tween_callback(_ride_home)


func _ride_home() -> void:
	target.z_index = _rest_z


func _is_highlighted() -> bool:
	return _hovered or _focused


func _settled_scale() -> float:
	return hover_scale if _is_highlighted() else 1.0


func _settled_lift() -> float:
	return hover_lift if _is_highlighted() else 0.0


func _settled_tilt() -> float:
	return hover_tilt * _tilt_sign if _is_highlighted() else 0.0


func _settled_brightness() -> float:
	return hover_brightness if _is_highlighted() else 1.0


# Measured against the current height rather than the height at _ready: containers
# hand out their sizes after this component is set up.
func _lift_offset(lift: float) -> Vector2:
	return Vector2(0.0, -target.size.y * lift)


# Channel-wise so a control authored part-transparent keeps its alpha; a plain
# Color * float would fade it as it brightens.
func _brighten(color: Color, amount: float) -> Color:
	return Color(color.r * amount, color.g * amount, color.b * amount, color.a)


# A disabled button reacting to the cursor is worse than one that ignores it: it
# invites the click it is about to refuse.
func _is_inert() -> bool:
	var button := target as BaseButton
	return button != null and button.disabled


func _snap_to_rest() -> void:
	if _shape_tween != null and _shape_tween.is_valid():
		_shape_tween.kill()
	if _color_tween != null and _color_tween.is_valid():
		_color_tween.kill()
	if target == null:
		return
	target.offset_transform_scale = _rest_scale
	target.offset_transform_position = _rest_offset
	target.offset_transform_rotation = _rest_rotation
	target.modulate = _rest_modulate
	target.z_index = _rest_z


# Only one tween may own a property at a time, otherwise a click landing during a
# hover leaves two of them fighting over the same value frame to frame.
func _restart(tween: Tween) -> Tween:
	if tween != null and tween.is_valid():
		tween.kill()
	var fresh := create_tween()
	# Both screens this rides on run with the tree paused, so the tween has to be
	# explicitly exempt rather than inherit the pause and freeze mid-reaction.
	fresh.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return fresh
