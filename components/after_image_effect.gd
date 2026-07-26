class_name AfterImageFx
extends Sprite2D

const BLUE := Color(0.18, 0.863, 1.0, 1.0)
const BLUE_TRANS := Color(0.18, 0.863, 1.0, 0.0)

func _init(tex: Texture2D):
	texture = tex
	

func _ready() -> void:
	modulate = BLUE
	
	var tween := create_tween()
	tween.tween_property(self, "modulate", BLUE_TRANS, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
	
	await tween.finished
	queue_free()
