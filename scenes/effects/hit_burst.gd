class_name HitBurst
extends Node2D

## Seconds the shock front takes to punch out and vanish — about four frames. Shorter
## than anything else here: it's the moment of contact, and a wave still visible once
## the debris is in flight reads as an explosion going off rather than a hit landing.
const WAVE_TIME := 0.07

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
## What the shock front grows to, against the scale it sits at in the scene. Kept small
## enough to stay a flash at the point of contact — the streaks are what carry the hit,
## and a front big enough to compete with them takes the shape away from them.
@export var wave_growth := Vector2(2.8, 1.3)

# Where the hit landed, in world space. Applied in _ready() rather than at setup time,
# because a global position means nothing until we're actually in the tree.
var _origin := Vector2.ZERO
var _dir := Vector2.RIGHT
var _strength := 0.0
var _live := 0


func setup(origin: Vector2, direction: Vector2, strength: float) -> void:
	_origin = origin
	if direction.length() > 0.01:
		_dir = direction.normalized()
	_strength = clampf(strength, 0.0, 1.0)


func _ready() -> void:
	global_position = _origin
	# Every layer is authored pointing down +X, so aiming the burst is this one rotation.
	# Particles bake it in at spawn, which orients the streak sprites along the hit as
	# well as throwing them that way — the streak texture is drawn lengthwise on X to
	# match, so rotating a layer in the scene would turn its particles side-on.
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
		queue_free()


func _fire(emitter: GPUParticles2D) -> void:
	_live += 1
	emitter.one_shot = true
	emitter.amount_ratio = lerpf(amount_min, 1.0, _strength)
	emitter.finished.connect(_on_layer_finished)
	emitter.emitting = true


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
