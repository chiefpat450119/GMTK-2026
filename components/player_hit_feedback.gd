class_name PlayerHitFeedback
extends Node

const FLASH_COLOR := Color(1, 0.45, 0.45)  # Sprite tint on the frame the hit lands
const RECOVER_TIME := 0.15  # Seconds for the spring back out of the squash
const HIT_SQUASH := 0.72  # sprite scale.y multiplier on the frame the hit lands
const HIT_STRETCH := 1.14  # sprite scale.x multiplier on that frame, so the volume roughly holds
const SHAKE_DIST := 6.0  # Pixels of the first sprite shake swing
const SHAKE_SWINGS := 4  # Swings the sprite shake decays over before settling

const TRAUMA_MIN := 0.5  # What the lightest hit is worth
const TRAUMA_MAX := 0.8  # What a hit of FULL_TRAUMA_DAMAGE or more is worth
const FULL_TRAUMA_DAMAGE := 10.0  # Seconds off the clock in one hit that earns TRAUMA_MAX

@export var time: TimeComponent  # Defaults to the time component on our parent
@export var sprite: Node2D  # Defaults to the first sprite on our parent

var base_scale: Vector2
var base_pos: Vector2
var base_modulate: Color

var scale_tween: Tween
var shake_tween: Tween
var flash_tween: Tween


func _ready() -> void:
	if time == null:
		time = TimeComponent.find_in(get_parent())
	if sprite == null:
		sprite = _find_sprite()

	if time == null or sprite == null:
		push_warning("PlayerHitFeedback on %s needs a TimeComponent and a sprite" % get_parent().name)
		return

	# Resting transform to squash away from and spring back to. Read before any
	# owner animation has had a frame to run, so it's the value from the scene.
	base_scale = sprite.scale
	base_pos = sprite.position
	base_modulate = sprite.modulate

	time.damaged.connect(_on_damaged)


func _on_damaged(amount: float) -> void:
	if time.time_left <= 0.0:
		return  # The run ends on this same call, so there's nothing left to react with.
	_play(amount)


func _play(damage: float) -> void:
	# Every part starts *at* its extreme rather than easing into it: easing in costs
	# the hit its immediacy, and a frame spent travelling to the squash is a frame
	# where nothing has visibly happened yet. from() sets the value outright on the
	# first step, so it lands even if an owner tween writes the same property first.
	var squashed := Vector2(base_scale.x * HIT_STRETCH, base_scale.y * HIT_SQUASH)
	scale_tween = _restart(scale_tween)
	scale_tween.tween_property(sprite, "scale", base_scale, RECOVER_TIME) \
		.from(squashed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Snap out along one random direction, then rattle back through it in swings
	# that each fall short of the last, so repeated hits don't all shake the same way.
	var dir := Vector2.from_angle(randf() * TAU)
	var step := RECOVER_TIME / float(SHAKE_SWINGS + 1)
	shake_tween = _restart(shake_tween)
	for i in range(1, SHAKE_SWINGS + 1):
		var falloff := 1.0 - float(i) / float(SHAKE_SWINGS + 1)  # never decays to a dead swing
		var side := 1.0 if i % 2 == 0 else -1.0
		var swing := shake_tween.tween_property(sprite, "position", \
			base_pos + dir * SHAKE_DIST * falloff * side, step).set_trans(Tween.TRANS_SINE)
		if i == 1:
			swing.from(base_pos + dir * SHAKE_DIST)  # Already at full throw on frame one
	shake_tween.tween_property(sprite, "position", base_pos, step) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	flash_tween = _restart(flash_tween)
	flash_tween.tween_property(sprite, "modulate", base_modulate, RECOVER_TIME) \
		.from(FLASH_COLOR)

	var t := clampf(damage / FULL_TRAUMA_DAMAGE, 0.0, 1.0)
	CameraShake.shake(lerpf(TRAUMA_MIN, TRAUMA_MAX, t))


# The player's sprite is an AnimatedSprite2D and the placeholder beside it a Sprite2D;
# both only need to be a Node2D from here.
func _find_sprite() -> Node2D:
	for child in get_parent().get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child
	return null


# Only one tween may own a property at a time, otherwise a hit landing during the
# recovery leaves two of them fighting over it frame to frame.
func _restart(tween: Tween) -> Tween:
	if tween != null and tween.is_valid():
		tween.kill()
	return create_tween()
