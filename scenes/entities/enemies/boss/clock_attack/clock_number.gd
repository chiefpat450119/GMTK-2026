class_name ClockNumber
extends Sprite2D

const TWEEN_TIME : float = 0.5

func move_to_pos(pos: Vector2):
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", pos, TWEEN_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 2 * PI, TWEEN_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
