class_name HomingProjectile
extends Projectile

@export var homing_speed: float = 0.5

func _physics_process(delta: float) -> void:
	if is_instance_valid(Player.instance):
		var target_angle := global_position.direction_to(
			Player.instance.global_position
		).angle()

		global_rotation = rotate_toward(
			global_rotation,
			target_angle,
			homing_speed * delta
		)

		_velocity = Vector2.RIGHT.rotated(global_rotation) * speed

	super(delta)
