# The spray a hit throws off: a shock front punched out along the shove, with speed
# streaks and debris riding it.
#
# Aimed rather than radial on purpose. A ring of particles says "something happened
# here"; a cone says "something hit it, from over there, this hard" — the burst, the
# knockback and the sprite shake all point the same way, so three parts of the
# reaction agree on the story instead of each telling their own.
#
# What sells force over fizz is deceleration. Everything here leaves at a speed
# nothing else in the game moves at and is dragged down inside a fifth of a second:
# a particle drifting out at a constant speed reads as smoke, the same particle
# slamming to a halt reads as something that was *thrown*. The drag is friction
# rather than a flat pull, so it bites hardest on the first frames and never quite
# reaches zero — a streak that stops dead has no velocity left to point itself along
# and spins on the spot for the rest of its life.
#
# Standalone and parented *beside* whatever was hit, not under it, so a body that
# dies a beat later doesn't take its own hit spray down with it. Frees itself once
# every layer has burnt out.
#
# The layers are whatever children the scene has — GPUParticles2D fire, and a
# Polygon2D is punched outward as the shock front — so a new layer can be added in
# the editor without touching this script.

class_name HitBurst
extends Node2D

## Seconds the shock front takes to punch out and vanish. Shorter than anything else
## here: it's the frame of contact, and a wave still visible once the debris is in
## flight reads as an explosion going off rather than a hit landing.
const WAVE_TIME := 0.11

## Overall size of the weakest hit's spray, as a multiplier on the scene's tuning.
## Scaling the node scales how far particles are thrown as well as how big they are,
## so the whole burst grows as one instead of just getting denser.
@export var scale_min := 0.95
## ...and of the hardest hit's. Kept within about half again as much: a burst that
## doubles reads as a different effect firing, not as the same hit landing harder.
@export var scale_max := 1.35
## Fraction of each emitter's particle count a chip hit is worth. The rest of the
## count is earned by damage, so weak hits spit and heavy ones erupt.
@export var amount_min := 0.6
## What the shock front grows to, against the scale it sits at in the scene. Stretched
## far harder along the hit than across it — an evenly growing ring is a shockwave from
## an explosion, and only the lopsided one reads as a blow from a direction.
@export var wave_growth := Vector2(5.0, 1.4)

# Where the hit landed, in world space. Applied in _ready() rather than at setup time,
# because a global position means nothing until we're actually in the tree.
var _origin := Vector2.ZERO
var _dir := Vector2.RIGHT
var _strength := 0.0
var _live := 0


## Where the hit landed, which way it drove, and how hard — `strength` is 0 for the
## weakest hit and 1 for the hardest. Call before adding the burst to the tree; the
## layers fire on the frame they enter it.
func setup(origin: Vector2, direction: Vector2, strength: float) -> void:
	_origin = origin
	if direction.length() > 0.01:
		_dir = direction.normalized()
	_strength = clampf(strength, 0.0, 1.0)


func _ready() -> void:
	global_position = _origin
	# Every layer in the scene points down its own +X, so aiming the whole burst is one
	# rotation here rather than a direction each of them has to be told about.
	rotation = _dir.angle()
	scale = Vector2.ONE * lerpf(scale_min, scale_max, _strength)

	# Physics interpolation is on, so without this the burst spends its first frame
	# streaking in from wherever it was spawned to where it belongs.
	reset_physics_interpolation()

	for child in get_children():
		if child is GPUParticles2D:
			_fire(child)
		elif child is Polygon2D:
			_punch(child)

	if _live == 0:
		queue_free()  # Nothing to wait on, and an empty burst would sit here forever.


func _fire(emitter: GPUParticles2D) -> void:
	_live += 1
	# Freeing is driven off `finished`, which a looping emitter never reaches — so the
	# one-shot this counts on is enforced here rather than trusted to the scene.
	emitter.one_shot = true
	emitter.amount_ratio = lerpf(amount_min, 1.0, _strength)
	emitter.finished.connect(_on_layer_finished)
	emitter.emitting = true


# The shock front: the flat, bright shape that owns the frame the hit lands on. It's
# already at full brightness on that frame and only ever shrinks in opacity from there
# — a wave that fades *in* spends its first frames looking like nothing happened.
func _punch(wave: Polygon2D) -> void:
	_live += 1
	var from: Vector2 = wave.scale

	var tween := create_tween().set_parallel()
	tween.tween_property(wave, "scale", from * wave_growth, WAVE_TIME) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Holds solid while it's opening and then goes at the end, so the front is read as
	# a shape being thrown rather than a glow dimming in place.
	tween.tween_property(wave, "modulate:a", 0.0, WAVE_TIME) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_on_layer_finished)


# Layers have their own lifetimes, so the last one to die decides when the burst is
# over — freeing on the first would cut the slower layer's tail off mid-air.
func _on_layer_finished() -> void:
	_live -= 1
	if _live <= 0:
		queue_free()
