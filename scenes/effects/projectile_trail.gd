class_name ProjectileTrail
extends Line2D

static var _additive_material: CanvasItemMaterial

var _target: Node2D
var _lifetime := 0.1
var _min_distance := 4.0

# Where the target stood at the end of the last two physics steps. Projectiles move
# on the physics clock while the world draws on the frame clock, so this is what the
# streak's head is interpolated between — see _drawn_position().
var _prev_pos := Vector2.ZERO
var _curr_pos := Vector2.ZERO

# Seconds since this trail was born, and the reading of that clock at which each
# point was laid down. Stamps and points are appended and dropped together, so
# index i in one is index i in the other.
var _now := 0.0
var _stamps := PackedFloat32Array()


## Puts a trail on a projectile. Parented to the scene rather than to the target,
## so the target being freed cuts the streak loose instead of taking it along.
static func spawn(target: Node2D, settings: TrailSettings) -> ProjectileTrail:
	var trail := ProjectileTrail.new()
	target.get_tree().current_scene.add_child(trail)
	trail.follow(target, settings)
	return trail


## Aims the trail at a node and applies a weapon's look. Call once, after the trail
## is in the tree.
func follow(target: Node2D, settings: TrailSettings) -> void:
	_target = target
	_lifetime = settings.lifetime
	_min_distance = settings.min_distance
	_prev_pos = target.global_position
	_curr_pos = _prev_pos

	# Points are held in world space, so the trail must not pick up a transform from
	# whatever it happens to be parented to — otherwise the whole streak rides along
	# with its parent instead of staying where it was drawn.
	top_level = true

	width = settings.width
	width_curve = settings.width_curve if settings.width_curve else _taper()
	gradient = settings.gradient if settings.gradient else _fade(settings.color)
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

	if settings.additive:
		material = _shared_additive()


# Reading the target on its own clock. This node is added to the scene after the
# projectile, so by the time this runs the shot has already taken its step.
func _physics_process(_delta: float) -> void:
	if is_instance_valid(_target):
		_prev_pos = _curr_pos
		_curr_pos = _target.global_position


func _process(delta: float) -> void:
	_now += delta
	_expire()

	if is_instance_valid(_target):
		_sample()
	elif get_point_count() == 0:
		# The shot is gone and the tail has finished draining into where it landed.
		queue_free()


# Drops points off the tail once they outlive the trail. This is what fixes the
# streak's length: however far the shot travels in `lifetime` seconds.
func _expire() -> void:
	while not _stamps.is_empty() and _now - _stamps[0] > _lifetime:
		_stamps.remove_at(0)
		remove_point(0)


func _sample() -> void:
	var point := _drawn_position()

	if get_point_count() < 2:
		_push(point)  # The anchor the streak grows out of
		_push(point)  # ...and the head, which rides the bullet until it earns a commit
		return

	# The head is moved onto the bullet every frame, so the streak stays welded to the
	# shot in between the points it actually commits.
	var head := get_point_count() - 1
	set_point_position(head, point)
	_stamps[head] = _now

	# Committing only every few pixels is what stops a stalled or slow shot from
	# stacking hundreds of points on the same spot.
	if get_point_position(head - 1).distance_to(point) >= _min_distance:
		_push(point)


# Where the projectile is actually being *drawn* this frame, which is not where it
# is: physics interpolation renders it partway between its last two steps. Sampling
# the raw position instead would leave the head of the streak trailing the sprite by
# up to a full step — at railgun speeds, a visible gap between a shot and its own
# trail. Node2D has no interpolated-transform getter in 4.7 (that one is 3D only),
# so the blend is done here on the same fraction the renderer uses.
func _drawn_position() -> Vector2:
	return _prev_pos.lerp(_curr_pos, Engine.get_physics_interpolation_fraction())


func _push(point: Vector2) -> void:
	add_point(point)
	_stamps.append(_now)


# Tapers from a point at the tail to full width at the head. That taper is most of
# what reads as speed — an even-width streak reads as a rod being carried along.
func _taper() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 1.0))
	return curve


# Fades the tail out to nothing. The head keeps the colour exactly as configured,
# over-bright channels included, since those are what carry the shot into the bloom.
func _fade(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color, 0.0))
	ramp.set_color(1, color)
	return ramp


static func _shared_additive() -> CanvasItemMaterial:
	if _additive_material == null:
		_additive_material = CanvasItemMaterial.new()
		_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive_material
