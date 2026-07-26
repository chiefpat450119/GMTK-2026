class_name MuzzleFlash
extends Node2D

## The gout of light and grit that leaves a barrel on firing. Everything is authored
## pointing down +X, so a caller only has to sit this at the muzzle and match the gun's
## rotation — [method fire] handles the rest.
##
## Built to be parented to a barrel once and re-fired, rather than spawned per shot, so a
## machinegun costs nothing but a tween restart per round. Spawn-and-forget still works —
## see [member autostart] and [member free_when_finished].

## Overall size of the weakest shot's flash, as a multiplier on what the scene authored.
## Scaling the node scales how far the spray is thrown as well as how big it is, so the
## flash grows as one piece instead of just getting denser.
@export var scale_min := 0.85
## ...and of the hardest shot's. Deliberately close to [member scale_min]: a flash that
## doubles reads as a different weapon firing, not as the same one hitting harder.
@export var scale_max := 1.3
## Fraction of a full shot's spray that the weakest one throws. The rest is earned by
## strength, so a tap spits and a charged shot erupts.
@export_range(0.0, 1.0) var amount_min := 0.5
## Seconds the emitters are held open per shot, at full strength — two or three frames.
## Long enough to read as a burst, short enough not to read as a jet.
##
## This, rather than particle count, is what [member amount_min] scales: resizing a
## CPUParticles2D deactivates every particle still in the air, so a weapon varying its
## strength shot to shot would wipe the previous shot's embers each time it fired.
@export var emit_window := 0.04
## Per-shot size wobble, as a fraction either side of the strength-derived scale. Without
## it repeated shots stamp out an identical flash and the gun reads as an animation loop.
@export_range(0.0, 1.0) var size_jitter := 0.12
## Per-shot roll on the polygons, in degrees either side of straight. Same reason as
## [member size_jitter]; kept small so the long forward spike stays on the barrel's line.
@export_range(0.0, 90.0) var flash_roll := 11.0
## Seconds the polygons take to punch out and vanish — two or three frames. The flash is
## the muzzle blast itself, and one still lit while the embers are in flight reads as
## something burning on the barrel rather than a shot going off.
@export var flash_time := 0.055
## What each polygon grows to over [member flash_time], against its authored scale.
@export var flash_growth := 1.9
## Fire once as soon as this enters the tree. For spawn-per-shot use.
@export var autostart := false
## Free this node once a flash has fully died out, embers included.
@export var free_when_finished := false

# Slack on the computed burst length before self-freeing, so a layer that finishes a hair
# late isn't cut off mid-air.
const TAIL_MARGIN := 0.15

var _emitters: Array[CPUParticles2D] = []
var _polygons: Array[Polygon2D] = []
var _base_scale := Vector2.ONE
var _base_poly_scales: Array[Vector2] = []
var _base_poly_alphas: Array[float] = []
var _flash_tween: Tween
var _emit_left := 0.0


func _ready() -> void:
	_base_scale = scale

	for child in get_children():
		if child is CPUParticles2D:
			var emitter := child as CPUParticles2D
			_emitters.append(emitter)
			emitter.one_shot = false
			emitter.emitting = false
		elif child is Polygon2D:
			var poly := child as Polygon2D
			_polygons.append(poly)
			_base_poly_scales.append(poly.scale)
			_base_poly_alphas.append(poly.modulate.a)
			poly.modulate.a = 0.0

	set_process(false)
	reset_physics_interpolation()

	if autostart:
		fire()


func fire(strength := 1.0) -> void:
	var t := clampf(strength, 0.0, 1.0)
	scale = _base_scale * (lerpf(scale_min, scale_max, t) * randf_range(1.0 - size_jitter, 1.0 + size_jitter))

	_punch_polygons()
	_open_emitters(t)

	if free_when_finished:
		get_tree().create_timer(_burst_duration(), false).timeout.connect(queue_free)


func stop() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	for poly in _polygons:
		poly.modulate.a = 0.0

	_emit_left = 0.0
	set_process(false)
	for emitter in _emitters:
		emitter.emitting = false
		emitter.restart()
		emitter.emitting = false


func _process(delta: float) -> void:
	_emit_left -= delta
	if _emit_left > 0.0:
		return

	_emit_left = 0.0
	set_process(false)
	# Only new particles stop; whatever is already in the air finishes its own lifetime,
	# which is the whole point of pulsing rather than restarting.
	for emitter in _emitters:
		emitter.emitting = false


func _punch_polygons() -> void:
	if _polygons.is_empty():
		return

	# One tween drives every polygon, so a re-fire only has to kill this to take the
	# previous shot's flash off the barrel — leaving it running would fight the new one
	# for the same properties and land the alpha somewhere between the two.
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween().set_parallel()

	var roll := deg_to_rad(randf_range(-flash_roll, flash_roll))
	for i in _polygons.size():
		var poly := _polygons[i]
		poly.rotation = roll
		# Snapped to full rather than faded in: a muzzle blast is already at its brightest
		# on the frame it appears, and easing up to it costs the shot its bite.
		poly.modulate.a = _base_poly_alphas[i]
		poly.scale = _base_poly_scales[i]

		_flash_tween.tween_property(poly, "scale", _base_poly_scales[i] * flash_growth, flash_time) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		# Holds bright while it opens and then drops off a cliff, so the flash reads as
		# light being thrown clear of the barrel rather than a bulb dimming in place.
		_flash_tween.tween_property(poly, "modulate:a", 0.0, flash_time) \
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)


func _open_emitters(strength: float) -> void:
	# maxf, so a shot landing on top of one still emitting extends that window rather than
	# cutting it short — held fire should read as a continuous spray, not a stutter.
	_emit_left = maxf(_emit_left, emit_window * lerpf(amount_min, 1.0, strength))
	if _emit_left <= 0.0:
		return

	set_process(true)
	for emitter in _emitters:
		emitter.emitting = true


# Timed rather than waiting on the emitters, because CPUParticles2D reports nothing when a
# continuously-emitting layer's last particle dies — and freeing on the shortest layer
# would cut the slower ones off mid-air anyway.
func _burst_duration() -> float:
	var longest := flash_time
	for emitter in _emitters:
		var tail := emitter.lifetime * (1.0 + emitter.lifetime_randomness)
		longest = maxf(longest, (emit_window + tail) / maxf(emitter.speed_scale, 0.01))
	return longest + TAIL_MARGIN
