# The dust an enemy leaves behind: a standalone still of its sprite, taken at the
# moment it died and then eroded away by the disintegrate shader.
#
# Deliberately *not* run on the enemy itself. HealthComponent frees the body on the
# same call that death is announced, and keeping a corpse alive to animate would
# leave something that still collides, still deals contact damage and still reads as
# an enemy for every frame the effect plays. Copying the sprite out costs one texture
# reference and buys a death that can outlive the thing that died.
#
# Particles hang off here later: add emitters as children, aim them along the
# shader's wind_dir, and give `linger` enough time for their tails to finish after
# the sprite itself has gone.

class_name DisintegrateEffect
extends Sprite2D

## Seconds to go from intact to fully eroded. Heavier enemies want longer — a tank
## puffing out as fast as a scout costs it all its weight.
@export var duration := 0.45
## Extra seconds to stay alive after the sprite is gone, before freeing itself.
## Nothing needs it yet; dust that outlives the body will.
@export var linger := 0.0
## The curve the erosion front travels on. Eased out, so the body comes apart the
## instant it dies and the last grains hang around — the shader's own threshold is
## already slowest at both ends, and easing in on top of that costs the death its
## impact while the front crawls through pixels that were never going to go yet.
@export var trans: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_OUT
## How far the noise pattern is shifted per instance, so two enemies dying together
## don't crumble in lockstep.
@export var offset_spread := 16.0

# Where the source sprite was standing. Applied in _ready() rather than at setup
# time, because a global transform means nothing until we're actually in the tree.
var _source_transform := Transform2D.IDENTITY


## Copies everything the effect needs off a live sprite. Must be called *before* the
## effect is added to the tree — by the time it isn't, the source is usually freed.
func setup(source: Node2D) -> void:
	texture = Sprites.current_texture(source)
	_source_transform = source.global_transform
	modulate = source.modulate
	self_modulate = source.self_modulate
	z_index = source.z_index

	# Both sprite classes carry these, and all four shift where the texture sits
	# relative to the node's origin — skip them and the corpse jumps on spawn.
	centered = source.centered
	offset = source.offset
	flip_h = source.flip_h
	flip_v = source.flip_v

	# Sheet layout only exists on Sprite2D. An AnimatedSprite2D's `frame` indexes its
	# animation, not a grid, so copying it across would land on the wrong cell.
	if source is Sprite2D:
		region_enabled = source.region_enabled
		region_rect = source.region_rect
		hframes = source.hframes
		vframes = source.vframes
		frame = source.frame


func _ready() -> void:
	global_transform = _source_transform

	var mat := _own_material()
	if mat == null:
		queue_free()
		return

	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("noise_offset", Vector2(randf(), randf()) * offset_spread)

	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 1.0, duration) \
		.from(0.0).set_trans(trans).set_ease(ease_type)
	if linger > 0.0:
		tween.tween_interval(linger)
	tween.tween_callback(queue_free)


# The material is a scene sub-resource, so every corpse would otherwise share one
# copy — and two enemies dying a beat apart would drive the same `progress`, so the
# second death would snap the first one's remains back to intact.
func _own_material() -> ShaderMaterial:
	var shared := material as ShaderMaterial
	if shared == null:
		push_error("DisintegrateEffect needs a ShaderMaterial running disintegrate.gdshader")
		return null
	var owned := shared.duplicate() as ShaderMaterial
	material = owned
	return owned
