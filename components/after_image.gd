class_name AfterImageSpawner
extends Node


func spawn_image(target: Node2D, tex: Texture2D, scale, flip) -> Sprite2D:
	var sprite = AfterImageFx.new(tex)
	
	sprite.flip_h = flip
	sprite.global_transform = target.global_transform
	sprite.scale = scale
	
	target.get_tree().current_scene.add_child(sprite)
	return sprite
