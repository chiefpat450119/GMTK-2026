# Flash, squash, shake, spray and knockback reaction for anything that owns a
# HealthComponent.
#
# Drop as a child of an enemy; it finds the health component and the sprite on
# that enemy on its own. Nothing has to call it — losing hp is the trigger, so
# contact damage, bullets and anything added later all get the reaction for free.
#
# Deliberately shaped like MeleeEnemy's impact reaction: a hard squash springing
# back out reads as a real hit far better than a colour flash on its own. Scale,
# position and colour each ride their own tween, so a re-hit mid-reaction
# restarts cleanly and an owner script grabbing one of those properties back
# can't strand the others mid-flight.
#
# The shove and the particle spray share one direction and one strength, so which way
# the body goes, which way the spray goes and how much of either there is all describe
# the same hit rather than three loosely related things happening at once.

class_name HitFeedback
extends Node

const FLASH_COLOR := Color(1, 0.45, 0.45)  # Sprite tint on the frame the hit lands
const RECOVER_TIME := 0.15  # Seconds for the spring back out of the squash
const HIT_SQUASH := 0.72  # sprite scale.y multiplier on the frame the hit lands
const HIT_STRETCH := 1.14  # sprite scale.x multiplier on that frame, so the volume roughly holds
const SHAKE_DIST := 6.0  # Pixels of the first shake swing
const SHAKE_SWINGS := 4  # Swings the shake decays over before settling
const KNOCKBACK_TIME := 0.05  # Seconds for the shove to decay to a stop
const KNOCKBACK_MAX_SCALE := 1.8  # knockback_speed multiplier a full-strength hit earns
# Share of a body's own full hp that one hit has to take to earn the biggest reaction
# there is. Measured against the body rather than against a fixed damage number,
# because a fixed one is wrong twice over: 25 damage is half a scout and a scratch on
# a tank, and a late-game gun clears any threshold picked for an early-game one, so
# every hit ends up maxed and the reaction stops saying anything at all.
const BIG_HIT_FRACTION := 0.22
# Pixels back up the incoming hit to start the spray, so it comes off the struck side
# of the body rather than out of its middle.
const BURST_BACKSET := 24.0

@export var health: HealthComponent  # Defaults to the health component on our parent
@export var sprite: Node2D  # Defaults to the first sprite on our parent
## Particles thrown off along the shove — hit_burst.tscn, or anything with a HitBurst
## root. Leaving it unset opts a body out of the spray.
@export var burst_scene: PackedScene
# Opening speed of the shove, in px/s. Enemies walk at 400-550 and keep driving at
# the player through the shove, so anything near their own speed cancels out and
# reads as a stumble rather than a hit. 0 opts a body out of being moved at all.
@export var knockback_speed := 900.0

# Multiplier the last hit earned, 1.0 up to KNOCKBACK_MAX_SCALE. A chip hit shoving as
# hard as a crit reads as the enemy having no weight, so damage picks the speed and the
# exported value stays what the weakest hit is worth.
var knockback_scale := 1.0

var base_scale: Vector2
var base_pos: Vector2
var base_modulate: Color

var scale_tween: Tween
var shake_tween: Tween
var flash_tween: Tween

# The knocked-back body, or null when our parent isn't one we can move.
var body: CharacterBody2D
var knockback := Cooldown.new(KNOCKBACK_TIME)
var knockback_dir: Vector2

# hp only ever starts at full, so the first change can only have been damage.
var last_hp := INF


func _ready() -> void:
	# Only runs while a shove is live; _play arms it.
	set_physics_process(false)

	if health == null:
		health = HealthComponent.find_in(get_parent())
	if sprite == null:
		sprite = Sprites.find_in(get_parent())

	body = get_parent() as CharacterBody2D

	if health == null or sprite == null:
		push_warning("HitFeedback on %s needs a HealthComponent and a sprite" % get_parent().name)
		return

	# Resting transform to squash away from and spring back to. Read before any
	# owner animation has had a frame to run, so it's the value from the scene.
	base_scale = sprite.scale
	base_pos = sprite.position
	base_modulate = sprite.modulate

	health.hp_changed_signal.connect(_on_hp_changed)


