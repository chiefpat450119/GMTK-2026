class_name Sprites
extends RefCounted
## Helpers for reaching an entity's visuals without knowing which sprite class it
## drew itself with.


## Returns the first sprite hanging off an entity, or null if it has none.
## Sprites are Sprite2D on some enemies and AnimatedSprite2D on others, and the
## reaction components only ever need them as a Node2D.
static func find_in(entity: Node) -> Node2D:
	for child in entity.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child
	return null


## Returns what a sprite is showing *right now* as a plain texture — the frame an
## AnimatedSprite2D is currently on, or a Sprite2D's own texture. Lets an effect take
## a still of a body at the moment it died.
static func current_texture(sprite: Node2D) -> Texture2D:
	if sprite is Sprite2D:
		return sprite.texture
	if sprite is AnimatedSprite2D:
		var frames: SpriteFrames = sprite.sprite_frames
		if frames == null or not frames.has_animation(sprite.animation):
			return null
		if sprite.frame >= frames.get_frame_count(sprite.animation):
			return null
		return frames.get_frame_texture(sprite.animation, sprite.frame)
	return null
