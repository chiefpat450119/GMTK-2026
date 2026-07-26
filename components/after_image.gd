class_name AfterImageSpawner
extends Node


func spawn_image(target: Node2D, tex: Texture2D) -> Sprite2D:
	var sprite = AfterImageFx.new(tex)
	target.get_tree().current_scene.add_child(sprite)
	return sprite
