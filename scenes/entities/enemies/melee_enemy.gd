class_name MeleeEnemy
extends Enemy

@export var attack_cd: float
@export var hurtbox: Area2D
@export var accel_time: float  # Seconds to reach full speed
@export var decel_time: float  # Seconds to coast to a stop

@onready var attack_cooldown := Cooldown.new(attack_cd)

func _ready() -> void:
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(delta: float) -> void:
	accelerate_towards_player(1, accel_time, decel_time, delta)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	if not attack_cooldown.is_done():
		return
	
	hit(1)