func _on_hp_changed() -> void:
	var previous := last_hp
	last_hp = health.hp

	if health.hp >= previous:
		return  # Healed, or set to what it already was — nothing was taken.
	if health.hp <= 0:
		return  # Dying; the owner is freed on this same call, so there's nothing to react with.

	# The very first change has no real previous to subtract from — hp only ever starts
	# at full, so that's what the hit came off.
	if is_inf(previous):
		previous = health.effective_max_hp

	_play(previous - health.hp)


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

	# How hard the hit was, 0 for a chip and 1 for one taking BIG_HIT_FRACTION of the
	# body's hp. The shove and the spray both ride it, so they always agree.
	var bar := maxf(health.effective_max_hp * BIG_HIT_FRACTION, 1.0)
	var strength := clampf(damage / bar, 0.0, 1.0)
	var impact_dir := _impact_dir(dir)
	_burst(impact_dir, strength)
	_knock_back(impact_dir, strength)


# Which way the hit drove the body: away from the player. They're the only thing that
# deals damage, so taking the direction from them keeps this a self-contained reaction
# that no damage source has to know about or call. Falls back to whatever the shake
# picked when there's no player, or when the body is sitting dead-centre on them and
# there's no direction left to take.
func _impact_dir(fallback: Vector2) -> Vector2:
	var player := Player.instance
	if player == null:
		return fallback

	var away := sprite.global_position - player.global_position
	if away.length() <= 0.01:
		return fallback
	return away.normalized()


# A short shove of the body itself. The sprite shake sells the impact but leaves the
# enemy standing exactly where it stood; moving the body is what makes a hit feel like
# it landed on something with weight.
#
# How hard is straight off what the hit took out of the body, so a build that trades
# fire rate for a heavy shot gets to see the weight of it, and the same shot moves a
# scout further than it moves a tank.
func _knock_back(dir: Vector2, strength: float) -> void:
	if body == null or knockback_speed <= 0.0:
		return

	knockback_scale = lerpf(1.0, KNOCKBACK_MAX_SCALE, strength)
	knockback_dir = dir
	knockback.start()
	set_physics_process(true)


# The spray, fired along the same direction the shove goes. Parented beside the body
# rather than under it — the same place DisintegrateOnDeath puts its corpse — so it
# y-sorts into the world at the right depth, and a hit landed a moment before death
# doesn't have its particles freed along with the body they came off.
#
# Bodies that opt out of the shove still get it: knockback_speed is about whether
# something can be moved, and even an immovable enemy should spit when it's struck.
func _burst(dir: Vector2, strength: float) -> void:
	if burst_scene == null:
		return

	var host := get_parent().get_parent()
	if host == null:
		return

	var burst := burst_scene.instantiate() as HitBurst
	if burst == null:
		push_error("HitFeedback on %s: burst_scene must have a HitBurst root" % get_parent().name)
		return

	burst.setup(sprite.global_position - dir * BURST_BACKSET, dir, strength)
	host.add_child(burst)


# Moved with move_and_collide rather than by writing velocity: the owner script drives
# velocity itself every frame and would overwrite the shove before it moved anything.
# This displaces on top of whatever move_and_slide the owner already ran, and still
# stops at walls.
func _physics_process(delta: float) -> void:
	knockback.tick(delta)
	if knockback.is_done():
		knockback.stop()
		set_physics_process(false)
		return

	var t := knockback.time_left / KNOCKBACK_TIME  # 1 -> 0 over the shove
	body.move_and_collide(knockback_dir * knockback_speed * knockback_scale * t * delta)


# Only one tween may own a property at a time, otherwise a hit landing during the
# recovery leaves two of them fighting over it frame to frame.
func _restart(tween: Tween) -> Tween:
	if tween != null and tween.is_valid():
		tween.kill()
	return create_tween()
