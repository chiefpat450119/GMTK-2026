class_name ClockNumber
extends Sprite2D

const TWEEN_TIME : float = 0.5

@export var projectile_damage: float
@export var damage_stat: Stat

@export var projectile_scene: PackedScene

func move_to_pos(pos: Vector2):
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", pos, TWEEN_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 2 * PI, TWEEN_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func shoot_projectile():
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "rotation", -4 * PI, TWEEN_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	var instance: Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	
	var sprite := find_sprite(instance)
	sprite.texture = texture
	
	
	var _rotation: float = global_position.direction_to(Player.instance.global_position).angle()
	instance.launch(
		global_position,
		_rotation,
		Projectile.Team.ENEMY,
		damage_stat.current_val(projectile_damage)
	)
	
	queue_free()


func find_sprite(entity: Node) -> Sprite2D:
	for child in entity.get_children():
		if child is Sprite2D:
			return child
	return null
	
	 
